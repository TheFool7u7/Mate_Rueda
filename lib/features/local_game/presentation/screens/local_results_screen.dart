import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/local_game/presentation/local_routes.dart';
import 'package:wordwonderslink/features/local_game/presentation/widgets/mate_widgets.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla 8 — Resultados: marcador grupal, podio por mesa y total de
/// estrellas del grupo (más el indicador de sincronización RNF05 en modo
/// varios dispositivos).
class LocalResultsScreen extends StatefulWidget {
  const LocalResultsScreen({super.key});

  @override
  State<LocalResultsScreen> createState() => _LocalResultsScreenState();
}

class _LocalResultsScreenState extends State<LocalResultsScreen> {
  @override
  void initState() {
    super.initState();
    final audio = AudioManagerService();
    audio.stopTrack();
    audio.playSfx('win.mp3');
  }

  static const _medals = [
    'assets/icons/medalla_oro.svg',
    'assets/icons/medalla_plata.svg',
    'assets/icons/medalla_bronce.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<LocalGameController>();
    if (game.teams.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(LocalRoutes.menu);
      });
      return const SizedBox.shrink();
    }
    final ranking = game.ranking;

    return MateBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const MateOutlinedText('¡Buen trabajo, equipo!', size: 42),
            const SizedBox(height: 12),
            SvgPicture.asset('assets/icons/trofeo.svg', height: 110),
            const SizedBox(height: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: game.totalStars),
              duration: const Duration(milliseconds: 1400),
              builder: (_, v, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/materueda/estrella.png',
                    height: 60,
                  ),
                  const SizedBox(width: 10),
                  MateOutlinedText(
                    '$v ${v == 1 ? 'estrella' : 'estrellas'}',
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MateCard(
              padding: 16,
              child: Column(
                children: [
                  for (var i = 0; i < ranking.length; i++) ...[
                    if (i > 0) const Divider(height: 16),
                    _row(i, ranking[i]),
                  ],
                ],
              ),
            ),
            if (game.isOnline && game.syncLatenciesMs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MateColors.turquesaCalma, width: 2),
                ),
                child: Text(
                  'Sincronización (RNF05): '
                  '${(game.rnf05ComplianceRatio * 100).round()}% ≤ 3 s · '
                  'prom. ${game.averageLatencyMs} ms',
                  style: mateFredoka(
                    16,
                    color: MateColors.moradoOscuro,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (game.isHost) ...[
              MateButton.turquesa(
                label: 'Jugar otra vez',
                icon: Icons.replay_rounded,
                onTap: () {
                  game.restart();
                  if (!game.isOnline) context.go(LocalRoutes.spin);
                },
              ),
              const SizedBox(height: 8),
            ],
            MateButton.amarillo(
              label: 'Volver al menú',
              icon: Icons.home_rounded,
              height: 64,
              fontSize: 26,
              onTap: () {
                game.reset();
                context.go(LocalRoutes.menu);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(int i, TeamScore t) {
    final medal = i < _medals.length
        ? _medals[i]
        : 'assets/icons/medalla_sin_rango.svg';
    return Row(
      children: [
        SvgPicture.asset(medal, width: 52, height: 52),
        const SizedBox(width: 12),
        TeamAvatar(
          color: t.color,
          label: t.name.replaceAll('Mesa ', ''),
          size: 52,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t.name,
            style: mateFredoka(26, color: MateColors.moradoOscuro),
          ),
        ),
        Image.asset('assets/images/materueda/estrella.png', height: 34),
        const SizedBox(width: 6),
        Text('${t.stars}', style: mateFredoka(32, color: MateColors.moradoVivo)),
      ],
    );
  }
}
