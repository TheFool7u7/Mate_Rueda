import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';

/// Widget de fondo reutilizable con patrón watermark sutil.
/// Aplica un color base y dibuja formas redondeadas repetidas al 5% de opacidad.
/// Cada pantalla puede pasar un [tint] diferente (castigo = rojo, victoria = dorado).
class AppBackground extends StatelessWidget {
  final Widget child;
  final Color? tint;

  const AppBackground({super.key, required this.child, this.tint});

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? AppColors.backgroundColor;
    return Stack(
      children: [
        // Fondo base
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: bg,
          ),
        ),
        // Watermark pattern
        Positioned.fill(
          child: CustomPaint(
            painter: _WatermarkPainter(baseColor: AppColors.primaryBlue),
          ),
        ),
        // Contenido
        child,
      ],
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  final Color baseColor;
  _WatermarkPainter({required this.baseColor});

  static const _letters = ['W', 'L', '*', '◆', 'W', 'L'];
  static const _spacing = 72.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    int idx = 0;

    for (double y = -_spacing; y < size.height + _spacing; y += _spacing) {
      final offset = ((y / _spacing).floor() % 2 == 0) ? 0.0 : _spacing / 2;
      for (
        double x = -_spacing + offset;
        x < size.width + _spacing;
        x += _spacing
      ) {
        final letter = _letters[idx % _letters.length];
        idx++;

        if (letter == '*') {
          // Círculo pequeño
          canvas.drawCircle(Offset(x, y), 6, paint);
        } else if (letter == '◆') {
          // Rombo (cuadrado rotado 45°)
          final path = Path();
          path.moveTo(x, y - 8);
          path.lineTo(x + 8, y);
          path.lineTo(x, y + 8);
          path.lineTo(x - 8, y);
          path.close();
          canvas.drawPath(path, paint);
        } else {
          // Letra con rounded rect de fondo
          final rrect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 24, height: 24),
            const Radius.circular(6),
          );
          canvas.drawRRect(rrect, paint);

          textPainter.text = TextSpan(
            text: letter,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: baseColor.withValues(
                alpha: 0.0,
              ), // invisible — solo la silueta
            ),
          );
        }
      }
    }

    // Superponer círculos grandes muy sutiles en las esquinas
    final cornerPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, 0), 120, cornerPaint);
    canvas.drawCircle(Offset(size.width, size.height), 140, cornerPaint);
    canvas.drawCircle(Offset(size.width, 0), 80, cornerPaint);

    // Arcos decorativos en background
    final arcPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double r = 60; r < 200; r += 40) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.15),
          radius: r,
        ),
        0,
        math.pi * 2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WatermarkPainter old) => old.baseColor != baseColor;
}
