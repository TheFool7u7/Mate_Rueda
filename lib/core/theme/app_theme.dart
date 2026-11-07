import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';

/// ThemeData global de Word Wonders Link — Estilo Game Show.
/// Usa Nunito (bold, rounded) via google_fonts.
class AppTheme {
  AppTheme._();

  static TextTheme get _nunitoTextTheme => GoogleFonts.nunitoTextTheme(
    TextTheme(
      headlineLarge: TextStyle(
        fontSize: AppDimensions.fontSizeTitle(null),
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        letterSpacing: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: AppDimensions.fontSizeXXL(null),
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      headlineSmall: TextStyle(
        fontSize: AppDimensions.fontSizeXL(null),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontSize: AppDimensions.fontSizeL(null),
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: 0.8,
      ),
      titleMedium: TextStyle(
        fontSize: AppDimensions.fontSizeM(null),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      labelLarge: TextStyle(
        fontSize: AppDimensions.fontSizeL(null),
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
      bodyLarge: TextStyle(
        fontSize: AppDimensions.fontSizeL(null),
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: AppDimensions.fontSizeM(null),
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      bodySmall: TextStyle(
        fontSize: AppDimensions.fontSizeS(null),
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
      ),
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundColor,

      // ── Esquema de colores ──
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryRed,
        tertiary: AppColors.accentGold,
        surface: AppColors.cardWhite,
        error: AppColors.primaryRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDark,
        onError: Colors.white,
      ),

      // ── Tipografía Nunito ──
      textTheme: _nunitoTextTheme,
      fontFamily: GoogleFonts.nunito().fontFamily,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.fontSizeXL(null),
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: 0.8,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL(null)),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL(null),
          vertical: AppDimensions.spacingS(null),
        ),
        shadowColor: AppColors.shadowBlue,
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primaryRed.withValues(alpha: 0.4),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight(null)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusRound(null),
            ),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeL(null),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(color: AppColors.primaryBlue, width: 2),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight(null)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusRound(null),
            ),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeL(null),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXL(null),
          vertical: AppDimensions.spacingL(null),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL(null)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL(null)),
          borderSide: BorderSide(color: AppColors.dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL(null)),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL(null)),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL(null)),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2.5),
        ),
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textLight,
          fontSize: AppDimensions.fontSizeM(null),
        ),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationL(null),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL(null)),
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.fontSizeXL(null),
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        elevation: 20,
        shadowColor: AppColors.shadowBlue,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.textGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlueLight;
          }
          return AppColors.dividerColor;
        }),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: AppDimensions.spacingXL(null),
      ),
    );
  }
}
