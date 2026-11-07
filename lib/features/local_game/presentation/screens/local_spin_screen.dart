import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/local_game/presentation/local_routes.dart';
import 'package:wordwonderslink/features/local_game/presentation/widgets/mate_widgets.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Colores de cada sector de la ruleta (uno por categoría).
const List<Color> _sectorColors = [
  MateColors.coralEnergia,
  MateColors.turquesaCalma,
  MateColors.amarilloEstrella,
  MateColors.moradoRueda,
  MateColors.cielo,
];

/// Texto corto de cada categoría para la ruleta.
const Map<MathCategory, String> _shortNames = {
  MathCategory.conteo: 'Conteo',
  MathCategory.comparacion: 'Comparar',
  MathCategory.sumas: 'Sumas',
  MathCategory.restas: 'Restas',
  MathCategory.figuras: 'Figuras',
};

/// Pantalla 5 — Ruleta: gira y se detiene en una de las 5 categorías.
class LocalSpinScreen extends StatefulWidget {
  const LocalSpinScreen({super.key});

  @override
  State<LocalSpinScreen> createState() => _LocalSpinScreenState();
}

class _LocalSpinScreenState extends State<LocalSpinScreen>
    with SingleTickerProviderStateMixin {
  static const int _sectors = 5;

  /// Volumen relativo (0..1) de los sonidos de la ruleta.
  static const double _spinSfxVolume = 0.25;
  static const double _stopSfxVolume = 0.5;

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  double _from = 0;
  double _to = 0;
  bool _spinning = false;
  MathCategory? _landed;
  int _lastSeenTrigger = 0;

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('juego.mp3');
    _lastSeenTrigger = context.read<LocalGameController>().spinTrigger;
  }

  @override
  void dispose() {
    AudioManagerService().stopLoopSfx();
    _spin.dispose();
    super.dispose();
  }

  double get _angle {
    final t = Curves.easeOutCubic.transform(_spin.value);
    return _from + (_to - _from) * t;
  }

  Future<void> _start() async {
    final game = context.read<LocalGameController>();
    if (!game.isHost || _spinning || _landed != null) return;
    final idx = game.drawCategoryIndex();
    _lastSeenTrigger = game.spinTrigger;
    await _animateToCategory(idx, finishAsHost: true);
  }

  Future<void> _animateToCategory(
    int idx, {
    required bool finishAsHost,
  }) async {
    const sector = 2 * math.pi / _sectors;
    // El centro del sector debe quedar bajo la flecha (arriba).
    final target = -(idx + 0.5) * sector;
    final turns = 5 + math.Random().nextInt(2);
    _from = _angle % (2 * math.pi);
    _to = turns * 2 * math.pi + target;
    setState(() => _spinning = true);

    // El "tic-tic" de la ruleta es muy fuerte: se atenúa al 25 %, y el
    // sonido de parada al 50 %.
    AudioManagerService().startLoopSfx(
      'tic_tic_tic ruleta.wav',
      volumeFactor: _spinSfxVolume,
    );
    await _spin.forward(from: 0);
    AudioManagerService().stopLoopSfx();
    AudioManagerService().playSfx(
      'termina_de_girar.wav',
      volumeFactor: _stopSfxVolume,
    );
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _landed = MathCategory.values[idx];
    });

    if (!finishAsHost) return;
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final game = context.read<LocalGameController>();
    game.onSpinFinished();
    if (!game.isOnline) context.go(LocalRoutes.challenge);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<LocalGameController>();
    if (game.teams.isEmpty) {
      // Se llegó sin partida (p. ej. recarga): volver al menú.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(LocalRoutes.menu);
      });
      return const SizedBox.shrink();
    }

    // En dispositivos cliente, cuando la docente gira la ruleta se dispara
    // la animación local hacia la misma categoría.
    if (!game.isHost &&
        game.spinTrigger != _lastSeenTrigger &&
        game.category != null &&
        !_spinning) {
      _lastSeenTrigger = game.spinTrigger;
      final idx = game.category!.index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateToCategory(idx, finishAsHost: false);
      });
    }

    final team = game.currentTeam;

    return MateBackground(
      showNumi: true,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Ronda ${game.round} de ${game.totalRounds}',
            style: mateFredoka(26, color: MateColors.moradoOscuro),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamAvatar(
                color: team.color,
                label: '${game.currentTeamIndex + 1}',
                size: 56,
              ),
              const SizedBox(width: 12),
              MateOutlinedText('Turno de ${team.name}', size: 34),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = math.min(box.maxWidth, box.maxHeight) * 0.92;
                  return GestureDetector(
                    onTap: game.isHost ? _start : null,
                    child: Semantics(
                      button: true,
                      label: 'Girar la ruleta',
                      child: SizedBox(
                        width: size,
                        height: size + 40,
                        child: AnimatedBuilder(
                          animation: _spin,
                          builder: (_, __) => CustomPaint(
                            painter: _WheelPainter(angle: _angle),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 110,
            child: Center(
              child: _landed != null
                  ? MateOutlinedText(_landed!.label, size: 40)
                  : game.isHost
                  ? MateButton(
                      label: _spinning ? 'Girando...' : '¡Girar!',
                      icon: Icons.refresh_rounded,
                      onTap: _spinning ? null : _start,
                    )
                  : MateOutlinedText(
                      _spinning ? 'Girando...' : 'La profe gira la ruleta',
                      size: 30,
                      color: MateColors.moradoOscuro,
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.angle});

  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 5;
    const sector = 2 * math.pi / n;
    final radius = math.min(size.width, size.height - 40) / 2;
    final center = Offset(size.width / 2, 40 + radius);

    // Sombra.
    canvas.drawCircle(
      center + const Offset(0, 8),
      radius,
      Paint()..color = MateColors.moradoOscuro.withValues(alpha: 0.35),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * sector;
      canvas.drawArc(
        rect,
        start,
        sector,
        true,
        Paint()..color = _sectorColors[i],
      );
      canvas.drawArc(
        rect,
        start,
        sector,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );

      // Texto de la categoría a lo largo del radio.
      final mid = start + sector / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: _shortNames[MathCategory.values[i]],
          style: mateFredoka(
            radius * 0.15,
            color: i == 2 ? MateColors.moradoOscuro : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.rotate(mid);
      canvas.translate(radius * 0.58, 0);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Aro exterior.
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = MateColors.moradoVivo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    canvas.restore();

    // Centro.
    canvas.drawCircle(center, radius * 0.16, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius * 0.16,
      Paint()
        ..color = MateColors.moradoVivo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Flecha fija arriba.
    final arrow = Path()
      ..moveTo(center.dx - 24, 6)
      ..lineTo(center.dx + 24, 6)
      ..lineTo(center.dx, 56)
      ..close();
    canvas.drawPath(arrow, Paint()..color = MateColors.amarilloEstrella);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = MateColors.moradoVivo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.angle != angle;
}
