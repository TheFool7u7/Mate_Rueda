import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/challenge/presentation/screens/math_challenge_screen.dart';
import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/local_game/presentation/local_routes.dart';
import 'package:wordwonderslink/features/local_game/presentation/widgets/mate_widgets.dart';
import 'package:wordwonderslink/shared/data/tts_service.dart';

/// Pantalla 6 — Reto: envuelve [MathChallengeScreen] con los datos de la
/// partida local y una etiqueta con la mesa que está en turno.
class LocalChallengeScreen extends StatelessWidget {
  const LocalChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<LocalGameController>();
    final challenge = game.challenge;
    if (challenge == null) {
      // Sin partida → menú. Si hay partida, solo se está saliendo de la
      // pantalla (la ronda ya avanzó): no redirigir.
      if (game.teams.isEmpty) _goMenuLater(context);
      return const SizedBox.shrink();
    }
    final team = game.currentTeam;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
      children: [
        MathChallengeScreen(
          challenge: challenge,
          progress: game.progress,
          autoSpeak: true,
          onAnswered: (index, correct) async {
            final controller = context.read<LocalGameController>();
            final router = GoRouter.of(context);
            controller.answer(index);
            // Breve pausa para ver la opción elegida antes de la
            // retroalimentación.
            await Future.delayed(const Duration(milliseconds: 700));
            router.go(LocalRoutes.feedback);
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(6, 6, 20, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: MateColors.moradoVivo, width: 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TeamAvatar(
                      color: team.color,
                      label: '${game.currentTeamIndex + 1}',
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Turno de ${team.name}',
                      style: mateFredoka(22, color: MateColors.moradoOscuro),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

void _goMenuLater(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) context.go(LocalRoutes.menu);
  });
}

/// Texto legible de una opción para mostrar la respuesta correcta.
String optionText(ChallengeOption o) {
  switch (o.label) {
    case '◀':
      return 'Izquierda';
    case '▶':
      return 'Derecha';
    case '=':
      return 'Son iguales';
    default:
      return o.label;
  }
}

/// Pantalla 7 — Retroalimentación inmediata (acierto / error) con
/// mensajes siempre positivos y recompensa de estrella.
class LocalFeedbackScreen extends StatefulWidget {
  const LocalFeedbackScreen({super.key});

  @override
  State<LocalFeedbackScreen> createState() => _LocalFeedbackScreenState();
}

class _LocalFeedbackScreenState extends State<LocalFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    // El sonido de acierto/error ya sonó al tocar la opción; aquí se lee el
    // mensaje en voz alta (accesibilidad, RNF02).
    final game = context.read<LocalGameController>();
    final challenge = game.challenge;
    if (challenge != null && game.lastCorrect != null) {
      final text = game.lastCorrect == true
          ? '¡Muy bien!'
          : '¡Casi! Intentemos otra. La respuesta era '
                '${optionText(challenge.options[challenge.correctIndex])}';
      TtsService.instance.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<LocalGameController>();
    final challenge = game.challenge;
    if (challenge == null || game.lastCorrect == null) {
      // Al pulsar "Siguiente" el controlador limpia la ronda antes de que
      // termine la navegación: solo volver al menú si no hay partida.
      if (game.teams.isEmpty) _goMenuLater(context);
      return const SizedBox.shrink();
    }
    final correct = game.lastCorrect!;
    final team = game.currentTeam;
    final answer = optionText(challenge.options[challenge.correctIndex]);

    return MateBackground(
      showNumi: !correct,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            MateOutlinedText(
              correct ? '¡Muy bien!' : '¡Casi! Intentemos otra',
              size: 46,
              color: correct ? MateColors.turquesaOscuro : MateColors.moradoVivo,
            ),
            const SizedBox(height: 20),
            if (correct)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Image.asset(
                  'assets/images/materueda/estrella.png',
                  height: 200,
                ),
              )
            else
              Image.asset('assets/images/materueda/numi.png', height: 200),
            const SizedBox(height: 16),
            MateCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TeamAvatar(
                        color: team.color,
                        label: '${game.currentTeamIndex + 1}',
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${team.name}: ${team.stars} ${team.stars == 1 ? 'estrella' : 'estrellas'}',
                            style: mateFredoka(26, color: MateColors.moradoOscuro),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!correct) ...[
                    const SizedBox(height: 12),
                    Text(
                      'La respuesta era',
                      style: mateFredoka(20, color: MateColors.moradoRueda, weight: FontWeight.w500),
                    ),
                    Text(
                      answer,
                      textAlign: TextAlign.center,
                      style: mateFredoka(40, color: MateColors.turquesaOscuro),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            MateButton.turquesa(
              label: game.isLastRound ? 'Ver resultados' : 'Siguiente',
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                final more = game.next();
                context.go(more ? LocalRoutes.spin : LocalRoutes.results);
              },
            ),
          ],
        ),
      ),
    );
  }
}
