import 'package:flutter/material.dart';

import 'package:wordwonderslink/core/constants/mate_colors.dart';

TextStyle mateFredoka(
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

/// Fondo ilustrado de MateRueda con el contenido centrado y acotado
/// (se ve bien tanto en teléfono como en tablet/proyector).
class MateBackground extends StatelessWidget {
  const MateBackground({
    super.key,
    required this.child,
    this.maxWidth = 620,
    this.showNumi = false,
  });

  final Widget child;
  final double maxWidth;

  /// Muestra a Numi (mascota) abajo a la derecha.
  final bool showNumi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/materueda/fondo_escenario.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          if (showNumi)
            Positioned(
              right: -10,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/materueda/numi.png',
                  width: 150,
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón en forma de píldora con degradado y sombra inferior
/// (identidad visual, Avance II §3.6).
class MateButton extends StatefulWidget {
  const MateButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient = const LinearGradient(
      colors: [Color(0xFFFF8A75), MateColors.coralEnergia],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    this.shadow = const Color(0xFFC9442F),
    this.height = 76,
    this.fontSize = 30,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient gradient;
  final Color shadow;
  final double height;
  final double fontSize;

  const MateButton.turquesa({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 76,
    this.fontSize = 30,
  }) : gradient = MateColors.turquesaGradient,
       shadow = MateColors.turquesaOscuro;

  const MateButton.amarillo({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 76,
    this.fontSize = 30,
  }) : gradient = MateColors.amarilloGradient,
       shadow = MateColors.amarilloOscuro;

  @override
  State<MateButton> createState() => _MateButtonState();
}

class _MateButtonState extends State<MateButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final depth = _down ? 2.0 : 8.0;
    final dark = widget.gradient == MateColors.amarilloGradient;
    final fg = dark ? MateColors.moradoOscuro : Colors.white;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onTap!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            height: widget.height,
            margin: EdgeInsets.only(top: 8 - depth + 2),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.height),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [BoxShadow(color: widget.shadow, offset: Offset(0, depth))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: widget.fontSize * 1.2),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: mateFredoka(widget.fontSize, color: fg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta crema con borde morado (mismo estilo que la del reto).
class MateCard extends StatelessWidget {
  const MateCard({super.key, required this.child, this.padding = 24});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: MateColors.cremaSuave,
      borderRadius: BorderRadius.circular(40),
      border: Border.all(color: MateColors.moradoVivo, width: 6),
      boxShadow: [
        BoxShadow(
          color: MateColors.moradoOscuro.withValues(alpha: 0.25),
          offset: const Offset(0, 8),
          blurRadius: 12,
        ),
      ],
    ),
    child: child,
  );
}

/// Texto con contorno blanco (como la pregunta del reto).
class MateOutlinedText extends StatelessWidget {
  const MateOutlinedText(
    this.text, {
    super.key,
    this.size = 44,
    this.color = MateColors.moradoVivo,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double size;
  final Color color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Text(
        text,
        textAlign: textAlign,
        style: mateFredoka(size).copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.2
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white,
        ),
      ),
      Text(text, textAlign: textAlign, style: mateFredoka(size, color: color)),
    ],
  );
}

/// Círculo de color con el número de la mesa.
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({
    super.key,
    required this.color,
    required this.label,
    this.size = 84,
  });

  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: size * 0.07),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          offset: Offset(0, size * 0.06),
        ),
      ],
    ),
    child: Text(
      label,
      style: mateFredoka(size * 0.5, color: Colors.white).copyWith(
        shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
      ),
    ),
  );
}
