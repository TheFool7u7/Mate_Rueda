import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:wordwonderslink/features/game/domain/letter_model.dart';
import 'package:wordwonderslink/features/game/domain/round_model.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/game/data/realtime_db_service.dart';
import 'package:wordwonderslink/features/room/data/firestore_service.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Provider del juego en tiempo real.
/// Gestiona: fases, letras (bloqueo atómico), turnos, timer, respuestas.
/// Escucha streams de RTDB para mantener la UI sincronizada.
class GameProvider extends ChangeNotifier {
  final RealtimeDbService _rtdbService = RealtimeDbService();
  final FirestoreService _firestoreService = FirestoreService();

  // ── Estado del juego ──
  GamePhase _currentPhase = GamePhase.selecting;
  String _currentLetter = '';
  String _currentCategory = '';
  String _currentRoundId = '';
  String _activePlayerUid = '';
  int _timerEnd = 0;
  Map<String, LetterModel> _letters = {};
  Map<String, dynamic> _playersData = {};
  String _currentAnswer = '';
  String _loserUid = '';
  Map<String, int> _finalScores = {};
  String? _roomHostUid;
  String? _punishmentMediaUrl;
  String? _punishmentType;
  bool _gameFinished =
      false; // guard para evitar doble ejecución de _finishGame()

  // ── Estado de UI ──
  bool _isLoading = false;
  String? _errorMessage;
  String? _roomCode;
  String? _localUid;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  String? _disconnectNotification;

  // ── Subscriptions ──
  StreamSubscription? _stateSubscription;
  StreamSubscription? _lettersSubscription;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _forceLogoutSubscription;
  StreamSubscription? _hostPresenceSubscription;
  Timer? _hostMigrationTimer;

  // ── Getters ──
  GamePhase get currentPhase => _currentPhase;
  String get currentLetter => _currentLetter;
  String get currentCategory => _currentCategory;
  String get currentRoundId => _currentRoundId;
  String get activePlayerUid => _activePlayerUid;
  Map<String, LetterModel> get letters => _letters;
  Map<String, dynamic> get playersData => _playersData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get remainingSeconds => _remainingSeconds;
  String get currentAnswer => _currentAnswer;
  String? get roomCode => _roomCode;
  String get loserUid => _loserUid;
  Map<String, int> get finalScores => _finalScores;
  String? get roomHostUid => _roomHostUid;
  String? get punishmentMediaUrl => _punishmentMediaUrl;
  String? get punishmentType => _punishmentType;
  bool get gameFinished => _gameFinished;
  String? get disconnectNotification => _disconnectNotification;

  /// True cuando todas las letras del tablero están marcadas como usadas.
  bool get allLettersUsed => _allLettersUsed();

  /// Letras disponibles (sin usar) ordenadas alfabéticamente
  List<LetterModel> get availableLetters =>
      _letters.values.where((l) => l.isFree).toList()
        ..sort((a, b) => a.char.compareTo(b.char));

  /// Verifica si es el turno de un jugador específico
  bool isMyTurn(String uid) => _activePlayerUid == uid;

  /// Verifica si la fase actual permite seleccionar letras
  bool get canSelectLetter => _currentPhase == GamePhase.selecting;

  // ══════════════════════════════════════
  // INICIALIZACIÓN
  // ══════════════════════════════════════

  /// Conecta al juego y empieza a escuchar cambios en RTDB
  void connectToGame(String roomCode, String uid, {String? hostUid}) {
    _roomCode = roomCode;
    _localUid = uid;
    _roomHostUid = hostUid;

    // Configurar presencia del jugador
    _rtdbService.setupPresence(roomCode, uid);
    _rtdbService.setPlayerConnection(roomCode, uid, true);

    // Escuchar estado del juego (fase, turno, timer)
    _stateSubscription?.cancel();
    _stateSubscription = _rtdbService
        .watchGameState(roomCode)
        .listen(
          _onGameStateChanged,
          onError: (e) => debugPrint('Error en watchGameState: $e'),
        );

    // Escuchar cambios en las letras
    _lettersSubscription?.cancel();
    _lettersSubscription = _rtdbService.watchLetters(roomCode).listen((
      lettersMap,
    ) {
      // Solo actualizar el mapa de letras y notificar.
      // El fin de juego se detecta en evaluation_screen.onAllVotesSubmitted
      // a través de gameProvider.allLettersUsed.
      _letters = lettersMap;
      _unlockOrphanLetters();
      notifyListeners();
    }, onError: (e) => debugPrint('Error en watchLetters: $e'));

    // Escuchar datos de jugadores (puntajes, conexión)
    _playersSubscription?.cancel();
    _playersSubscription = _rtdbService.watchPlayers(roomCode).listen((data) {
      // Detectar desconexiones para notificar a los demás
      _detectDisconnections(data);
      _playersData = data;
      notifyListeners();
    }, onError: (e) => debugPrint('Error en watchPlayers: $e'));

    // Escuchar cambios de forzar logout
    _startForceLogoutListener(uid);

    // Iniciar watcher de presencia del host (para migración automática)
    _startHostWatcher();
  }

  /// Compara el estado de conexión anterior con el nuevo para detectar
  /// jugadores que se desconectaron y generar una notificación.
  void _detectDisconnections(Map<String, dynamic> newData) {
    if (_playersData.isEmpty) return; // Primera carga, no comparar

    newData.forEach((uid, value) {
      if (uid == _localUid) return; // No notificar mi propia desconexión

      final newPlayerMap = value as Map<dynamic, dynamic>?;
      final newConnected = (newPlayerMap?['isConnected'] as bool?) ?? false;

      final oldPlayerMap = _playersData[uid] as Map<dynamic, dynamic>?;
      final oldConnected = (oldPlayerMap?['isConnected'] as bool?) ?? false;

      if (oldConnected && !newConnected) {
        // Jugador pasó de conectado a desconectado
        _disconnectNotification = uid;
        debugPrint('=== DISCONNECT: Jugador $uid se desconectó');
      } else if (!oldConnected && newConnected) {
        // Jugador se reconectó
        _disconnectNotification = 'reconnected:$uid';
        debugPrint('=== RECONNECT: Jugador $uid se reconectó');
      }
    });
  }

  /// Limpia la notificación de desconexión después de mostrarla en la UI
  void clearDisconnectNotification() {
    _disconnectNotification = null;
  }

  /// Vigila la conexión del host actual.
  /// Si el host se desconecta por más de 15 segundos, se migra al siguiente
  /// jugador conectado de forma determinista (primer UID alfabéticamente).
  void _startHostWatcher() {
    _hostPresenceSubscription?.cancel();
    _hostMigrationTimer?.cancel();

    if (_roomCode == null || _roomHostUid == null) return;
    // El host no se vigila a sí mismo
    if (_localUid == _roomHostUid) return;

    final hostConnRef = FirebaseDatabase.instance
        .ref('games/$_roomCode/players/$_roomHostUid/isConnected');

    _hostPresenceSubscription = hostConnRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;

      if (!isConnected) {
        // Host se desconectó — iniciar timer de migración
        _hostMigrationTimer?.cancel();
        _hostMigrationTimer = Timer(const Duration(seconds: 15), () {
          debugPrint('=== HOST MIGRATION: Timer de 15s expirado, migrando host');
          _migrateHost();
        });
      } else {
        // Host reconectó — cancelar migración
        _hostMigrationTimer?.cancel();
      }
    });
  }

  /// Ejecuta la migración de host.
  /// Solo el primer jugador conectado (alfabéticamente por UID) ejecuta la
  /// escritura para evitar race conditions entre múltiples clientes.
  Future<void> _migrateHost() async {
    if (_roomCode == null || _localUid == null) return;

    // Obtener jugadores conectados (excluyendo al host desconectado)
    final connectedUids = <String>[];
    _playersData.forEach((uid, data) {
      final playerMap = data as Map<dynamic, dynamic>?;
      final isConn = (playerMap?['isConnected'] as bool?) ?? false;
      if (isConn && uid != _roomHostUid) {
        connectedUids.add(uid);
      }
    });

    if (connectedUids.isEmpty) return;

    // Orden determinista: alfabético por UID
    connectedUids.sort();
    final newHostUid = connectedUids.first;

    // Solo el elegido ejecuta la migración
    if (_localUid != newHostUid) {
      debugPrint('=== HOST MIGRATION: No soy el elegido ($newHostUid), esperando...');
      return;
    }

    try {
      debugPrint('=== HOST MIGRATION: Migrando host de $_roomHostUid a $newHostUid');
      await _firestoreService.updateRoomHost(_roomCode!, newHostUid);
      _roomHostUid = newHostUid;
      notifyListeners();

      // Ya soy host, dejar de vigilar la presencia del host anterior
      _hostPresenceSubscription?.cancel();
      _hostMigrationTimer?.cancel();
    } catch (e) {
      debugPrint('Error en migración de host: $e');
    }
  }

  /// Procesa cambios en el estado del juego desde RTDB
  void _onGameStateChanged(Map<String, dynamic> state) {
    if (state.isEmpty) return;

    // Solo actualizar _currentPhase si el campo 'phase' viene EXPLÍCITO en el state.
    // Si falta (e.g. setPunishmentMedia() solo actualiza punishmentMediaUrl/Type),
    // GamePhase.fromString(null) devolvería 'selecting' erróneamente.
    final incomingPhaseStr = state['phase'] as String?;
    if (incomingPhaseStr != null) {
      final newPhase = GamePhase.fromString(incomingPhaseStr);
      if (newPhase != GamePhase.answering) {
        _currentAnswer = '';
      }
      // Al reiniciar (fase selecting), limpiar TODO el estado de la partida anterior
      if (newPhase == GamePhase.selecting &&
          _currentPhase != GamePhase.selecting) {
        _loserUid = '';
        _punishmentMediaUrl = null;
        _punishmentType = null;
        _finalScores = {};
        _gameFinished = false;
        debugPrint(
          '=== STATE: Reinicio detectado — limpiando datos de partida anterior',
        );
      }
      _currentPhase = newPhase;
    } else {
      debugPrint(
        '=== STATE: sin campo phase, manteniendo fase actual: ${_currentPhase.name}',
      );
    }

    _currentLetter = state['currentLetter'] as String? ?? _currentLetter;
    _currentCategory = state['currentCategory'] as String? ?? _currentCategory;
    _currentRoundId = state['roundId'] as String? ?? _currentRoundId;
    _activePlayerUid = state['activePlayer'] as String? ?? _activePlayerUid;
    _timerEnd = state['timerEnd'] as int? ?? _timerEnd;

    _unlockOrphanLetters();

    // Estos campos solo se actualizan si vienen en el nuevo estado.
    // Una vez poblados persisten en memoria durante la partida.
    // Solo se limpian explícitamente en el bloque de reinicio (selecting) de arriba.
    final incomingLoser = state['loserUid'] as String?;
    if (incomingLoser != null && incomingLoser.isNotEmpty) {
      _loserUid = incomingLoser;
    }

    final incomingMediaUrl = state['punishmentMediaUrl'] as String?;
    if (incomingMediaUrl != null && incomingMediaUrl.isNotEmpty) {
      _punishmentMediaUrl = incomingMediaUrl;
    }

    final incomingMediaType = state['punishmentType'] as String?;
    if (incomingMediaType != null && incomingMediaType.isNotEmpty) {
      _punishmentType = incomingMediaType;
    }

    if (state['finalScores'] != null) {
      try {
        // RTDB retorna Map con claves Object? — NO usar Map<String,dynamic>.from()
        // porque lanza cast silencioso. Usar Object? y convertir explícitamente.
        final rawScores = state['finalScores'];
        final Map<Object?, Object?> scoresMap = Map<Object?, Object?>.from(
          rawScores as Map,
        );

        _finalScores = {};
        scoresMap.forEach((key, value) {
          if (key != null && value != null) {
            _finalScores[key.toString()] = (value as num).toInt();
          }
        });
        debugPrint('=== SCORES MAPEADOS: $_finalScores');
      } catch (e) {
        debugPrint('=== ERROR mapeando scores: $e');
        // No limpiar _finalScores si ya teníamos datos válidos
        if (_finalScores.isEmpty) _finalScores = {};
      }
    }
    // NOTA: NO limpiar _finalScores si el nuevo state no los trae.
    // Una vez poblados deben persistir en memoria hasta disconnectFromGame().

    debugPrint('=== STATE CHANGE: phase=${_currentPhase.name}');
    debugPrint('=== STATE CHANGE: finalScores=$_finalScores');

    // Actualizar countdown si hay un timer activo
    if (_timerEnd > 0) {
      _startCountdown();
    } else {
      _stopCountdown();
    }

    notifyListeners();
  }

  bool _allLettersUsed() {
    if (_letters.isEmpty) return false;
    return _letters.values.every(
      (l) => l.status == LetterStatus.used || l.status == LetterStatus.locked,
    );
  }

  /// Activa el fin del juego. Solo el host debe llamar este método.
  /// Se llama desde evaluation_screen.onAllVotesSubmitted cuando
  /// todas las letras ya están usadas.
  Future<void> triggerFinishGame() async {
    if (_roomCode == null) return;
    if (!_gameFinished) {
      _gameFinished = true;
    }
    debugPrint('=== triggerFinishGame: llamando _finishGame()');
    await _finishGame();
  }

  Future<void> _finishGame() async {
    if (_roomCode == null) return;

    try {
      debugPrint('=== FINISH: Leyendo scores de RTDB...');
      final ref = FirebaseDatabase.instance.ref('games/$_roomCode/players');
      final snapshot = await ref.get();

      final Map<String, int> finalScores = {};
      String? loserUid;
      String? winnerUid;
      int minScore = 999999;
      int maxScore = -1;

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        data.forEach((uid, value) {
          final playerMap = Map<String, dynamic>.from(value as Map);
          final score = (playerMap['roundScore'] ?? 0) as int;
          final uidStr = uid.toString();
          finalScores[uidStr] = score;

          if (score < minScore) {
            minScore = score;
            loserUid = uidStr;
          }
          if (score > maxScore) {
            maxScore = score;
            winnerUid = uidStr;
          }
        });
      }

      debugPrint('=== FINISH: Scores encontrados: $finalScores');

      // Verificar que el perdedor esté conectado.
      // Si no lo está, reasignar el castigo al siguiente jugador con menor
      // puntaje que sí esté conectado.
      if (loserUid != null && snapshot.exists) {
        final loserData = (snapshot.value as Map)[loserUid] as Map?;
        final loserConnected = (loserData?['isConnected'] as bool?) ?? false;

        if (!loserConnected) {
          debugPrint('=== FINISH: Perdedor $loserUid está desconectado, buscando reemplazo...');

          // Ordenar jugadores por puntaje ascendente para encontrar al siguiente
          final sortedByScore = finalScores.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          String? replacementLoser;
          for (final entry in sortedByScore) {
            final pData = (snapshot.value as Map)[entry.key] as Map?;
            final isConn = (pData?['isConnected'] as bool?) ?? false;
            if (isConn) {
              replacementLoser = entry.key;
              break;
            }
          }

          if (replacementLoser != null) {
            debugPrint('=== FINISH: Castigo reasignado a $replacementLoser');
            loserUid = replacementLoser;
          } else {
            debugPrint('=== FINISH: Ningún jugador conectado, manteniendo perdedor original');
          }
        }
      }

      if (loserUid != null) {
        // Finalizar juego en RTDB (fase punishment, loserUid, finalScores)
        await _rtdbService.finishGame(
          roomCode: _roomCode!,
          loserUid: loserUid!,
          finalScores: finalScores,
        );

        // 2. Actualizar estado de sala en Firestore a finished
        await _firestoreService.updateRoomStatus(
          _roomCode!,
          RoomStatus.finished,
        );

        // 3. Actualizar estadísticas globales para cada jugador
        for (final entry in finalScores.entries) {
          final playerUid = entry.key;
          final score = entry.value;
          final isWinner = playerUid == winnerUid;

          try {
            await _firestoreService.updateUserStats(
              uid: playerUid,
              pointsEarned: score,
              won: isWinner,
            );
            await _firestoreService.updateLeaderboardStats(
              uid: playerUid,
              pointsEarned: score,
            );
          } catch (e) {
            debugPrint('Error actualizando stats para $playerUid: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error al finalizar la partida: $e');
    }
  }

  // ══════════════════════════════════════
  // SELECCIÓN DE LETRAS
  // ══════════════════════════════════════

  /// Intenta reclamar una letra de la rueda.
  /// Usa optimistic UI: bloquea visualmente de inmediato, rollback si falla.
  Future<bool> claimLetter({
    required String char,
    required String uid,
    required String username,
  }) async {
    if (_roomCode == null) return false;
    if (!canSelectLetter) return false;

    // Verificar que la letra está libre
    final letter = _letters[char];
    if (letter == null || !letter.isFree) {
      _errorMessage = AppStrings.letterAlreadyTaken;
      notifyListeners();
      return false;
    }

    _errorMessage = null;

    try {
      // Optimistic UI: actualizar localmente primero
      _letters[char] = letter.copyWith(
        status: LetterStatus.locked,
        claimedBy: uid,
        claimedByUsername: username,
      );
      notifyListeners();

      // Intentar bloqueo atómico en RTDB
      final success = await _rtdbService.claimLetter(
        roomCode: _roomCode!,
        char: char,
        uid: uid,
        username: username,
      );

      if (!success) {
        // Rollback: la letra ya fue tomada por otro jugador
        _letters[char] = letter; // Restaurar estado original
        _errorMessage = AppStrings.letterAlreadyTaken;
        notifyListeners();
        return false;
      }

      // Éxito: actualizar el estado del juego a "answering"
      final timePerTurn = 30; // Se obtiene de la sala
      final timerEnd =
          DateTime.now().millisecondsSinceEpoch + (timePerTurn * 1000);

      await _rtdbService.updateGameState(
        _roomCode!,
        phase: GamePhase.answering,
        currentLetter: char,
        activePlayer: uid,
        timerEnd: timerEnd,
      );

      return true;
    } on AppException catch (e) {
      // Rollback en caso de error
      _letters[char] = letter;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _letters[char] = letter;
      _errorMessage = 'Error al reclamar letra: $e';
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════
  // ENVÍO DE RESPUESTA
  // ══════════════════════════════════════

  /// Actualiza la respuesta del jugador mientras escribe
  void updateAnswer(String value) {
    if (_currentPhase != GamePhase.answering) return;
    _currentAnswer = value;
    notifyListeners();
  }

  /// Envía la respuesta del jugador para la letra actual
  Future<bool> submitAnswer({
    required String uid,
    required String username,
    required String roundId,
  }) async {
    if (_roomCode == null || _currentAnswer.trim().isEmpty) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Guardar respuesta en Firestore
      final response = ResponseModel(
        letterId: _currentLetter,
        word: _currentAnswer.trim(),
        submittedBy: uid,
        submittedByUsername: username,
        submittedAt: DateTime.now(),
      );

      await _firestoreService.submitResponse(_roomCode!, roundId, response);

      // Marcar la letra como usada en RTDB
      await _rtdbService.markLetterUsed(_roomCode!, _currentLetter);

      // SIEMPRE ir a evaluación — incluso la última letra debe ser votada.
      // _finishGame() se llamará desde evaluation_screen.onAllVotesSubmitted
      // cuando allLettersUsed=true.
      await _rtdbService.updateGameState(
        _roomCode!,
        phase: GamePhase.evaluating,
        timerEnd: 0,
      );

      _currentAnswer = '';
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al enviar respuesta: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Se acabó el tiempo sin responder
  Future<void> handleTimeUp() async {
    if (_roomCode == null) return;

    try {
      // Liberar la letra (no se usó)
      if (_currentLetter.isNotEmpty) {
        await _rtdbService.releaseLetter(_roomCode!, _currentLetter);
      }

      // Volver a fase de selección
      await _rtdbService.updateGameState(
        _roomCode!,
        phase: GamePhase.selecting,
        currentLetter: '',
        activePlayer: '',
        timerEnd: 0,
      );
    } catch (e) {
      debugPrint('Error en handleTimeUp: $e');
    }
  }

  // ══════════════════════════════════════
  // CAMBIO DE CATEGORÍA / RONDA
  // ══════════════════════════════════════

  /// Avanza a la siguiente categoría después de la evaluación
  Future<void> nextCategory() async {
    if (_roomCode == null) return;

    // No avanzar si el juego ya terminó (evita race condition con _finishGame)
    if (_gameFinished ||
        _currentPhase == GamePhase.punishment ||
        _currentPhase == GamePhase.results) {
      debugPrint(
        '=== nextCategory() bloqueado: fase=${_currentPhase.name}, _gameFinished=$_gameFinished',
      );
      return;
    }

    try {
      // Seleccionar nueva categoría aleatoria
      final categories = List<String>.from(AppStrings.gameCategories)
        ..shuffle();
      final newCategory = categories.first;

      await _rtdbService.updateGameState(
        _roomCode!,
        phase: GamePhase.selecting,
        currentCategory: newCategory,
        currentLetter: '',
        activePlayer: '',
        timerEnd: 0,
      );

      // Guard post-write: si mientras se ejecutaba el await, el juego terminó
      // (triggerFinishGame lo marcó en _gameFinished), restaurar punishment
      // para que 'selecting' no quede en RTDB por encima de 'punishment'.
      if (_gameFinished && _roomCode != null) {
        debugPrint(
          '=== nextCategory: detectado _gameFinished=true post-write → restaurando punishment',
        );
        await _rtdbService.updateGamePhase(_roomCode!, GamePhase.punishment);
      }
    } catch (e) {
      debugPrint('Error al cambiar categoría: $e');
    }
  }

  /// Termina el juego y va a resultados
  Future<void> endGame() async {
    if (_roomCode == null) return;

    try {
      await _rtdbService.updateGamePhase(_roomCode!, GamePhase.results);
    } catch (e) {
      debugPrint('Error al terminar juego: $e');
    }
  }

  // ══════════════════════════════════════
  // TIMER
  // ══════════════════════════════════════

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateRemainingTime();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }

  bool _isTickTockPlaying = false;

  void _updateRemainingTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((_timerEnd - now) / 1000).ceil();
    _remainingSeconds = remaining > 0 ? remaining : 0;

    if (_remainingSeconds <= 10 && _remainingSeconds > 0 && _currentPhase == GamePhase.answering) {
      if (!_isTickTockPlaying) {
        _isTickTockPlaying = true;
        AudioManagerService().startLoopSfx('tick-tock.wav');
      }
    } else {
      if (_isTickTockPlaying) {
        _isTickTockPlaying = false;
        AudioManagerService().stopLoopSfx();
      }
    }

    if (_remainingSeconds <= 0) {
      if (_currentPhase == GamePhase.answering) {
        AudioManagerService().playSfx('alarma.wav');
      }
      _stopCountdown();
      // Si soy el jugador activo y se me acabó el tiempo, libero la letra
      if (_currentPhase == GamePhase.answering &&
          _activePlayerUid.isNotEmpty &&
          _activePlayerUid == _localUid) {
        handleTimeUp();
      }
    }

    notifyListeners();
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ══════════════════════════════════════
  // PUNTAJES
  // ══════════════════════════════════════

  /// Obtiene el puntaje de un jugador en la ronda actual
  int getPlayerScore(String uid) {
    final playerData = _playersData[uid] as Map<dynamic, dynamic>?;
    return (playerData?['roundScore'] as int?) ?? 0;
  }

  /// Obtiene si un jugador está conectado
  bool isPlayerConnected(String uid) {
    final playerData = _playersData[uid] as Map<dynamic, dynamic>?;
    return (playerData?['isConnected'] as bool?) ?? false;
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Desconecta del juego y limpia todo el estado
  void disconnectFromGame(String uid) {
    if (_roomCode != null) {
      _rtdbService.setPlayerConnection(_roomCode!, uid, false);
    }

    _stateSubscription?.cancel();
    _lettersSubscription?.cancel();
    _playersSubscription?.cancel();
    _forceLogoutSubscription?.cancel();
    _hostPresenceSubscription?.cancel();
    _hostMigrationTimer?.cancel();
    _stopCountdown();

    _roomCode = null;
    _localUid = null;
    _roomHostUid = null;
    _loserUid = '';
    _finalScores = {};
    _letters = {};
    _playersData = {};
    _currentPhase = GamePhase.selecting;
    _currentLetter = '';
    _currentCategory = '';
    _activePlayerUid = '';
    _currentAnswer = '';
    _remainingSeconds = 0;
    _errorMessage = null;
    _punishmentMediaUrl = null;
    _punishmentType = null;
    _gameFinished = false; // resetear flag al desconectar

    notifyListeners();
  }

  /// Sale de la sala en Firestore si está activa
  Future<void> leaveRoom() async {
    if (_roomCode == null || _localUid == null) return;
    try {
      final room = await _firestoreService.getRoom(_roomCode!);
      if (room != null) {
        final player = room.players.cast<PlayerRef?>().firstWhere(
          (p) => p?.uid == _localUid,
          orElse: () => null,
        );
        if (player != null) {
          await _firestoreService.leaveRoom(_roomCode!, player);
        }
      }
    } catch (e) {
      debugPrint('Error al salir de la sala: $e');
    }
  }

  /// Reinicia el juego (solo host)
  Future<bool> restartGame() async {
    if (_roomCode == null) return false;
    _setLoading(true);
    try {
      // Seleccionar nueva categoría aleatoria
      final categories = List<String>.from(AppStrings.gameCategories)
        ..shuffle();
      final newCategory = categories.first;

      final playerUids = _playersData.keys.toList();
      await _rtdbService.restartGame(
        roomCode: _roomCode!,
        newCategory: newCategory,
        playerUids: playerUids,
      );

      // Resetear flag para nueva partida
      _gameFinished = false;

      // Cambiar estado de sala en Firestore a playing
      await _firestoreService.updateRoomStatus(_roomCode!, RoomStatus.playing);

      return true;
    } catch (e) {
      _errorMessage = 'Error al reiniciar el juego: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpia los datos del juego de RTDB al terminar
  Future<void> cleanupGame(String roomCode) async {
    try {
      await _rtdbService.cleanupGame(roomCode);
    } catch (e) {
      debugPrint('Error al limpiar datos de RTDB: $e');
    }
  }

  void _startForceLogoutListener(String uid) {
    _forceLogoutSubscription?.cancel();
    _forceLogoutSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;
          final data = snapshot.data();
          if (data?['forceLogout'] == true) {
            await leaveRoom();
            disconnectFromGame(uid);
          }
        });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _unlockOrphanLetters() {
    if (_roomCode == null || _localUid == null || _localUid != _roomHostUid) return;
    if (_currentPhase != GamePhase.selecting) return;

    _letters.forEach((char, letter) {
      if (letter.isLocked) {
        debugPrint('=== UNLOCK ORPHAN: Liberando letra $char bloqueada en fase selecting');
        _rtdbService.releaseLetter(_roomCode!, char);
      }
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _lettersSubscription?.cancel();
    _playersSubscription?.cancel();
    _forceLogoutSubscription?.cancel();
    _hostPresenceSubscription?.cancel();
    _hostMigrationTimer?.cancel();
    _stopCountdown();
    super.dispose();
  }
}
