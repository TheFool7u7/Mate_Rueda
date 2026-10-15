import 'package:flutter/material.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';

/// Overlay de carga semi-transparente que bloquea la interacción.
/// Se muestra durante operaciones asíncronas (login, envío, etc.).
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingXXL(context),
                    vertical: AppDimensions.spacingXL(context),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusXL(context),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingL(context)),
                      Text(
                        message ?? AppStrings.loading,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM(context),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
