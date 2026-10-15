import 'package:flutter/material.dart';

/// Paleta de colores oficial de Word Wonders Link — Rediseño Game Show.
/// Nunca usar colores hardcodeados fuera de este archivo.
class AppColors {
  AppColors._();

  // ── Colores principales ──
  static const Color backgroundColor = Color(0xFFE8EEF8);
  static const Color primaryBlue = Color(0xFF3A7BD5);
  static const Color primaryRed = Color(0xFFE82020);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // ── Variantes de azul ──
  static const Color primaryBlueLight = Color(0xFF6FA3E8);
  static const Color primaryBlueDark = Color(0xFF2256A8);

  // ── Variantes de rojo ──
  static const Color primaryRedLight = Color(0xFFF07070);
  static const Color primaryRedDark = Color(0xFFB51515);

  // ── Fondos especiales de pantalla ──
  static const Color punishmentBg = Color(
    0xFFF8E8E8,
  ); // Castigo: rojo cálido suave
  static const Color victoryBg = Color(0xFFFFF8E7); // Victoria: dorado suave

  // ── Gradientes de botones ──
  static const LinearGradient buttonRedGradient = LinearGradient(
    colors: [Color(0xFFFF3E3E), Color(0xFFE82020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonBlueGradient = LinearGradient(
    colors: [Color(0xFF5B9EF5), Color(0xFF3A7BD5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonOrangeGradient = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFE82020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGreenGradient = LinearGradient(
    colors: [Color(0xFF55E88A), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Gradientes especiales ──
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD060), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statsGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient punishmentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFE82020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Colores para el ranking / podio ──
  static const Color goldRank = Color(0xFFFFD700);
  static const Color silverRank = Color(0xFFC0C0C0);
  static const Color bronzeRank = Color(0xFFCD7F32);

  // ── Texto ──
  static const Color textGrey = Color(0xFF7B7D8D);
  static const Color textLight = Color(0xFFB0B3C5);
  static const Color dividerColor = Color(0xFFE0E3EB);

  // ── Sombras ──
  static const Color shadowLight = Color(0x1A000050);
  static const Color shadowMedium = Color(0x33000050);
  static const Color shadowBlue = Color(0x283A7BD5);

  // ── Colores de jugadores ──
  static const List<Color> playerColors = [
    Color(0xFF3A7BD5), // Azul
    Color(0xFFE82020), // Rojo
    Color(0xFF2ECC71), // Verde
    Color(0xFFF5A623), // Dorado
    Color(0xFF9B59B6), // Púrpura
    Color(0xFF1ABC9C), // Turquesa
    Color(0xFFE67E22), // Naranja
    Color(0xFFE91E63), // Rosa
  ];

  // ── Estado de letras en la rueda ──
  static const Color letterFree = Color(0xFFFFFFFF);
  static const Color letterUsed = Color(0xFF9E9E9E);
  static const Color letterLocked = Color(0xFFFFEB3B);
}
