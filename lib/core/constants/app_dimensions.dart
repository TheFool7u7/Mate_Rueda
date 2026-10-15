import 'package:flutter/material.dart';

/// Dimensiones, espaciados, radios y tamaños reutilizables.
/// Utiliza MediaQuery para determinar si es tablet y devolver valores escalados.
class AppDimensions {
  AppDimensions._();

  static bool isTablet(BuildContext? context) {
    if (context == null) return false;
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  // ── Espaciados (padding / margin) ──
  static double spacingXS(BuildContext? context) =>
      isTablet(context) ? 6.0 : 4.0;
  static double spacingS(BuildContext? context) =>
      isTablet(context) ? 12.0 : 8.0;
  static double spacingM(BuildContext? context) =>
      isTablet(context) ? 18.0 : 12.0;
  static double spacingL(BuildContext? context) =>
      isTablet(context) ? 24.0 : 16.0;
  static double spacingXL(BuildContext? context) =>
      isTablet(context) ? 32.0 : 24.0;
  static double spacingXXL(BuildContext? context) =>
      isTablet(context) ? 48.0 : 32.0;
  static double spacingXXXL(BuildContext? context) =>
      isTablet(context) ? 64.0 : 48.0;
  static double screenPadding(BuildContext? context) =>
      isTablet(context) ? 48.0 : 24.0;

  // ── Border radius ──
  static double radiusS(BuildContext? context) =>
      isTablet(context) ? 12.0 : 8.0;
  static double radiusM(BuildContext? context) =>
      isTablet(context) ? 16.0 : 12.0;
  static double radiusL(BuildContext? context) =>
      isTablet(context) ? 24.0 : 16.0;
  static double radiusXL(BuildContext? context) =>
      isTablet(context) ? 32.0 : 24.0;
  static double radiusXXL(BuildContext? context) =>
      isTablet(context) ? 40.0 : 30.0;
  static double radiusRound(BuildContext? context) => 100.0; // Round es round

  // ── Tamaños de botones ──
  static double buttonHeight(BuildContext? context) =>
      isTablet(context) ? 72.0 : 56.0;
  static double buttonHeightSmall(BuildContext? context) =>
      isTablet(context) ? 56.0 : 44.0;
  static double buttonHeightLarge(BuildContext? context) =>
      isTablet(context) ? 80.0 : 64.0;
  static double buttonIconSize(BuildContext? context) =>
      isTablet(context) ? 32.0 : 24.0;

  // ── Tamaños de íconos ──
  static double iconSizeS(BuildContext? context) =>
      isTablet(context) ? 24.0 : 16.0;
  static double iconSizeM(BuildContext? context) =>
      isTablet(context) ? 32.0 : 24.0;
  static double iconSizeL(BuildContext? context) =>
      isTablet(context) ? 48.0 : 32.0;
  static double iconSizeXL(BuildContext? context) =>
      isTablet(context) ? 64.0 : 48.0;
  static double iconSizeXXL(BuildContext? context) =>
      isTablet(context) ? 80.0 : 64.0;

  // ── Tamaños de avatar ──
  static double avatarSizeS(BuildContext? context) =>
      isTablet(context) ? 48.0 : 32.0;
  static double avatarSizeM(BuildContext? context) =>
      isTablet(context) ? 64.0 : 48.0;
  static double avatarSizeL(BuildContext? context) =>
      isTablet(context) ? 96.0 : 64.0;
  static double avatarSizeXL(BuildContext? context) =>
      isTablet(context) ? 128.0 : 96.0;

  // ── Tamaños de fuente ──
  static double fontSizeXS(BuildContext? context) =>
      isTablet(context) ? 14.0 : 10.0;
  static double fontSizeS(BuildContext? context) =>
      isTablet(context) ? 16.0 : 12.0;
  static double fontSizeM(BuildContext? context) =>
      isTablet(context) ? 18.0 : 14.0;
  static double fontSizeL(BuildContext? context) =>
      isTablet(context) ? 22.0 : 16.0;
  static double fontSizeXL(BuildContext? context) =>
      isTablet(context) ? 28.0 : 20.0;
  static double fontSizeXXL(BuildContext? context) =>
      isTablet(context) ? 32.0 : 24.0;
  static double fontSizeTitle(BuildContext? context) =>
      isTablet(context) ? 40.0 : 28.0;
  static double fontSizeDisplay(BuildContext? context) =>
      isTablet(context) ? 48.0 : 36.0;
  static double fontSizeHero(BuildContext? context) =>
      isTablet(context) ? 64.0 : 48.0;

  // ── Rueda de letras ──
  static double letterWheelSize(BuildContext? context) =>
      isTablet(context) ? 400.0 : 280.0;
  static double letterCircleSize(BuildContext? context) =>
      isTablet(context) ? 48.0 : 36.0;
  static double letterFontSize(BuildContext? context) =>
      isTablet(context) ? 22.0 : 18.0;

  // ── Teclado personalizado ──
  static double keyboardKeySize(BuildContext? context) =>
      isTablet(context) ? 56.0 : 36.0;
  static double keyboardKeySpacing(BuildContext? context) =>
      isTablet(context) ? 8.0 : 4.0;
  static double keyboardHeight(BuildContext? context) =>
      isTablet(context) ? 280.0 : 180.0;

  // ── Elevaciones / sombras ──
  static double elevationS(BuildContext? context) => 2.0;
  static double elevationM(BuildContext? context) => 4.0;
  static double elevationL(BuildContext? context) => 8.0;
  static double elevationXL(BuildContext? context) => 12.0;

  // ── Cards ──
  static double cardPadding(BuildContext? context) =>
      isTablet(context) ? 24.0 : 16.0;
  static double cardRadius(BuildContext? context) =>
      isTablet(context) ? 24.0 : 16.0;
  static double cardElevation(BuildContext? context) => 4.0;

  // ── Pantalla de respuesta / timer ──
  static double timerSize(BuildContext? context) =>
      isTablet(context) ? 180.0 : 120.0;
  static double timerStrokeWidth(BuildContext? context) =>
      isTablet(context) ? 12.0 : 8.0;

  // ── Scoreboard ──
  static double scoreboardWidth(BuildContext? context) =>
      isTablet(context) ? 220.0 : 140.0;
  static double scoreboardRowHeight(BuildContext? context) =>
      isTablet(context) ? 48.0 : 32.0;

  // ── Power-ups ──
  static double powerUpSize(BuildContext? context) =>
      isTablet(context) ? 64.0 : 48.0;
  static double powerUpIconSize(BuildContext? context) =>
      isTablet(context) ? 40.0 : 28.0;

  // ── Stepper (crear sala) ──
  static double stepperButtonSize(BuildContext? context) =>
      isTablet(context) ? 56.0 : 40.0;
  static double stepperValueWidth(BuildContext? context) =>
      isTablet(context) ? 80.0 : 60.0;

  // ── Splash ──
  static double splashLogoSize(BuildContext? context) =>
      isTablet(context) ? 300.0 : 200.0;
  static double splashProgressWidth(BuildContext? context) =>
      isTablet(context) ? 300.0 : 200.0;

  // ── Máximos y mínimos de juego (constantes) ──
  static const int minPlayers = 2;
  static const int maxPlayers = 8;
  static const int defaultPlayers = 4;
  static const int minResponseTime = 15;
  static const int maxResponseTime = 60;
  static const int defaultResponseTime = 30;
  static const int maxPunishmentRecordingSeconds = 30;
  static const int splashDurationMs = 2000;
}
