import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';
import 'package:wordwonderslink/features/game/domain/letter_model.dart';

/// Rueda giratoria de letras del alfabeto español.
/// Estilo "game show" con sectores alternados azul/rojo y letras en fichas blancas.
class LetterWheelWidget extends StatefulWidget {
  final Map<String, LetterModel> letters;
  final void Function(String char)? onLetterTap;
  final bool enabled;

  const LetterWheelWidget({
    super.key,
    required this.letters,
    this.onLetterTap,
    this.enabled = true,
  });

  @override
  State<LetterWheelWidget> createState() => _LetterWheelWidgetState();
}

class _LetterWheelWidgetState extends State<LetterWheelWidget>
    with TickerProviderStateMixin {
  double _rotationAngle = 0.0;
  double _previousAngle = 0.0;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  // Sectores del disco interior
  static const int _sectorCount = 12;

  static const _alphabet = [
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

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.letterWheelSize(context),
      height: AppDimensions.letterWheelSize(context),
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: AnimatedBuilder(
          animation: _spinAnimation,
          builder: (context, child) {
            return Transform.rotate(angle: _rotationAngle, child: child);
          },
          child: CustomPaint(
            painter: _WheelPainter(
              rotationAngle: _rotationAngle,
              sectorCount: _sectorCount,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [..._buildLetterCircles(), _buildCenterDisc()],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLetterCircles() {
    final totalLetters = _alphabet.length;
    final circleSize = AppDimensions.letterCircleSize(context);
    final radius =
        (AppDimensions.letterWheelSize(context) / 2) - (circleSize / 2) - 8;

    return List.generate(totalLetters, (index) {
      final angle = (2 * pi * index / totalLetters) - (pi / 2);
      final x = radius * cos(angle);
      final y = radius * sin(angle);

      final char = _alphabet[index];
      final letter = widget.letters[char];
      final status = letter?.status ?? LetterStatus.free;

      return Positioned(
        left:
            (AppDimensions.letterWheelSize(context) / 2) +
            x -
            (AppDimensions.letterCircleSize(context) / 2),
        top:
            (AppDimensions.letterWheelSize(context) / 2) +
            y -
            (AppDimensions.letterCircleSize(context) / 2),
        child: _LetterCircle(
          char: char,
          status: status,
          claimedBy: letter?.claimedBy,
          onTap: widget.enabled && status == LetterStatus.free
              ? () => widget.onLetterTap?.call(char)
              : null,
        ),
      );
    });
  }

  Widget _buildCenterDisc() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradiente radial que simula una esfera brillante
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFC8D8F0),
            Color(0xFF7AAEE8),
            Color(0xFF3A7BD5),
          ],
          stops: [0.0, 0.25, 0.65, 1.0],
          center: Alignment(-0.3, -0.4),
        ),
        border: Border.all(color: const Color(0xFF2255AA), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A44BB).withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 4,
            offset: const Offset(-1, -2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Colors.white, Color(0xFFC0C8D8), Color(0xFF8899BB)],
              stops: [0.0, 0.55, 1.0],
              center: Alignment(-0.3, -0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(
      AppDimensions.letterWheelSize(context) / 2,
      AppDimensions.letterWheelSize(context) / 2,
    );
    final position = details.localPosition - center;
    final angle = atan2(position.dy, position.dx);

    setState(() {
      _rotationAngle += (angle - _previousAngle) * 0.3;
      _previousAngle = angle;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy);

    if (speed > 100) {
      final targetAngle = _rotationAngle + (speed * 0.001);
      _spinController.reset();

      AudioManagerService().startLoopSfx('tic_tic_tic ruleta.wav');

      _spinAnimation = Tween<double>(begin: _rotationAngle, end: targetAngle)
          .animate(
            CurvedAnimation(
              parent: _spinController,
              curve: Curves.easeOutCubic,
            ),
          );

      _spinAnimation.addListener(() {
        setState(() {
          _rotationAngle = _spinAnimation.value;
        });
      });

      _spinController.forward().then((_) {
        AudioManagerService().stopLoopSfx();
        AudioManagerService().playSfx('termina_de_girar.wav');
      });
    }
  }
}

// ─────────────────────────────────────────────
// Círculo individual de letra — estilo ficha de juego
// ─────────────────────────────────────────────
class _LetterCircle extends StatefulWidget {
  final String char;
  final LetterStatus status;
  final String? claimedBy;
  final VoidCallback? onTap;

  const _LetterCircle({
    required this.char,
    required this.status,
    this.claimedBy,
    this.onTap,
  });

  @override
  State<_LetterCircle> createState() => _LetterCircleState();
}

class _LetterCircleState extends State<_LetterCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.78,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    _tapController.forward().then((_) {
      _tapController.reverse();
      widget.onTap!();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFree = widget.status == LetterStatus.free;
    final isLocked = widget.status == LetterStatus.locked;
    final playerColor = _getPlayerColor();

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: AppDimensions.letterCircleSize(context),
          height: AppDimensions.letterCircleSize(context),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isFree
                ? const RadialGradient(
                    colors: [Colors.white, Color(0xFFDCE8F8)],
                    center: Alignment(-0.3, -0.4),
                  )
                : isLocked
                ? RadialGradient(
                    colors: [
                      Colors.white,
                      Color.lerp(Colors.white, playerColor, 0.25)!,
                    ],
                    center: const Alignment(-0.3, -0.4),
                  )
                : const RadialGradient(
                    colors: [Color(0xFFF0F0F0), Color(0xFFD8D8D8)],
                  ),
            border: Border.all(
              color: isFree
                  ? const Color(0xFF3A7BD5)
                  : isLocked
                  ? playerColor
                  : const Color(0xFFAAAAAA),
              width: isLocked ? 2.5 : 2.0,
            ),
            boxShadow: isFree
                ? [
                    BoxShadow(
                      color: const Color(0xFF1A3B8B).withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 2,
                      offset: const Offset(-1, -1),
                    ),
                  ]
                : isLocked
                ? [
                    BoxShadow(
                      color: playerColor.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.char,
              style: TextStyle(
                fontSize: AppDimensions.letterFontSize(context),
                fontWeight: FontWeight.w900,
                color: isFree
                    ? const Color(0xFF1A2B4A)
                    : isLocked
                    ? playerColor
                    : const Color(0xFF888888),
                decoration: widget.status == LetterStatus.used
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: const Color(0xFF888888),
                decorationThickness: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPlayerColor() {
    if (widget.claimedBy == null) return const Color(0xFF3A7BD5);
    final colorIndex =
        widget.claimedBy.hashCode.abs() % AppColors.playerColors.length;
    return AppColors.playerColors[colorIndex];
  }
}

// ─────────────────────────────────────────────
// Pinta el aro exterior + sectores azul/rojo
// ─────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final double rotationAngle;
  final int sectorCount;

  const _WheelPainter({required this.rotationAngle, required this.sectorCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 2;
    final innerR = outerR * 0.72; // radio del disco de sectores

    // ── Sombra exterior ──
    final shadowPaint = Paint()
      ..color = const Color(0xFF1A3080).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center + const Offset(0, 4), outerR, shadowPaint);

    // ── Aro exterior azul ──
    final rimShader = const LinearGradient(
      colors: [Color(0xFF5588DD), Color(0xFF2255AA), Color(0xFF1133AA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: center, radius: outerR));
    canvas.drawCircle(center, outerR, Paint()..shader = rimShader);

    // Highlight del aro
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── Sectores alternados azul/rojo ──
    final sectorAngle = (2 * pi) / sectorCount;
    for (int i = 0; i < sectorCount; i++) {
      final startA = i * sectorAngle + rotationAngle - pi / 2;
      final isRed = i % 2 == 0;

      final sectorRect = Rect.fromCircle(center: center, radius: innerR);
      final sectorShader = RadialGradient(
        colors: isRed
            ? const [Color(0xFFFF6060), Color(0xFFE82020), Color(0xFFC00000)]
            : const [Color(0xFF5599FF), Color(0xFF2266DD), Color(0xFF1144BB)],
        stops: const [0.0, 0.6, 1.0],
        radius: 1.0,
      ).createShader(sectorRect);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(sectorRect, startA, sectorAngle, false)
        ..close();

      canvas.drawPath(path, Paint()..shader = sectorShader);

      // Divisor blanco entre sectores
      canvas.drawLine(
        center,
        Offset(
          center.dx + innerR * cos(startA),
          center.dy + innerR * sin(startA),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
    }

    // Highlight suave sobre los sectores
    final highlightGrad = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.22),
        Colors.white.withValues(alpha: 0.06),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
      center: const Alignment(0, -0.5),
    ).createShader(Rect.fromCircle(center: center, radius: innerR));
    canvas.drawCircle(center, innerR, Paint()..shader = highlightGrad);

    // ── Borde separador aro/sectores ──
    canvas.drawCircle(
      center,
      innerR + 1,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Separadores de letras en el aro ──
    final n = 27; // letras del alfabeto español
    for (int i = 0; i < n; i++) {
      final a = (2 * pi * i / n) - pi / 2 + rotationAngle;
      canvas.drawLine(
        Offset(
          center.dx + (innerR + 2) * cos(a),
          center.dy + (innerR + 2) * sin(a),
        ),
        Offset(
          center.dx + (outerR - 2) * cos(a),
          center.dy + (outerR - 2) * sin(a),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.rotationAngle != rotationAngle;
}
