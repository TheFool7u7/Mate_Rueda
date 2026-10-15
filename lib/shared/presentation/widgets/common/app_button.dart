import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Variantes visuales del botón
enum AppButtonVariant { filled, outline, social }

/// Botón reutilizable con gradiente, sombras 3D y press animation.
/// Press scale: 0.95 | Inner highlight | Bold shadow
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final LinearGradient? gradient;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final Widget? iconWidget;
  final bool isLoading;
  final bool fullWidth;
  final double? height;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.gradient,
    this.color,
    this.textColor,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  });

  const AppButton.red({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  }) : variant = AppButtonVariant.filled,
       gradient = AppColors.buttonRedGradient,
       color = null,
       textColor = null;

  const AppButton.blue({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  }) : variant = AppButtonVariant.filled,
       gradient = AppColors.buttonBlueGradient,
       color = null,
       textColor = null;

  const AppButton.green({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  }) : variant = AppButtonVariant.filled,
       gradient = AppColors.buttonGreenGradient,
       color = null,
       textColor = null;

  const AppButton.orange({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  }) : variant = AppButtonVariant.filled,
       gradient = AppColors.buttonOrangeGradient,
       color = null,
       textColor = null;

  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  }) : variant = AppButtonVariant.outline,
       gradient = null,
       textColor = null;

  const AppButton.social({
    super.key,
    required this.iconWidget,
    this.onPressed,
    this.isLoading = false,
  }) : text = '',
       variant = AppButtonVariant.social,
       gradient = null,
       color = null,
       textColor = null,
       icon = null,
       fullWidth = false,
       height = null,
       fontSize = null;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.forward();
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  void _handleTap() {
    if (widget.isLoading || widget.onPressed == null) return;
    AudioManagerService().playSfx('bubble.wav');
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,
        child: switch (widget.variant) {
          AppButtonVariant.filled => _buildFilledButton(),
          AppButtonVariant.outline => _buildOutlineButton(),
          AppButtonVariant.social => _buildSocialButton(),
        },
      ),
    );
  }

  Widget _buildFilledButton() {
    final btnGradient = widget.gradient ?? AppColors.buttonRedGradient;
    final btnHeight = widget.height ?? AppDimensions.buttonHeight(context);
    final isActive = widget.onPressed != null && !widget.isLoading;

    return Container(
      width: widget.fullWidth ? double.infinity : null,
      height: btnHeight,
      decoration: BoxDecoration(
        gradient: isActive ? btnGradient : null,
        color: isActive ? null : AppColors.textGrey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound(context)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: btnGradient.colors.last.withValues(alpha: 0.45),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound(context)),
        child: Stack(
          children: [
            // Inner highlight (top gleam)
            if (isActive)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: btnHeight * 0.45,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (widget.isLoading || widget.onPressed == null) ? null : _handleTap,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusRound(context),
                ),
                splashColor: Colors.white.withValues(alpha: 0.15),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: widget.fullWidth
                              ? MainAxisSize.max
                              : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 22),
                              SizedBox(width: AppDimensions.spacingS(context)),
                            ],
                            if (widget.iconWidget != null) ...[
                              widget.iconWidget!,
                              SizedBox(width: AppDimensions.spacingS(context)),
                            ],
                            Text(
                              widget.text,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize:
                                    widget.fontSize ??
                                    AppDimensions.fontSizeL(context),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton() {
    final borderColor = widget.color ?? AppColors.primaryBlue;
    final btnHeight = widget.height ?? AppDimensions.buttonHeight(context);

    return Container(
      width: widget.fullWidth ? double.infinity : null,
      height: btnHeight,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound(context)),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (widget.isLoading || widget.onPressed == null) ? null : _handleTap,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusRound(context),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: borderColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: widget.fullWidth
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: borderColor, size: 22),
                        SizedBox(width: AppDimensions.spacingS(context)),
                      ],
                      Text(
                        widget.text,
                        style: GoogleFonts.nunito(
                          color: borderColor,
                          fontSize:
                              widget.fontSize ??
                              AppDimensions.fontSizeL(context),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: (widget.isLoading || widget.onPressed == null) ? null : _handleTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : widget.iconWidget ?? Icon(widget.icon, size: 28),
          ),
        ),
      ),
    );
  }
}
