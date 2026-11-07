import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/online_game/data/mate_room_backend.dart';

/// Fase actual de una partida.
enum LocalPhase { lobby, spinning, challenge, feedback, results }

/// Mesa / grupo que juega y sus estrellas acumuladas.
class TeamScore {
  TeamScore({
    required this.name,
    required this.color,
    this.uid,
    this.stars = 0,
    this.answered = 0,
  });

  final String name;
  final Color color;

  /// Dispositivo que controla esta mesa (solo en modo varios dispositivos).
  final String? uid;
  int stars;
  int answered;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (uid != null) 'uid': uid,
    'stars': stars,
    'answered': answered,
  };
}

/// Controla una partida de MateRueda: mesas por turnos, ruleta, reto,
/// retroalimentación y marcador.
///
/// Soporta dos modos con las mismas pantallas:
/// - **Un dispositivo** (`isOnline == false`): todas las mesas juegan por
///   turnos en la misma pantalla, sin internet ni Firebase.
/// - **Varios dispositivos** (`isOnline == true`): la docente crea una sala
///   con código (`isHost == true`) y cada mesa se une desde su propio
///   dispositivo (`isHost == false`), sincronizados mediante
///   [MateRoomBackend] (Firebase Realtime Database).
class LocalGameController extends ChangeNotifier {
  LocalGameController({Random? random, MateRoomBackend? backend})
    : _rng = random ?? Random(),
      _defaultBackend = backend;

  final Random _rng;
  final MateRoomBackend? _defaultBackend;

  static const List<Color> teamColors = [
    MateColors.coralEnergia,
    MateColors.turquesaCalma,
    MateColors.amarilloEstrella,
    MateColors.moradoRueda,
    MateColors.cielo,
    Color(0xFF7BC96F),
  ];

  static const int minTeams = 1;
  static const int maxTeams = 6;
  static const List<int> roundOptions = [5, 10, 15];

  /// Umbral máximo de sincronización permitido por RNF05 (3 segundos).
  static const int rnf05MaxMs = 3000;

  // ── Estado de conexión (modo varios dispositivos) ──
  MateRoomBackend? _backend;
  bool _isOnline = false;
  bool _isHost = true;
  String? _roomCode;
  int? _myTeamIndex;
  int spinTrigger = 0;

  StreamSubscription<List<String>>? _membersSub;
  StreamSubscription<Map<String, dynamic>?>? _stateSub;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _answersSub;

  /// Tiempos de sincronización medidos en milisegundos (evidencia RNF05).
  final List<int> syncLatenciesMs = [];

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  /// `true` cuando la partida se juega entre varios dispositivos.
  bool get isOnline => _isOnline;

  /// `true` si este dispositivo conduce la partida (docente / proyector).
  bool get isHost => !_isOnline || _isHost;

  /// `true` si este dispositivo puede responder el reto actual.
  bool get isMyTurn {
    if (!_isOnline || _isHost) return true;
    return _myTeamIndex != null && _myTeamIndex == currentTeamIndex;
  }

  /// Código de la sala (solo modo varios dispositivos).
  String? get roomCode => _roomCode;

  /// Índice (0-based) de la mesa asignada a este dispositivo cliente.
  int? get myTeamIndex => _myTeamIndex;

  /// Proporción (0..1) de acciones sincronizadas en ≤ 3 s (RNF05).
  double get rnf05ComplianceRatio {
    if (syncLatenciesMs.isEmpty) return 1.0;
    final ok = syncLatenciesMs.where((ms) => ms <= rnf05MaxMs).length;
    return ok / syncLatenciesMs.length;
  }

  /// Latencia promedio de sincronización en milisegundos.
  int get averageLatencyMs {
    if (syncLatenciesMs.isEmpty) return 0;
    final total = syncLatenciesMs.fold(0, (a, b) => a + b);
    return (total / syncLatenciesMs.length).round();
  }

  // ── Configuración ──
  int teamCount = 3;
  int totalRounds = 5;
  ChallengeSettings settings = ChallengeSettings.basico;

  // ── Estado de la partida ──
  LocalPhase phase = LocalPhase.lobby;
  List<TeamScore> teams = [];
  int round = 0; // 1..totalRounds una vez iniciada
  int currentTeamIndex = 0;
  MathCategory? category;
  MathChallenge? challenge;
  int? lastAnswerIndex;
  bool? lastCorrect;

  late MathChallengeGenerator _generator = MathChallengeGenerator(
    _rng,
    settings,
  );

  TeamScore get currentTeam =>
      teams[currentTeamIndex.clamp(0, max(0, teams.length - 1))];

  /// Avance 0..1 para la barra amarilla del reto.
  double get progress => totalRounds == 0 ? 0 : round / totalRounds;

  bool get isLastRound => round >= totalRounds;

  int get totalStars => teams.fold(0, (sum, t) => sum + t.stars);

  /// Mesas ordenadas por estrellas (de mayor a menor) para el podio.
  List<TeamScore> get ranking =>
      List.of(teams)..sort((a, b) => b.stars.compareTo(a.stars));

  // ── Configuración previa a la partida (1 dispositivo) ──
  void configure({
    int? teamCount,
    int? totalRounds,
    ChallengeSettings? settings,
  }) {
    _cancelSubscriptions();
    _isOnline = false;
    _isHost = true;
    _roomCode = null;
    _myTeamIndex = null;
    if (teamCount != null) {
      this.teamCount = teamCount.clamp(minTeams, maxTeams);
    }
    if (totalRounds != null) this.totalRounds = max(1, totalRounds);
    if (settings != null) this.settings = settings;
    _generator = MathChallengeGenerator(_rng, this.settings);
    _buildTeams();
    phase = LocalPhase.lobby;
    notifyListeners();
  }

  void _buildTeams() {
    teams = [
      for (var i = 0; i < teamCount; i++)
        TeamScore(
          name: 'Mesa ${i + 1}',
          color: teamColors[i % teamColors.length],
        ),
    ];
  }

  // ── Modo varios dispositivos (Firebase / MateRoomBackend) ──

  /// Crea una sala compartida donde la docente es anfitriona y las mesas se
  /// conectan con un código de 5 caracteres.
  Future<String> createOnlineRoom({
    int? totalRounds,
    ChallengeSettings? settings,
    MateRoomBackend? backend,
  }) async {
    _cancelSubscriptions();
    if (totalRounds != null) this.totalRounds = max(1, totalRounds);
    if (settings != null) this.settings = settings;
    _generator = MathChallengeGenerator(_rng, this.settings);

    _backend = backend ?? _defaultBackend ?? FirebaseMateRoomBackend();
    final code = await _backend!.createRoom();

    _isOnline = true;
    _isHost = true;
    _roomCode = code;
    _myTeamIndex = null;
    round = 0;
    currentTeamIndex = 0;
    spinTrigger = 0;
    syncLatenciesMs.clear();
    teams = [];
    _resetRound();
    phase = LocalPhase.lobby;

    _membersSub = _backend!.watchMembers(code).listen(_onMembersChanged);
    _answersSub = _backend!.watchAnswers(code).listen(_onAnswersChanged);

    await _publishIfHost();
    notifyListeners();
    return code;
  }

  /// Une este dispositivo como una mesa a la sala con código [rawCode].
  /// Devuelve `false` si el código no existe.
  Future<bool> joinOnlineRoom(
    String rawCode, {
    MateRoomBackend? backend,
  }) async {
    final code = normalizeRoomCode(rawCode);
    if (code.isEmpty) return false;

    _cancelSubscriptions();
    _backend = backend ?? _defaultBackend ?? FirebaseMateRoomBackend();
    final ok = await _backend!.joinRoom(code);
    if (!ok) return false;

    _isOnline = true;
    _isHost = false;
    _roomCode = code;
    _myTeamIndex = null;
    syncLatenciesMs.clear();
    phase = LocalPhase.lobby;

    _stateSub = _backend!.watchState(code).listen(_onRemoteState);
    notifyListeners();
    return true;
  }

  void _onMembersChanged(List<String> memberUids) {
    if (!_isOnline || !_isHost) return;
    // En la sala de espera la lista de mesas se arma con los dispositivos
    // conectados (máximo 6 mesas).
    if (phase == LocalPhase.lobby) {
      final limited = memberUids.take(maxTeams).toList();
      teams = [
        for (var i = 0; i < limited.length; i++)
          TeamScore(
            name: 'Mesa ${i + 1}',
            color: teamColors[i % teamColors.length],
            uid: limited[i],
          ),
      ];
      teamCount = teams.length;
      _publishIfHost();
      notifyListeners();
    }
  }

  void _onAnswersChanged(Map<String, Map<String, dynamic>> answers) {
    if (!_isOnline || !_isHost) return;
    if (phase != LocalPhase.challenge || challenge == null || teams.isEmpty) {
      return;
    }
    final activeUid = currentTeam.uid;
    final entry = activeUid != null ? answers[activeUid] : null;
    if (entry == null) return;
    final ansRound = (entry['round'] as num?)?.toInt();
    final ansIndex = (entry['index'] as num?)?.toInt();
    if (ansRound != round || ansIndex == null) return;

    final sentAt = (entry['at'] as num?)?.toInt();
    if (sentAt != null) {
      final delta = DateTime.now().millisecondsSinceEpoch - sentAt;
      syncLatenciesMs.add(delta.clamp(0, 60000));
    }
    answer(ansIndex);
  }

  void _onRemoteState(Map<String, dynamic>? data) {
    if (!_isOnline || _isHost || data == null) return;

    final sentAt = (data['sentAt'] as num?)?.toInt();
    if (sentAt != null) {
      final delta = DateTime.now().millisecondsSinceEpoch - sentAt;
      syncLatenciesMs.add(delta.clamp(0, 60000));
    }

    final phaseName = data['phase'] as String?;
    phase = LocalPhase.values.firstWhere(
      (p) => p.name == phaseName,
      orElse: () => LocalPhase.lobby,
    );
    round = (data['round'] as num?)?.toInt() ?? 0;
    totalRounds = (data['totalRounds'] as num?)?.toInt() ?? 5;
    currentTeamIndex = (data['currentTeamIndex'] as num?)?.toInt() ?? 0;
    spinTrigger = (data['spinTrigger'] as num?)?.toInt() ?? 0;

    final catName = data['category'] as String?;
    category = catName == null
        ? null
        : MathCategory.values.firstWhere(
            (c) => c.name == catName,
            orElse: () => MathCategory.conteo,
          );

    final rawChallenge = data['challenge'];
    challenge = rawChallenge is Map
        ? MathChallenge.fromJson(rawChallenge)
        : null;

    lastAnswerIndex = (data['lastAnswerIndex'] as num?)?.toInt();
    lastCorrect = data['lastCorrect'] as bool?;

    final rawTeams = data['teams'] as List<dynamic>? ?? const [];
    teams = [
      for (var i = 0; i < rawTeams.length; i++)
        if (rawTeams[i] is Map)
          TeamScore(
            name: (rawTeams[i] as Map)['name'] as String? ?? 'Mesa ${i + 1}',
            color: teamColors[i % teamColors.length],
            uid: (rawTeams[i] as Map)['uid'] as String?,
            stars: ((rawTeams[i] as Map)['stars'] as num?)?.toInt() ?? 0,
            answered: ((rawTeams[i] as Map)['answered'] as num?)?.toInt() ?? 0,
          ),
    ];
    teamCount = teams.length;

    final myUid = _backend?.uid;
    final idx = myUid == null
        ? -1
        : teams.indexWhere((t) => t.uid == myUid);
    _myTeamIndex = idx >= 0 ? idx : null;

    notifyListeners();
  }

  Map<String, dynamic> _toStateMap() => {
    'phase': phase.name,
    'round': round,
    'totalRounds': totalRounds,
    'currentTeamIndex': currentTeamIndex,
    'spinTrigger': spinTrigger,
    if (category != null) 'category': category!.name,
    if (challenge != null) 'challenge': challenge!.toJson(),
    if (lastAnswerIndex != null) 'lastAnswerIndex': lastAnswerIndex,
    if (lastCorrect != null) 'lastCorrect': lastCorrect,
    'sentAt': DateTime.now().millisecondsSinceEpoch,
    'teams': [for (final t in teams) t.toJson()],
  };

  Future<void> _publishIfHost() async {
    if (_isOnline && _isHost && _roomCode != null && _backend != null) {
      await _backend!.publishState(_roomCode!, _toStateMap());
    }
  }

  void _cancelSubscriptions() {
    _membersSub?.cancel();
    _membersSub = null;
    _stateSub?.cancel();
    _stateSub = null;
    _answersSub?.cancel();
    _answersSub = null;
  }

  // ── Flujo de la partida ──

  /// Inicia la partida (botón de la docente en la sala de espera).
  void start() {
    if (!_isOnline && teams.length != teamCount) _buildTeams();
    if (teams.isEmpty) return;
    for (final t in teams) {
      t
        ..stars = 0
        ..answered = 0;
    }
    round = 1;
    currentTeamIndex = 0;
    _resetRound();
    phase = LocalPhase.spinning;
    _publishIfHost();
    notifyListeners();
  }

  void _resetRound() {
    category = null;
    challenge = null;
    lastAnswerIndex = null;
    lastCorrect = null;
  }

  /// Sortea la categoría que mostrará la ruleta. No cambia de fase: la
  /// ruleta anima hasta ella y luego llama a [onSpinFinished].
  int drawCategoryIndex() {
    final idx = _rng.nextInt(MathCategory.values.length);
    category = MathCategory.values[idx];
    spinTrigger++;
    if (_isOnline && _isHost) {
      _publishIfHost();
      notifyListeners();
    }
    return idx;
  }

  /// La ruleta terminó de girar: se genera el reto de la categoría.
  void onSpinFinished() {
    if (!isHost) return;
    final cat = category ?? MathCategory.values[drawCategoryIndex()];
    challenge = _generator.generate(cat);
    phase = LocalPhase.challenge;
    _publishIfHost();
    notifyListeners();
  }

  /// Envía o evalúa una respuesta según el rol del dispositivo:
  /// - Si es la docente / modo 1 dispositivo: califica de inmediato.
  /// - Si es una mesa conectada: envía su respuesta al anfitrión.
  Future<void> submitAnswer(int index) async {
    if (_isOnline && !_isHost) {
      if (!isMyTurn || _roomCode == null || _backend == null) return;
      await _backend!.sendAnswer(_roomCode!, round: round, index: index);
      return;
    }
    answer(index);
  }

  /// La mesa en turno eligió la opción [index].
  bool answer(int index) {
    final c = challenge!;
    final correct = c.isCorrect(index);
    lastAnswerIndex = index;
    lastCorrect = correct;
    currentTeam.answered++;
    if (correct) currentTeam.stars++;
    phase = LocalPhase.feedback;
    _publishIfHost();
    notifyListeners();
    return correct;
  }

  /// Avanza tras la retroalimentación. Devuelve `true` si hay otra ronda,
  /// `false` si la partida terminó (fase resultados).
  bool next() {
    if (isLastRound) {
      phase = LocalPhase.results;
      _publishIfHost();
      notifyListeners();
      return false;
    }
    round++;
    currentTeamIndex = (currentTeamIndex + 1) % teams.length;
    _resetRound();
    phase = LocalPhase.spinning;
    _publishIfHost();
    notifyListeners();
    return true;
  }

  /// Vuelve a jugar con la misma configuración.
  void restart() {
    start();
  }

  /// Regresa al menú principal descartando la partida.
  void reset() {
    final code = _roomCode;
    final backend = _backend;
    final wasOnline = _isOnline;
    final wasHost = _isHost;
    _cancelSubscriptions();
    _isOnline = false;
    _isHost = true;
    _roomCode = null;
    _myTeamIndex = null;
    spinTrigger = 0;
    teams = [];
    round = 0;
    _resetRound();
    phase = LocalPhase.lobby;
    notifyListeners();
    if (wasOnline && code != null && backend != null) {
      if (wasHost) {
        backend.closeRoom(code).catchError((_) {});
      } else {
        backend.leaveRoom(code).catchError((_) {});
      }
    }
  }
}
