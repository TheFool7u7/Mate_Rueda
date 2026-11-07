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
  const LocalSplashScreen({
    super.key,
    this.duration = const Duration(seconds: 3),
  });

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

/// Pantalla 2 — Menú principal: Numi saluda a la docente y ofrece crear
/// una partida ("Jugar") o unirse a una sala existente ("Unirse a sala").
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
              height: 120,
              child: Image.asset('assets/images/materueda/logotipo.png'),
            ),
            const SizedBox(height: 12),
            const MateOutlinedText('¡Hola, profe! ¿Listos?', size: 40),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  0,
                  -10 * Curves.easeInOut.transform(_float.value),
                ),
                child: child,
              ),
              child: Image.asset(
                'assets/images/materueda/numi.png',
                height: 240,
              ),
            ),
            const SizedBox(height: 20),
            MateButton(
              label: 'Jugar',
              icon: Icons.play_arrow_rounded,
              onTap: () => context.go(LocalRoutes.setup),
            ),
            const SizedBox(height: 12),
            MateButton.turquesa(
              label: 'Unirse a sala',
              icon: Icons.meeting_room_rounded,
              height: 68,
              fontSize: 26,
              onTap: () => context.go(LocalRoutes.join),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3A. CREAR PARTIDA (configuración de la docente)
// ═══════════════════════════════════════════════════════════

/// Pantalla 3 — Crear partida: permite elegir entre jugar en un solo
/// dispositivo (por turnos) o en varios dispositivos (con código de sala),
/// además de mesas, rondas y nivel.
class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  late int _teams;
  late int _rounds;
  late bool _extended;
  bool _multiDevice = false;
  bool _hostPlays = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = context.read<LocalGameController>();
    _teams = c.teamCount.clamp(
      LocalGameController.minTeams,
      LocalGameController.maxTeams,
    );
    _rounds = c.totalRounds;
    _extended = c.settings.countMax > ChallengeSettings.basico.countMax;
    _hostPlays = c.hostPlays;
  }

  Future<void> _create() async {
    if (_creating) return;
    final game = context.read<LocalGameController>();
    final chosenSettings = _extended
        ? ChallengeSettings.ampliado
        : ChallengeSettings.basico;

    if (!_multiDevice) {
      game.configure(
        teamCount: _teams,
        totalRounds: _rounds,
        settings: chosenSettings,
      );
      context.go(LocalRoutes.lobby);
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await game.createOnlineRoom(
        totalRounds: _rounds,
        settings: chosenSettings,
        hostPlays: _hostPlays,
      );
      if (mounted) context.go(LocalRoutes.lobby);
    } catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _error = 'No se pudo crear la sala en línea. Revisa la conexión.';
        });
      }
    }
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
                  _label('¿Cómo jugarán?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _chip(
                            '1 dispositivo',
                            !_multiDevice,
                            () => setState(() => _multiDevice = false),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _chip(
                            'Varios',
                            _multiDevice,
                            () => setState(() => _multiDevice = true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!_multiDevice) ...[
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
                              style: mateFredoka(
                                64,
                                color: MateColors.moradoVivo,
                              ),
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
                  ] else ...[
                    _label('Este dispositivo'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _chip(
                              'Juega (Mesa 1)',
                              _hostPlays,
                              () => setState(() => _hostPlays = true),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _chip(
                              'Solo dirige',
                              !_hostPlays,
                              () => setState(() => _hostPlays = false),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _hostPlays
                            ? 'Este dispositivo será Mesa 1 y los demás se unirán con código.'
                            : 'Este dispositivo solo dirige la partida; las mesas se unen con código.',
                        style: mateFredoka(
                          19,
                          color: MateColors.moradoRueda,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _label('¿Cuántas rondas?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final r in LocalGameController.roundOptions)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _chip(
                              '$r',
                              _rounds == r,
                              () => setState(() => _rounds = r),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label('Nivel'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _chip(
                            'Hasta 10',
                            !_extended,
                            () => setState(() => _extended = false),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _chip(
                            'Hasta 20',
                            _extended,
                            () => setState(() => _extended = true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: mateFredoka(20, color: MateColors.coralEnergia),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            MateButton(
              label: _creating ? 'Creando...' : 'Crear sala',
              icon: Icons.groups_rounded,
              onTap: _creating ? null : _create,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(LocalRoutes.menu),
              child: Text(
                'Volver',
                style: mateFredoka(22, color: MateColors.moradoOscuro),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: mateFredoka(26, color: MateColors.moradoOscuro));

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
              boxShadow: const [
                BoxShadow(
                  color: MateColors.turquesaOscuro,
                  offset: Offset(0, 5),
                ),
              ],
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
              style: mateFredoka(
                26,
                color: selected ? Colors.white : MateColors.moradoVivo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3B. UNIRSE A SALA (mesas en otros dispositivos)
// ═══════════════════════════════════════════════════════════

/// Pantalla 3B — Unirse a sala: una mesa escribe el código de 5 caracteres
/// proyectado por la docente.
class LocalJoinScreen extends StatefulWidget {
  const LocalJoinScreen({super.key});

  @override
  State<LocalJoinScreen> createState() => _LocalJoinScreenState();
}

class _LocalJoinScreenState extends State<LocalJoinScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _joining) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final ok = await context.read<LocalGameController>().joinOnlineRoom(code);
      if (!mounted) return;
      if (ok) {
        AudioManagerService().playSfx('positiva.wav');
        context.go(LocalRoutes.lobby);
      } else {
        setState(() {
          _joining = false;
          _error = 'No encontramos ese código. Revisa la pantalla.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'No se pudo conectar. Revisa internet.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MateBackground(
      showNumi: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const MateOutlinedText('Unirse a sala', size: 44),
            const SizedBox(height: 16),
            MateCard(
              child: Column(
                children: [
                  Text(
                    'Escribe el código de la pizarra',
                    style: mateFredoka(24, color: MateColors.moradoOscuro),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: mateFredoka(44, color: MateColors.moradoVivo),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'AB3K9',
                      hintStyle: mateFredoka(
                        40,
                        color: MateColors.pista,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: MateColors.moradoVivo,
                          width: 4,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: MateColors.moradoVivo,
                          width: 4,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _join(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: mateFredoka(20, color: MateColors.coralEnergia),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            MateButton.turquesa(
              label: _joining ? 'Entrando...' : 'Entrar',
              icon: Icons.login_rounded,
              onTap: _joining ? null : _join,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(LocalRoutes.menu),
              child: Text(
                'Volver',
                style: mateFredoka(22, color: MateColors.moradoOscuro),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 4. SALA DE ESPERA
// ═══════════════════════════════════════════════════════════

/// Pantalla 4 — Sala de espera: código de sala (si es multidispositivo),
/// avatares de color por mesa y botón "Iniciar partida" (control docente).
class LocalLobbyScreen extends StatefulWidget {
  const LocalLobbyScreen({super.key});

  @override
  State<LocalLobbyScreen> createState() => _LocalLobbyScreenState();
}

class _LocalLobbyScreenState extends State<LocalLobbyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

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
            if (game.isOnline && game.roomCode != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: MateColors.bannerGradient,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Column(
                  children: [
                    Text(
                      'Código de sala',
                      style: mateFredoka(
                        20,
                        color: MateColors.amarilloEstrella,
                      ),
                    ),
                    Text(
                      game.roomCode!,
                      style: mateFredoka(52, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (game.isOnline && game.myTeamIndex != null) ...[
              MateOutlinedText(
                '¡Eres Mesa ${game.myTeamIndex! + 1}!',
                size: 32,
                color: MateColors.turquesaOscuro,
              ),
              const SizedBox(height: 8),
            ],
            if (game.isOnline && game.isHost) ...[
              TextButton.icon(
                onPressed: () => game.setHostPlays(!game.hostPlays),
                icon: Icon(
                  game.hostPlays
                      ? Icons.tablet_android_rounded
                      : Icons.cast_for_education_rounded,
                  color: MateColors.moradoVivo,
                ),
                label: Text(
                  game.hostPlays
                      ? 'Este dispositivo juega como Mesa 1 (toca para solo dirigir)'
                      : 'Solo dirigiendo sin jugar (toca para ser Mesa 1)',
                  textAlign: TextAlign.center,
                  style: mateFredoka(18, color: MateColors.moradoVivo),
                ),
              ),
              const SizedBox(height: 4),
            ],
            MateCard(
              child: Column(
                children: [
                  Text(
                    teams.isEmpty
                        ? 'Esperando que se unan las mesas...'
                        : '${teams.length} ${teams.length == 1 ? 'mesa lista' : 'mesas listas'} · ${game.totalRounds} rondas',
                    textAlign: TextAlign.center,
                    style: mateFredoka(24, color: MateColors.moradoOscuro),
                  ),
                  const SizedBox(height: 16),
                  if (teams.isNotEmpty)
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
                                TeamAvatar(
                                  color: teams[i].color,
                                  label: '${i + 1}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  teams[i].name,
                                  style: mateFredoka(
                                    20,
                                    color: MateColors.moradoOscuro,
                                  ),
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
            if (game.isHost)
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
              )
            else
              MateOutlinedText(
                'Esperando a la profe...',
                size: 30,
                color: MateColors.moradoOscuro,
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (game.isOnline) {
                  game.reset();
                  context.go(LocalRoutes.menu);
                } else {
                  context.go(LocalRoutes.setup);
                }
              },
              child: Text(
                game.isOnline ? 'Salir de la sala' : 'Cambiar configuración',
                style: mateFredoka(20, color: MateColors.moradoOscuro),
              ),
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
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.elasticOut,
      ),
    );
    return ScaleTransition(scale: anim, child: child);
  }
}
