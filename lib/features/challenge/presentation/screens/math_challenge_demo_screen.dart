import 'package:flutter/material.dart';

import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/challenge/presentation/screens/math_challenge_screen.dart';

/// Modo demo local (sin Firebase) del Reto matemático.
///
/// Empieza con el reto exacto del mockup (5 manzanas) y luego genera retos
/// aleatorios de las 5 categorías. Sirve para revisar la vista mientras se
/// adapta el flujo multijugador (Ruleta → Reto → Retroalimentación).
class MathChallengeDemoScreen extends StatefulWidget {
  const MathChallengeDemoScreen({super.key, this.totalRounds = 10});

  final int totalRounds;

  @override
  State<MathChallengeDemoScreen> createState() =>
      _MathChallengeDemoScreenState();
}

class _MathChallengeDemoScreenState extends State<MathChallengeDemoScreen> {
  final _generator = MathChallengeGenerator();
  MathChallenge _challenge = MathChallengeGenerator.mockup;
  int _round = 5; // Igual que el mockup: barra a la mitad.
  int? _initialSelected = 1; // Inicia con '5' seleccionado como en la imagen 10

  void _onAnswered(int index, bool correct) {
    _initialSelected = null;
    // TODO(materueda): navegar a la pantalla 7 — Retroalimentación.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _round = _round >= widget.totalRounds ? 1 : _round + 1;
        _challenge = _generator.random();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MathChallengeScreen(
      challenge: _challenge,
      progress: _round / widget.totalRounds,
      initialSelected: _initialSelected,
      onAnswered: _onAnswered,
    );
  }
}
