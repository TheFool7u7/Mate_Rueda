import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'package:wordwonderslink/features/game/domain/letter_model.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Fases del juego en tiempo real
enum GamePhase {
  selecting, // Jugadores seleccionan letras
  answering, // Un jugador está respondiendo
  evaluating, // Jugadores califican la respuesta
  punishment, // Fase de castigo
  results; // Resultados finales

  static GamePhase fromString(String? value) {
    switch (value) {
      case 'answering':
        return GamePhase.answering;
      case 'evaluating':
        return GamePhase.evaluating;
      case 'punishment':
        return GamePhase.punishment;
      case 'results':
        return GamePhase.results;
      default:
        return GamePhase.selecting;
    }
  }
}

/// Servicio de Firebase Realtime Database para estado en vivo del juego.
/// Gestiona: fase del juego, turnos, letras (bloqueo atómico), timer, presencia.
/// Usa transacciones para concurrencia segura en el bloqueo de letras.
class RealtimeDbService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // ── Referencias base ──
  DatabaseReference _gameRef(String roomCode) => _rtdb.ref('games/$roomCode');

  DatabaseReference _stateRef(String roomCode) =>
      _rtdb.ref('games/$roomCode/state');

  DatabaseReference _lettersRef(String roomCode) =>
      _rtdb.ref('games/$roomCode/letters');

  DatabaseReference _letterRef(String roomCode, String char) =>
      _rtdb.ref('games/$roomCode/letters/$char');

  DatabaseReference _playersRef(String roomCode) =>
      _rtdb.ref('games/$roomCode/players');

  DatabaseReference _playerRef(String roomCode, String uid) =>
      _rtdb.ref('games/$roomCode/players/$uid');

  // ══════════════════════════════════════
  // INICIALIZACIÓN DEL JUEGO
  // ══════════════════════════════════════

  /// Inicializa el estado del juego en RTDB al comenzar la partida.
  /// Crea la estructura: state, letters (27 del español), players.
  Future<void> initializeGame({
    required String roomCode,
    required String firstCategory,
    required List<String> playerUids,
  }) async {
    try {
      // Letras del alfabeto español
      const alphabet = [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'Ñ',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
      ];

      final Map<String, dynamic> gameData = {
        'state': {
          'phase': GamePhase.selecting.name,
          'currentLetter': '',
          'currentCategory': firstCategory,
          'roundId':
              'round_${firstCategory}_${DateTime.now().millisecondsSinceEpoch}',
          'timerEnd': 0,
          'activePlayer': '',
        },
        'letters': {
          for (final char in alphabet)
            char: {
              'status': LetterStatus.free.name,
              'lockedBy': null,
              'lockedByUsername': null,
            },
        },
        'players': {
          for (final uid in playerUids)
            uid: {'roundScore': 0, 'isConnected': true},
        },
      };

      await _gameRef(roomCode).set(gameData);
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al inicializar juego: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // ESTADO DEL JUEGO
  // ══════════════════════════════════════

  /// Actualiza la fase del juego
  Future<void> updateGamePhase(String roomCode, GamePhase phase) async {
    try {
      await _stateRef(roomCode).update({'phase': phase.name});
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al actualizar fase: $e',
        originalError: e,
      );
    }
  }

  /// Actualiza el estado completo del juego (fase, letra, categoría, timer)
  Future<void> updateGameState(
    String roomCode, {
    GamePhase? phase,
    String? currentLetter,
    String? currentCategory,
    int? timerEnd,
    String? activePlayer,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (phase != null) updates['phase'] = phase.name;
      if (currentLetter != null) updates['currentLetter'] = currentLetter;
      if (currentCategory != null) updates['currentCategory'] = currentCategory;
      if (timerEnd != null) updates['timerEnd'] = timerEnd;
      if (activePlayer != null) updates['activePlayer'] = activePlayer;

      if (updates.isNotEmpty) {
        await _stateRef(roomCode).update(updates);
      }
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al actualizar estado del juego: $e',
        originalError: e,
      );
    }
  }

  /// Stream del estado del juego (fase, turno, timer)
  Stream<Map<String, dynamic>> watchGameState(String roomCode) {
    return _stateRef(roomCode).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(data);
    });
  }

  // ══════════════════════════════════════
  // BLOQUEO ATÓMICO DE LETRAS
  // ══════════════════════════════════════

  /// Reclama una letra usando una transacción atómica.
  /// Si la letra ya tiene status != "free", la transacción falla.
  /// Retorna true si se logró reclamar, false si ya estaba tomada.
  Future<bool> claimLetter({
    required String roomCode,
    required String char,
    required String uid,
    required String username,
  }) async {
    try {
      final ref = _letterRef(roomCode, char);

      final result = await ref.runTransaction((currentData) {
        if (currentData == null) {
          return Transaction.abort();
        }

        final data = Map<String, dynamic>.from(currentData as Map);
        final currentStatus = data['status'] as String?;

        // Solo permitir reclamar si la letra está libre
        if (currentStatus != LetterStatus.free.name) {
          return Transaction.abort();
        }

        // Bloquear la letra para este jugador
        data['status'] = LetterStatus.locked.name;
        data['lockedBy'] = uid;
        data['lockedByUsername'] = username;

        return Transaction.success(data);
      });

      return result.committed;
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al reclamar letra "$char": $e',
        originalError: e,
      );
    }
  }

  /// Libera una letra previamente bloqueada (rollback si falla la respuesta)
  Future<void> releaseLetter(String roomCode, String char) async {
    try {
      await _letterRef(roomCode, char).update({
        'status': LetterStatus.free.name,
        'lockedBy': null,
        'lockedByUsername': null,
      });
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al liberar letra "$char": $e',
        originalError: e,
      );
    }
  }

  /// Marca una letra como usada después de que se envió la respuesta
  Future<void> markLetterUsed(String roomCode, String char) async {
    try {
      await _letterRef(
        roomCode,
        char,
      ).update({'status': LetterStatus.used.name});
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al marcar letra "$char" como usada: $e',
        originalError: e,
      );
    }
  }

  /// Stream de todas las letras (para actualizar la rueda en tiempo real)
  Stream<Map<String, LetterModel>> watchLetters(String roomCode) {
    return _lettersRef(roomCode).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <String, LetterModel>{};

      return data.map((key, value) {
        final char = key.toString();
        final letterData = Map<String, dynamic>.from(value as Map);
        return MapEntry(char, LetterModel.fromRtdb(char, letterData));
      });
    });
  }

  // ══════════════════════════════════════
  // JUGADORES / PRESENCIA
  // ══════════════════════════════════════

  /// Actualiza el puntaje de un jugador en la ronda actual
  Future<void> updatePlayerScore(
    String roomCode,
    String uid,
    int scoreToAdd,
  ) async {
    try {
      final ref = _playerRef(roomCode, uid).child('roundScore');
      await ref.runTransaction((currentData) {
        final current = (currentData as int?) ?? 0;
        return Transaction.success(current + scoreToAdd);
      });
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al actualizar puntaje: $e',
        originalError: e,
      );
    }
  }

  /// Marca la conexión/desconexión de un jugador
  Future<void> setPlayerConnection(
    String roomCode,
    String uid,
    bool isConnected,
  ) async {
    try {
      await _playerRef(roomCode, uid).update({'isConnected': isConnected});
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al actualizar conexión: $e',
        originalError: e,
      );
    }
  }

  /// Configura la desconexión automática al perder conexión
  Future<void> setupPresence(String roomCode, String uid) async {
    try {
      final connectedRef = _rtdb.ref('.info/connected');
      final playerConnRef = _playerRef(roomCode, uid).child('isConnected');

      connectedRef.onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        if (connected) {
          // Al reconectar, marcar como conectado
          playerConnRef.set(true);
          // Al desconectar, marcar como desconectado automáticamente
          playerConnRef.onDisconnect().set(false);
        }
      });
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al configurar presencia: $e',
        originalError: e,
      );
    }
  }

  /// Stream de los datos de todos los jugadores
  Stream<Map<String, dynamic>> watchPlayers(String roomCode) {
    return _playersRef(roomCode).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(data);
    });
  }

  // ══════════════════════════════════════
  // FINALIZACIÓN Y REINICIO
  // ══════════════════════════════════════

  /// Finaliza el juego en RTDB actualizando la fase, perdedor y puntajes finales
  Future<void> finishGame({
    required String roomCode,
    required String loserUid,
    required Map<String, int> finalScores,
  }) async {
    try {
      await _stateRef(roomCode).update({
        'phase': GamePhase.punishment.name,
        'loserUid': loserUid,
        'finalScores': finalScores,
      });
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al finalizar juego en RTDB: $e',
        originalError: e,
      );
    }
  }

  /// Reinicia el estado del juego para volver a jugar
  Future<void> restartGame({
    required String roomCode,
    required String newCategory,
    required List<String> playerUids,
  }) async {
    try {
      const alphabet = [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'Ñ',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
      ];

      final Map<String, dynamic> updates = {
        'state': {
          'phase': GamePhase.selecting.name,
          'currentLetter': '',
          'currentCategory': newCategory,
          'roundId':
              'round_${newCategory}_${DateTime.now().millisecondsSinceEpoch}',
          'timerEnd': 0,
          'activePlayer': '',
          'loserUid': '',
          'finalScores': null,
          'punishmentMediaUrl': null,
          'punishmentType': null,
        },
        'letters': {
          for (final char in alphabet)
            char: {
              'status': LetterStatus.free.name,
              'lockedBy': null,
              'lockedByUsername': null,
            },
        },
        'players': {
          for (final uid in playerUids)
            uid: {'roundScore': 0, 'isConnected': true},
        },
      };

      await _gameRef(roomCode).update(updates);
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al reiniciar juego: $e',
        originalError: e,
      );
    }
  }

  /// Guarda la URL del archivo y el tipo de castigo en RTDB
  Future<void> setPunishmentMedia({
    required String roomCode,
    required String mediaUrl,
    required String punishmentType,
    String? targetColor,
  }) async {
    try {
      debugPrint('=== RTDB: Guardando mediaUrl: $mediaUrl');
      debugPrint('=== RTDB: En ruta: games/$roomCode/state');
      final updateData = {
        'punishmentMediaUrl': mediaUrl,
        'punishmentType': punishmentType,
      };
      if (targetColor != null) {
        updateData['punishmentTargetColor'] = targetColor;
      }
      await _stateRef(roomCode).update(updateData);
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al guardar multimedia del castigo: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Elimina todos los datos del juego al terminar la partida
  Future<void> cleanupGame(String roomCode) async {
    try {
      await _gameRef(roomCode).remove();
    } catch (e) {
      throw RealtimeDbException(
        message: 'Error al limpiar datos del juego: $e',
        originalError: e,
      );
    }
  }
}
