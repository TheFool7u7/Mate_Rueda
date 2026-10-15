import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';

/// Datos de un power-up
class PowerUpData {
  final String assetPath;
  final String label;
  final int count;
  final Color accentColor;

  const PowerUpData({
    required this.assetPath,
    required this.label,
    required this.count,
    required this.accentColor,
  });
}

/// Barra de power-ups del juego.
/// Muestra 4 botones con emoji, conteo y tooltip.
class PowerUpsWidget extends StatelessWidget {
  final void Function(String powerUpType)? onPowerUpTap;
  final bool enabled;

  const PowerUpsWidget({super.key, this.onPowerUpTap, this.enabled = true});

  // Power-ups disponibles
  static const _powerUps = [
    PowerUpData(
      assetPath: 'assets/icons/snowflake.svg',
      label: 'Congelar',
      count: 3,
      accentColor: Color(0xFF00BCD4),
    ),
    PowerUpData(
      assetPath: 'assets/icons/bomb.svg',
      label: 'Bomba',
      count: 5,
      accentColor: Color(0xFFFF5722),
    ),
    PowerUpData(
      assetPath: 'assets/icons/dice.svg',
      label: 'Dado',
      count: 2,
      accentColor: Color(0xFF9C27B0),
    ),
    PowerUpData(
      assetPath: 'assets/icons/joker.svg',
      label: 'Comodín',
      count: 7,
      accentColor: Color(0xFFFFC107),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _powerUps.map((powerUp) {
          return Padding(
            padding: EdgeInsets.only(right: AppDimensions.spacingXS(context)),
            child: _PowerUpButton(
              data: powerUp,
              onTap: enabled ? () => onPowerUpTap?.call(powerUp.label) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Botón individual de power-up con emoji y badge de conteo
class _PowerUpButton extends StatelessWidget {
  final PowerUpData data;
  final VoidCallback? onTap;

  const _PowerUpButton({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: data.label,
        child: Container(
          width: AppDimensions.powerUpSize(context),
          height: AppDimensions.powerUpSize(context),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
            border: Border.all(
              color: data.accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: data.accentColor.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // SVG centrado
              Center(
                child: SvgPicture.asset(data.assetPath, width: 32, height: 32),
              ),
              // Badge con conteo
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: data.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.accentColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${data.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
