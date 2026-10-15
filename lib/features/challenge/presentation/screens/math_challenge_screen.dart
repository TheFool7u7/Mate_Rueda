import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/challenge/presentation/widgets/challenge_illustrations.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla 6 — Reto matemático (mockup `10_reto_matematico.png`).
///
/// Es un widget "tonto": recibe el [challenge] y avisa con [onAnswered]
/// cuando el estudiante toca una opción. Así se puede usar tanto en el
/// modo demo local ([MathChallengeDemoScreen]) como, más adelante,
/// conectado al flujo multijugador de Firebase.
class MathChallengeScreen extends StatefulWidget {
  const MathChallengeScreen({
    super.key,
    required this.challenge,
    required this.onAnswered,
    this.progress = 0.5,
    this.enabled = true,
    this.initialSelected,
  });

  final MathChallenge challenge;

  /// Opción seleccionada inicialmente (p. ej. índice 1 para mockup exacto).
  final int? initialSelected;

  /// Se llama una sola vez con el índice elegido y si fue correcto.
  final void Function(int index, bool correct) onAnswered;

  /// Valor 0..1 de la barra amarilla inferior (avance de la partida).
  final double progress;

  /// Permite bloquear las opciones (p. ej. si no es el turno del jugador).
  final bool enabled;

  @override
  State<MathChallengeScreen> createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends State<MathChallengeScreen>
    with TickerProviderStateMixin {
  // Tamaño de referencia del mockup (px).
  static const double _designW = 1024;
  static const double _designH = 1536;

  final FlutterTts _tts = FlutterTts();
  int? _selected;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
    } catch (_) {
      // TTS no disponible en esta plataforma: el botón simplemente no habla.
    }
  }

  @override
  void didUpdateWidget(covariant MathChallengeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.challenge, widget.challenge) ||
        oldWidget.initialSelected != widget.initialSelected) {
      _answered = false;
      _selected = widget.initialSelected;
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  void _speak() {
    AudioManagerService().playSfx('bubble.wav');
    _tts.stop();
    _tts.speak(widget.challenge.narration);
  }

  void _select(int index) {
    if (!widget.enabled || _answered) return;
    _answered = true;
    setState(() => _selected = index);
    final correct = widget.challenge.isCorrect(index);
    AudioManagerService().playSfx(correct ? 'positiva.wav' : 'nagativa.wav');
    widget.onAnswered(index, correct);
  }

  /// Animación de entrada escalonada para cada bloque.
  Widget _staggered({required double start, required Widget child}) {
    final anim = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        start,
        math.min(start + 0.5, 1),
        curve: Curves.easeOutBack,
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 40),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo ilustrado (03_fondo_escenario) ──
          Image.asset(
            'assets/images/materueda/fondo_escenario.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                // Unidad de escala: 1u = 1px del mockup.
                final u = math.min(
                  box.maxWidth / _designW,
                  box.maxHeight / _designH,
                );

                return Stack(
                  children: [
                    // ── Decoraciones flotantes (+, =) ──
                    ..._decorations(u, box),

                    // ── Numi (abajo a la derecha) ──
                    Positioned(
                      right: -20 * u,
                      bottom: 0,
                      child: AnimatedBuilder(
                        animation: _float,
                        builder: (_, c) => Transform.translate(
                          offset: Offset(
                            0,
                            -12 * u * Curves.easeInOut.transform(_float.value),
                          ),
                          child: c,
                        ),
                        child: Image.asset(
                          'assets/images/materueda/numi.png',
                          width: 340 * u,
                        ),
                      ),
                    ),

                    // ── Contenido principal ──
                    Positioned(
                      top: 0,
                      bottom: 300 * u,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: _designW * u,
                          child: Column(
                            children: [
                              SizedBox(height: 30 * u),
                              const Spacer(),
                              _staggered(
                                start: 0,
                                child: _CategoryBanner(
                                  label: challenge.category.label,
                                  u: u,
                                ),
                              ),
                              SizedBox(height: 70 * u),
                              _staggered(
                                start: 0.1,
                                child: _QuestionRow(
                                  question: challenge.question,
                                  onPlay: _speak,
                                  u: u,
                                ),
                              ),
                              SizedBox(height: 50 * u),
                              _staggered(
                                start: 0.2,
                                child: _IllustrationCard(
                                  challenge: challenge,
                                  u: u,
                                ),
                              ),
                              SizedBox(height: 70 * u),
                              _staggered(
                                start: 0.35,
                                child: _OptionsRow(
                                  challenge: challenge,
                                  selected: _selected,
                                  onTap: _select,
                                  u: u,
                                ),
                              ),
                              const Spacer(flex: 2),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Barra de progreso ──
                    Positioned(
                      left: (box.maxWidth - _designW * u) / 2 + 235 * u,
                      bottom: 190 * u,
                      child: _ProgressBar(value: widget.progress, u: u),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _decorations(double u, BoxConstraints box) {
    final dx = (box.maxWidth - _designW * u) / 2;
    Widget plus(Color c, double size) => _PlusSign(color: c, size: size * u);
    return [
      Positioned(
        left: dx + 55 * u,
        top: 180 * u,
        child: plus(MateColors.amarilloEstrella, 70),
      ),
      Positioned(
        left: dx + 950 * u,
        top: 185 * u,
        child: plus(MateColors.turquesaCalma, 52),
      ),
      Positioned(
        left: dx + 920 * u,
        top: 755 * u,
        child: plus(MateColors.amarilloEstrella, 78),
      ),
      Positioned(
        left: dx + 30 * u,
        top: 745 * u,
        child: _EqualsSign(size: 60 * u),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// COMPONENTES
// ═══════════════════════════════════════════════════════════

TextStyle _fredoka(
  double size, {
  Color color = Colors.white,
  FontWeight weight = FontWeight.w700,
}) => TextStyle(
  fontFamily: 'Fredoka',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.1,
);

/// Píldora morada con el nombre de la categoría y destellos amarillos.
class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.label, required this.u});

  final String label;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 520 * u, maxWidth: 820 * u),
      padding: EdgeInsets.symmetric(horizontal: 26 * u, vertical: 20 * u),
      decoration: BoxDecoration(
        gradient: MateColors.bannerGradient,
        borderRadius: BorderRadius.circular(60 * u),
        border: Border.all(
          color: MateColors.moradoOscuro.withValues(alpha: 0.35),
          width: 3 * u,
        ),
        boxShadow: [
          BoxShadow(
            color: MateColors.moradoOscuro.withValues(alpha: 0.45),
            offset: Offset(0, 8 * u),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Sparkle(size: 46 * u),
          SizedBox(width: 18 * u),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: _fredoka(64 * u, weight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 18 * u),
          _Sparkle(size: 46 * u, mirrored: true),
        ],
      ),
    );
  }
}

/// Pregunta con contorno blanco + botón amarillo de audio.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.onPlay,
    required this.u,
  });

  final String question;
  final VoidCallback onPlay;
  final double u;

  @override
  Widget build(BuildContext context) {
    final size = 74 * u;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60 * u),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Stack(
                children: [
                  Text(
                    question,
                    style: _fredoka(size).copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 14 * u
                        ..strokeJoin = StrokeJoin.round
                        ..color = Colors.white,
                      shadows: [
                        Shadow(
                          color: MateColors.moradoOscuro.withValues(
                            alpha: 0.25,
                          ),
                          offset: Offset(0, 6 * u),
                          blurRadius: 6 * u,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    question,
                    style: _fredoka(size, color: MateColors.moradoVivo),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 28 * u),
          _PlayButton(onTap: onPlay, u: u),
        ],
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.onTap, required this.u});

  final VoidCallback onTap;
  final double u;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.u;
    final d = 100 * u;
    return Semantics(
      button: true,
      label: 'Escuchar la pregunta',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MateColors.amarilloGradient,
              border: Border.all(color: Colors.white, width: 5 * u),
              boxShadow: [
                BoxShadow(
                  color: MateColors.amarilloOscuro,
                  offset: Offset(0, 7 * u),
                ),
              ],
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: MateColors.moradoVivo,
              size: 70 * u,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta crema con borde morado que contiene la ilustración del reto.
class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.challenge, required this.u});

  final MathChallenge challenge;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 220 * u),
          child: _Sparkle(size: 54 * u),
        ),
        SizedBox(width: 6 * u),
        Container(
          width: 770 * u,
          height: 380 * u,
          padding: EdgeInsets.all(32 * u),
          decoration: BoxDecoration(
            color: MateColors.cremaSuave,
            borderRadius: BorderRadius.circular(70 * u),
            border: Border.all(color: MateColors.moradoVivo, width: 12 * u),
            boxShadow: [
              BoxShadow(
                color: MateColors.moradoOscuro.withValues(alpha: 0.25),
                offset: Offset(0, 10 * u),
                blurRadius: 14 * u,
              ),
            ],
          ),
          child: Center(
            child: _ChallengeVisual(challenge: challenge, u: u),
          ),
        ),
        SizedBox(width: 6 * u),
        Padding(
          padding: EdgeInsets.only(bottom: 220 * u),
          child: _Sparkle(size: 54 * u, mirrored: true),
        ),
      ],
    );
  }
}

/// Ilustración central según el tipo de reto.
class _ChallengeVisual extends StatelessWidget {
  const _ChallengeVisual({required this.challenge, required this.u});

  final MathChallenge challenge;
  final double u;

  Widget _group(int count, {double? size, int crossed = 0}) {
    final s = size ?? (count <= 5 ? 150 * u : (count <= 8 ? 120 * u : 95 * u));
    // Igual que el mockup: filas de 4 centradas.
    final perRow = count <= 5 ? 4 : 4;
    final rows = <Widget>[];
    for (var i = 0; i < count; i += perRow) {
      final end = math.min(i + perRow, count);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var j = i; j < end; j++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * u),
                child: ChallengeObjectIcon(
                  object: challenge.object,
                  size: s,
                  crossedOut: j >= count - crossed,
                ),
              ),
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _operator(String symbol) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 14 * u),
    child: Text(symbol, style: _fredoka(110 * u, color: MateColors.moradoVivo)),
  );

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (challenge.visual) {
      ChallengeVisual.group => _group(challenge.countA),
      ChallengeVisual.subtraction => _group(
        challenge.countA,
        crossed: challenge.countB,
      ),
      ChallengeVisual.addition => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _group(challenge.countA, size: 105 * u),
          _operator('+'),
          _group(challenge.countB, size: 105 * u),
        ],
      ),
      ChallengeVisual.twoGroups => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _group(challenge.countA, size: 105 * u),
          Container(
            width: 8 * u,
            height: 260 * u,
            margin: EdgeInsets.symmetric(horizontal: 30 * u),
            decoration: BoxDecoration(
              color: MateColors.pista,
              borderRadius: BorderRadius.circular(8 * u),
            ),
          ),
          _group(challenge.countB, size: 105 * u),
        ],
      ),
      ChallengeVisual.shape => ShapeIcon(
        shape: challenge.shape!,
        size: 260 * u,
        color: MateColors.coralEnergia,
      ),
    };
    return FittedBox(fit: BoxFit.scaleDown, child: content);
  }
}

/// Fila de opciones táctiles grandes.
class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.challenge,
    required this.selected,
    required this.onTap,
    required this.u,
  });

  final MathChallenge challenge;
  final int? selected;
  final ValueChanged<int> onTap;
  final double u;

  @override
  Widget build(BuildContext context) {
    final n = challenge.options.length;
    final width = n == 2 ? 380 * u : 272 * u;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) SizedBox(width: 18 * u),
          _OptionButton(
            option: challenge.options[i],
            selected: selected == i,
            dimmed: selected != null && selected != i,
            width: width,
            onTap: () => onTap(i),
            u: u,
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatefulWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.dimmed,
    required this.width,
    required this.onTap,
    required this.u,
  });

  final ChallengeOption option;
  final bool selected;
  final bool dimmed;
  final double width;
  final VoidCallback onTap;
  final double u;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _down = false;

  Widget _label(Color color) {
    final u = widget.u;
    final o = widget.option;
    if (o.shape != null) {
      return ShapeIcon(
        shape: o.shape!,
        size: 120 * u,
        color: widget.selected ? Colors.white : MateColors.moradoVivo,
      );
    }
    if (o.label == '◀' || o.label == '▶') {
      return Icon(
        o.label == '◀' ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
        size: 130 * u,
        color: color,
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(o.label, style: _fredoka(130 * u, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.u;
    final sel = widget.selected;
    final h = 200 * u;
    final depth = _down ? 3 * u : 10 * u;

    return Semantics(
      button: true,
      selected: sel,
      label: widget.option.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedOpacity(
          opacity: widget.dimmed ? 0.6 : 1,
          duration: const Duration(milliseconds: 200),
          child: AnimatedScale(
            scale: sel ? 1.06 : (_down ? 0.96 : 1),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: widget.width,
              height: h,
              margin: EdgeInsets.only(top: 10 * u - depth),
              decoration: BoxDecoration(
                color: sel ? null : MateColors.cremaSuave,
                gradient: sel ? MateColors.turquesaGradient : null,
                borderRadius: BorderRadius.circular(56 * u),
                border: Border.all(
                  color: sel
                      ? MateColors.turquesaOscuro
                      : MateColors.moradoVivo,
                  width: 11 * u,
                ),
                boxShadow: [
                  BoxShadow(
                    color: sel
                        ? MateColors.turquesaOscuro
                        : MateColors.moradoOscuro,
                    offset: Offset(0, depth),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sel)
                    _Sparkle(size: 40 * u, color: MateColors.amarilloEstrella),
                  if (sel) SizedBox(width: 10 * u),
                  Flexible(
                    child: _label(sel ? Colors.white : MateColors.moradoVivo),
                  ),
                  if (sel) SizedBox(width: 10 * u),
                  if (sel)
                    _Sparkle(
                      size: 40 * u,
                      mirrored: true,
                      color: MateColors.amarilloEstrella,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra amarilla de avance con pista lila y borde morado.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.u});

  final double value;
  final double u;

  @override
  Widget build(BuildContext context) {
    final w = 485 * u;
    final h = 90 * u;
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.all(14 * u),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: MateColors.moradoVivo, width: 6 * u),
        boxShadow: [
          BoxShadow(
            color: MateColors.moradoOscuro.withValues(alpha: 0.35),
            offset: Offset(0, 6 * u),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: Stack(
          children: [
            Container(color: MateColors.pista),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: MateColors.amarilloGradient,
                    borderRadius: BorderRadius.circular(h / 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DECORACIONES
// ═══════════════════════════════════════════════════════════

/// Tres trazos amarillos que irradian (los "destellos" del mockup).
class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.size,
    this.mirrored = false,
    this.color = MateColors.amarilloEstrella,
  });

  final double size;
  final bool mirrored;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: mirrored,
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparklePainter(color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * 0.45, h * 0.10), Offset(w * 0.75, h * 0.30), p);
    canvas.drawLine(Offset(w * 0.15, h * 0.50), Offset(w * 0.75, h * 0.50), p);
    canvas.drawLine(Offset(w * 0.45, h * 0.90), Offset(w * 0.75, h * 0.70), p);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.color != color;
}

class _PlusSign extends StatelessWidget {
  const _PlusSign({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = size * 0.3;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(t / 2),
      ),
    );
    return Transform.rotate(
      angle: -0.15,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [bar(size, t), bar(t, size)],
        ),
      ),
    );
  }
}

class _EqualsSign extends StatelessWidget {
  const _EqualsSign({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = size * 0.28;
    Widget bar() => Container(
      width: size,
      height: t,
      decoration: BoxDecoration(
        color: MateColors.moradoVivo,
        borderRadius: BorderRadius.circular(t / 2),
      ),
    );
    return Transform.rotate(
      angle: -0.12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bar(),
          SizedBox(height: t * 0.8),
          bar(),
        ],
      ),
    );
  }
}
