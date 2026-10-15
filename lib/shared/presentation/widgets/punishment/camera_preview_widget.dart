import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';

/// Widget de preview de cámara para pantallas de castigo.
/// Muestra la vista en vivo de la cámara con controles opcionales.
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final File? capturedImage;
  final VoidCallback? onCapture;
  final VoidCallback? onRetake;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onFlash;
  final bool showReticle;
  final String? reticleLabel;
  final bool canSwitchCamera;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.capturedImage,
    this.onCapture,
    this.onRetake,
    this.onSwitchCamera,
    this.onFlash,
    this.showReticle = false,
    this.reticleLabel,
    this.canSwitchCamera = true,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay una foto capturada, mostrarla en vez del preview
    if (capturedImage != null) {
      return _buildCapturedView(context);
    }

    // Si el controller no está listo, mostrar placeholder
    if (controller == null || !controller!.value.isInitialized) {
      return _buildPlaceholder(context);
    }

    return _buildCameraPreview(context);
  }

  /// Vista del preview de cámara en vivo
  Widget _buildCameraPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
      child: Stack(
        children: [
          // Preview de cámara
          SizedBox(
            width: double.infinity,
            height: 400,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.previewSize?.height ?? 400,
                height: controller!.value.previewSize?.width ?? 300,
                child: CameraPreview(controller!),
              ),
            ),
          ),

          // Reticle/diana para "encontrar color"
          if (showReticle) _buildReticle(context),

          // Controles superiores (flash, cambiar cámara)
          Positioned(
            top: AppDimensions.spacingM(context),
            left: AppDimensions.spacingM(context),
            right: AppDimensions.spacingM(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash
                if (onFlash != null)
                  _CircleIconButton(icon: Icons.flash_auto, onTap: onFlash!),
                const Spacer(),
                // Cambiar cámara
                if (canSwitchCamera && onSwitchCamera != null)
                  _CircleIconButton(
                    icon: Icons.cameraswitch_rounded,
                    onTap: onSwitchCamera!,
                  ),
              ],
            ),
          ),

          // Botón de captura centrado abajo
          if (onCapture != null)
            Positioned(
              bottom: AppDimensions.spacingXL(context),
              left: 0,
              right: 0,
              child: Center(child: _CaptureButton(onTap: onCapture!)),
            ),
        ],
      ),
    );
  }

  /// Vista de la foto capturada con opción de retomar
  Widget _buildCapturedView(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 400,
            child: Image.file(capturedImage!, fit: BoxFit.cover),
          ),
          // Botón retomar en esquina superior derecha
          if (onRetake != null)
            Positioned(
              top: AppDimensions.spacingM(context),
              right: AppDimensions.spacingM(context),
              child: _CircleIconButton(
                icon: Icons.refresh_rounded,
                onTap: onRetake!,
                color: AppColors.primaryRed,
              ),
            ),
          // Indicador de foto tomada
          Positioned(
            bottom: AppDimensions.spacingXL(context),
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL(context),
                  vertical: AppDimensions.spacingS(context),
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusRound(context),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 18),
                    SizedBox(width: AppDimensions.spacingXS(context)),
                    Text(
                      '¡Foto tomada!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: AppDimensions.fontSizeM(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Diana/reticle para el castigo "encontrar color"
  Widget _buildReticle(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Diana circular
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            if (reticleLabel != null) ...[
              SizedBox(height: AppDimensions.spacingS(context)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM(context),
                  vertical: AppDimensions.spacingXS(context),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusRound(context),
                  ),
                ),
                child: Text(
                  reticleLabel!,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimensions.fontSizeM(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Placeholder cuando la cámara no está lista
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
            SizedBox(height: AppDimensions.spacingS(context)),
            Text(
              'Iniciando cámara...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular de captura de foto (estilo iOS)
class _CaptureButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CaptureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Botón circular con ícono (flash, cambiar cámara, retomar)
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? Colors.black).withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
