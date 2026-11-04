import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/local_game/presentation/local_routes.dart';
import 'package:wordwonderslink/features/local_game/presentation/widgets/mate_widgets.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

// ═══════════════════════════════════════════════════════════
// 1. SPLASH
// ═══════════════════════════════════════════════════════════

/// Pantalla 1 — Inicio: logotipo con animación de aparición y paso
/// automático al menú (2–3 s).
class LocalSplashScreen extends StatefulWidget {
  const LocalSplashScreen({super.key, this.duration = const Duration(seconds: 3)});

  final Duration duration;

  @override
  State<LocalSplashScreen> createState() => _LocalSplashScreenState();
}

class _LocalSplashScreenState extends State<LocalSplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) context.go(LocalRoutes.menu);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MateBackground(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Image.asset('assets/images/materueda/logotipo.png'),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 2. MENÚ PRINCIPAL
// ═══════════════════════════════════════════════════════════

/// Pantalla 2 — Menú principal: Numi saluda a la docente.
class LocalMenuScreen extends StatefulWidget {
  const LocalMenuScreen({super.key});

  @override
  State<LocalMenuScreen> createState() => _LocalMenuScreenState();
}

class _LocalMenuScreenState extends State<LocalMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3');
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MateBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: Image.asset('assets/images/materueda/logotipo.png'),
            ),
            const SizedBox(height: 12),
            const MateOutlinedText('¡Hola, profe! ¿Listos?', size: 40),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -10 * Curves.easeInOut.transform(_float.value)),
                child: child,
              ),
              child: Image.asset('assets/images/materueda/numi.png', height: 280),
            ),
            const SizedBox(height: 24),
            MateButton(
              label: 'Jugar',
              icon: Icons.play_arrow_rounded,
              onTap: () => context.go(LocalRoutes.setup),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3. CREAR PARTIDA (configuración de la docente)
// ═══════════════════════════════════════════════════════════

/// Pantalla 3 — Crear partida: mesas, rondas y nivel.
///
/// En modo un-dispositivo no hace falta código de sala; cuando exista el
/// modo multidispositivo aquí se elegirá "un dispositivo / varios".
class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  late int _teams;
  late int _rounds;
  late bool _extended;

  @override
  void initState() {
    super.initState();
    final c = context.read<LocalGameController>();
    _teams = c.teamCount;
    _rounds = c.totalRounds;
    _extended = c.settings.countMax > ChallengeSettings.basico.countMax;
  }

  void _create() {
    context.read<LocalGameController>().configure(
      teamCount: _teams,
      totalRounds: _rounds,
      settings: _extended
          ? ChallengeSettings.ampliado
          : ChallengeSettings.basico,
    );
    context.go(LocalRoutes.lobby);
  }

  @override
  Widget build(BuildContext context) {
    return MateBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const MateOutlinedText('Crear partida', size: 44),
            const SizedBox(height: 16),
            MateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('¿Cuántas mesas?'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _roundIconButton(
                        Icons.remove_rounded,
                        _teams > LocalGameController.minTeams
                            ? () => setState(() => _teams--)
                            : null,
                        'Menos mesas',
                      ),
                      SizedBox(
                        width: 90,
                        child: Center(
                          child: Text(
                            '$_teams',
                            style: mateFredoka(64, color: MateColors.moradoVivo),
                          ),
                        ),
                      ),
                      _roundIconButton(
                        Icons.add_rounded,
                        _teams < LocalGameController.maxTeams
                            ? () => setState(() => _teams++)
                            : null,
                        'Más mesas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('¿Cuántas rondas?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final r in LocalGameController.roundOptions)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _chip('$r', _rounds == r, () => setState(() => _rounds = r)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('Nivel'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _chip('Hasta 10', !_extended, () => setState(() => _extended = false)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _chip('Hasta 20', _extended, () => setState(() => _extended = true)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            MateButton(label: 'Crear sala', icon: Icons.groups_rounded, onTap: _create),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(LocalRoutes.menu),
              child: Text('Volver', style: mateFredoka(22, color: MateColors.moradoOscuro)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: mateFredoka(26, color: MateColors.moradoOscuro));

  Widget _roundIconButton(IconData icon, VoidCallback? onTap, String semantic) {
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: MateColors.turquesaGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: MateColors.turquesaOscuro, offset: Offset(0, 5))],
            ),
            child: Icon(icon, color: Colors.white, size: 44),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? null : Colors.white,
            gradient: selected ? MateColors.bannerGradient : null,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: MateColors.moradoVivo, width: 4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: mateFredoka(28, color: selected ? Colors.white : MateColors.moradoVivo),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 4. SALA DE ESPERA
// ═══════════════════════════════════════════════════════════

/// Pantalla 4 — Sala de espera: avatares de color por mesa y botón
/// "Iniciar partida" (control de la docente).
class LocalLobbyScreen extends StatefulWidget {
  const LocalLobbyScreen({super.key});

  @override
  State<LocalLobbyScreen> createState() => _LocalLobbyScreenState();
}

class _LocalLobbyScreenState extends State<LocalLobbyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<LocalGameController>();
    final teams = game.teams;
    return MateBackground(
      showNumi: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const MateOutlinedText('Sala de espera', size: 44),
            const SizedBox(height: 8),
            MateCard(
              child: Column(
                children: [
                  Text(
                    '${teams.length} ${teams.length == 1 ? 'mesa lista' : 'mesas listas'} · ${game.totalRounds} rondas',
                    style: mateFredoka(24, color: MateColors.moradoOscuro),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      for (var i = 0; i < teams.length; i++)
                        _appear(
                          i,
                          teams.length,
                          Column(
                            children: [
                              TeamAvatar(color: teams[i].color, label: '${i + 1}'),
                              const SizedBox(height: 4),
                              Text(
                                teams[i].name,
                                style: mateFredoka(20, color: MateColors.moradoOscuro),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            MateButton.turquesa(
              label: 'Iniciar partida',
              icon: Icons.rocket_launch_rounded,
              onTap: teams.isEmpty
                  ? null
                  : () {
                      AudioManagerService().playSfx('lets_go.wav');
                      game.start();
                      context.go(LocalRoutes.spin);
                    },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(LocalRoutes.setup),
              child: Text('Cambiar configuración', style: mateFredoka(20, color: MateColors.moradoOscuro)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appear(int i, int n, Widget child) {
    final start = (i / n) * 0.6;
    final anim = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.elasticOut),
    );
    return ScaleTransition(scale: anim, child: child);
  }
}
