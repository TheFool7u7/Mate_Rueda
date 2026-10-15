import 'package:flutter/material.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';

/// Teclado QWERTY personalizado en español (incluye Ñ).
/// Se desactiva cuando otro jugador está respondiendo.
class CustomKeyboardWidget extends StatelessWidget {
  final void Function(String char)? onKeyTap;
  final VoidCallback? onBackspace;
  final VoidCallback? onSubmit;
  final bool enabled;

  const CustomKeyboardWidget({
    super.key,
    this.onKeyTap,
    this.onBackspace,
    this.onSubmit,
    this.enabled = true,
  });

  // Distribución QWERTY en español
  static const _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ñ'];
  static const _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXS(context),
          vertical: AppDimensions.spacingS(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fila 1: Q-P
            _buildKeyRow(context, _row1),
            SizedBox(height: AppDimensions.keyboardKeySpacing(context)),
            // Fila 2: A-Ñ
            _buildKeyRow(context, _row2),
            // Fila 3: Z-M con backspace y enviar
            _buildBottomRow(context),
            SizedBox(height: AppDimensions.keyboardKeySpacing(context)),
            // Fila 4: Espacio
            _buildSpaceRow(context),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de teclas
  Widget _buildKeyRow(BuildContext context, List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.keyboardKeySpacing(context) / 2,
          ),
          child: _KeyButton(
            label: key,
            onTap: enabled ? () => onKeyTap?.call(key) : null,
          ),
        );
      }).toList(),
    );
  }

  /// Fila inferior con backspace, letras Z-M y botón enviar
  Widget _buildBottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tecla backspace
        _ActionKeyButton(
          icon: Icons.backspace_outlined,
          onTap: enabled ? onBackspace : null,
          color: AppColors.textGrey,
        ),
        SizedBox(width: AppDimensions.keyboardKeySpacing(context)),
        // Letras Z-M
        ..._row3.map((key) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.keyboardKeySpacing(context) / 2,
            ),
            child: _KeyButton(
              label: key,
              onTap: enabled ? () => onKeyTap?.call(key) : null,
            ),
          );
        }),
        SizedBox(width: AppDimensions.keyboardKeySpacing(context)),
        // Tecla enviar
        _ActionKeyButton(
          icon: Icons.send_rounded,
          onTap: enabled ? onSubmit : null,
          color: AppColors.primaryBlue,
          isAccent: true,
        ),
      ],
    );
  }

  /// Fila de espacio ancha
  Widget _buildSpaceRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: enabled ? () => onKeyTap?.call(' ') : null,
          child: Container(
            // 40% del ancho aproximado o un ancho fijo grande
            width: 200,
            height: AppDimensions.keyboardKeySize(context) + 6,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusS(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(0, 2),
                  blurRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(0, -0.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ESPACIO',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tecla individual del teclado (letra)
class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _KeyButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.keyboardKeySize(context),
        height: AppDimensions.keyboardKeySize(context) + 6,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS(context)),
          boxShadow: [
            // Sombra 3D inferior
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 2),
              blurRadius: 1,
            ),
            // Borde de luz superior
            const BoxShadow(
              color: Colors.white,
              offset: Offset(0, -0.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tecla de acción (backspace, enviar)
class _ActionKeyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool isAccent;

  const _ActionKeyButton({
    required this.icon,
    this.onTap,
    required this.color,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.keyboardKeySize(context) + 12,
        height: AppDimensions.keyboardKeySize(context) + 6,
        decoration: BoxDecoration(
          color: isAccent ? color : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS(context)),
          boxShadow: [
            BoxShadow(
              color: isAccent
                  ? color.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 2),
              blurRadius: isAccent ? 4 : 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: isAccent ? Colors.white : color, size: 20),
        ),
      ),
    );
  }
}
