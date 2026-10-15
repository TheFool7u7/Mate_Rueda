import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';

/// Ilustraciones vectoriales planas (flat design) para los retos.
///
/// Se dibujan con [CustomPainter] para no depender de imágenes externas
/// y mantener el estilo redondeado de la identidad visual de MateRueda.
class ChallengeObjectIcon extends StatelessWidget {
  const ChallengeObjectIcon({
    super.key,
    required this.object,
    this.size = 64,
    this.crossedOut = false,
  });

  final ChallengeObject object;
  final double size;

  /// En restas, los objetos "retirados" se muestran tenues y tachados.
  final bool crossedOut;

  @override
  Widget build(BuildContext context) {
    Widget icon = CustomPaint(
      size: Size.square(size),
      painter: switch (object) {
        ChallengeObject.manzana => const _ApplePainter(),
        ChallengeObject.estrella => const _StarPainter(),
        ChallengeObject.pelota => const _BallPainter(),
        ChallengeObject.flor => const _FlowerPainter(),
      },
    );
    if (crossedOut) {
      icon = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.35, child: icon),
          CustomPaint(size: Size.square(size), painter: const _CrossPainter()),
        ],
      );
    }
    return SizedBox.square(dimension: size, child: icon);
  }
}

/// Figura geométrica plana.
class ShapeIcon extends StatelessWidget {
  const ShapeIcon({
    super.key,
    required this.shape,
    this.size = 64,
    this.color = const Color(0xFFFF6F59),
  });

  final ShapeKind shape;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ShapePainter(shape, color),
  );
}

// ═══════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════

class _ApplePainter extends CustomPainter {
  const _ApplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cuerpo: dos lóbulos unidos.
    final body = Path()
      ..moveTo(w * 0.50, h * 0.30)
      ..cubicTo(w * 0.30, h * 0.18, w * 0.04, h * 0.28, w * 0.07, h * 0.56)
      ..cubicTo(w * 0.10, h * 0.82, w * 0.30, h * 0.98, w * 0.50, h * 0.90)
      ..cubicTo(w * 0.70, h * 0.98, w * 0.90, h * 0.82, w * 0.93, h * 0.56)
      ..cubicTo(w * 0.96, h * 0.28, w * 0.70, h * 0.18, w * 0.50, h * 0.30)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [Color(0xFFFF6B5A), Color(0xFFE8322A), Color(0xFFC21F1F)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Brillo.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.20, h * 0.38, w * 0.13, h * 0.20),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Tallo.
    canvas.drawLine(
      Offset(w * 0.49, h * 0.32),
      Offset(w * 0.44, h * 0.12),
      Paint()
        ..color = const Color(0xFF7A4A2A)
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // Hoja.
    final leaf = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.58, h * 0.02, w * 0.82, h * 0.06)
      ..quadraticBezierTo(w * 0.76, h * 0.26, w * 0.50, h * 0.22)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawLine(
      Offset(w * 0.53, h * 0.20),
      Offset(w * 0.74, h * 0.10),
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = w * 0.015,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width * 0.48;
    final inner = outer * 0.48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFC21A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF2A100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      c + Offset(-outer * 0.25, -outer * 0.2),
      outer * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BallPainter extends CustomPainter {
  const _BallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.44;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(rect, Paint()..color = const Color(0xFF2EC4B6));
    canvas.drawRect(
      Rect.fromLTRB(rect.left, c.dy - r * 0.28, rect.right, c.dy + r * 0.28),
      Paint()..color = const Color(0xFFFFD23F),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.4, -r * 0.45),
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.2;
    final petal = Paint()..color = const Color(0xFFFF6F9C);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a) * r * 1.2, math.sin(a) * r * 1.2),
        r,
        petal,
      );
    }
    canvas.drawCircle(c, r * 0.9, Paint()..color = const Color(0xFFFFD23F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF6A4C93)
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.shape, this.color);

  final ShapeKind shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = Color.lerp(color, Colors.black, 0.2)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeJoin = StrokeJoin.round;

    final Path path;
    switch (shape) {
      case ShapeKind.circulo:
        path = Path()
          ..addOval(
            Rect.fromCircle(center: size.center(Offset.zero), radius: w * 0.42),
          );
      case ShapeKind.cuadrado:
        path = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
              Radius.circular(w * 0.08),
            ),
          );
      case ShapeKind.triangulo:
        path = Path()
          ..moveTo(w * 0.5, h * 0.08)
          ..lineTo(w * 0.94, h * 0.88)
          ..lineTo(w * 0.06, h * 0.88)
          ..close();
      case ShapeKind.rectangulo:
        path = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.04, h * 0.25, w * 0.92, h * 0.5),
              Radius.circular(w * 0.06),
            ),
          );
    }
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.shape != shape || old.color != color;
}
