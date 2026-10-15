import 'package:flutter/material.dart';

/// Paleta oficial de MateRueda (Avance II, sección 3.6 — Identidad visual).
///
/// Se mantiene separada de [AppColors] mientras se migran las pantallas
/// heredadas de Word Wonders Link.
class MateColors {
  MateColors._();

  // ── Paleta base ──
  static const Color moradoRueda = Color(0xFF6A4C93);
  static const Color coralEnergia = Color(0xFFFF6F59);
  static const Color amarilloEstrella = Color(0xFFFFD23F);
  static const Color turquesaCalma = Color(0xFF2EC4B6);
  static const Color cremaSuave = Color(0xFFFDF8F0);

  // ── Variantes usadas en los mockups ──
  static const Color moradoVivo = Color(0xFF6C3FC5);
  static const Color moradoOscuro = Color(0xFF4B2A8C);
  static const Color turquesaOscuro = Color(0xFF169C92);
  static const Color amarilloOscuro = Color(0xFFF2B400);
  static const Color cielo = Color(0xFF5ED3EE);
  static const Color pista = Color(0xFFE6E0F5);

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF7B4FD6), Color(0xFF5E35B1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient turquesaGradient = LinearGradient(
    colors: [Color(0xFF3FD9CB), Color(0xFF1FB3A6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient amarilloGradient = LinearGradient(
    colors: [Color(0xFFFFE066), Color(0xFFFFC107)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
