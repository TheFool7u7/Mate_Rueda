import 'dart:math';

import 'package:flutter/material.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';

/// Fase actual de una partida local.
enum LocalPhase { lobby, spinning, challenge, feedback, results }

/// Mesa / grupo que juega y sus estrellas acumuladas.
class TeamScore {
  TeamScore({required this.name, required this.color});

  final String name;
  final Color color;
  int stars = 0;
  int answered = 0;
}

/// Controla una partida de MateRueda en un solo dispositivo (modo demo,
/// sin Firebase): mesas por turnos, ruleta, reto, retroalimentación y
/// marcador.
///
/// Cuando se implemente el modo multidispositivo, esta clase será la
/// implementación local de una interfaz común de sesión de juego.
class LocalGameController extends ChangeNotifier {
  LocalGameController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

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

  TeamScore get currentTeam => teams[currentTeamIndex];

  /// Avance 0..1 para la barra amarilla del reto.
  double get progress => totalRounds == 0 ? 0 : round / totalRounds;

  bool get isLastRound => round >= totalRounds;

  int get totalStars => teams.fold(0, (sum, t) => sum + t.stars);

  /// Mesas ordenadas por estrellas (de mayor a menor) para el podio.
  List<TeamScore> get ranking =>
      List.of(teams)..sort((a, b) => b.stars.compareTo(a.stars));

  // ── Configuración previa a la partida ──
  void configure({
    int? teamCount,
    int? totalRounds,
    ChallengeSettings? settings,
  }) {
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

  // ── Flujo de la partida ──

  /// Inicia la partida (botón de la docente en la sala de espera).
  void start() {
    if (teams.length != teamCount) _buildTeams();
    for (final t in teams) {
      t
        ..stars = 0
        ..answered = 0;
    }
    round = 1;
    currentTeamIndex = 0;
    _resetRound();
    phase = LocalPhase.spinning;
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
    return idx;
  }

  /// La ruleta terminó de girar: se genera el reto de la categoría.
  void onSpinFinished() {
    final cat = category ?? MathCategory.values[drawCategoryIndex()];
    challenge = _generator.generate(cat);
    phase = LocalPhase.challenge;
    notifyListeners();
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
    notifyListeners();
    return correct;
  }

  /// Avanza tras la retroalimentación. Devuelve `true` si hay otra ronda,
  /// `false` si la partida terminó (fase resultados).
  bool next() {
    if (isLastRound) {
      phase = LocalPhase.results;
      notifyListeners();
      return false;
    }
    round++;
    currentTeamIndex = (currentTeamIndex + 1) % teams.length;
    _resetRound();
    phase = LocalPhase.spinning;
    notifyListeners();
    return true;
  }

  /// Vuelve a jugar con la misma configuración.
  void restart() {
    start();
  }

  /// Regresa al menú principal descartando la partida.
  void reset() {
    teams = [];
    round = 0;
    _resetRound();
    phase = LocalPhase.lobby;
    notifyListeners();
  }
}
