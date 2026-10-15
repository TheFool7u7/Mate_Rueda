import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';

/// Campo de texto pill-shaped con estilo game-show.
/// White pill card, blue border cuando focused, prefixIcon en círculo de color.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.prefixIconColor,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
  });

  const AppTextField.email({
    super.key,
    this.controller,
    this.label = 'Correo electrónico',
    this.hintText = 'tucorreo@ejemplo.com',
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
  }) : prefixIcon = Icons.email_outlined,
       prefixIconColor = AppColors.primaryBlue,
       isPassword = false,
       keyboardType = TextInputType.emailAddress,
       maxLines = 1,
       textCapitalization = TextCapitalization.none;

  const AppTextField.password({
    super.key,
    this.controller,
    this.label = 'Contraseña',
    this.hintText = '••••••••••',
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
  }) : prefixIcon = Icons.lock_outline,
       prefixIconColor = AppColors.textGrey,
       isPassword = true,
       keyboardType = TextInputType.visiblePassword,
       maxLines = 1,
       textCapitalization = TextCapitalization.none;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.prefixIconColor ?? AppColors.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              widget.label!,
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeM(context),
                fontWeight: FontWeight.w700,
                color: _isFocused ? AppColors.primaryBlue : AppColors.textDark,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusXXL(context),
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppColors.primaryBlue.withValues(alpha: 0.15)
                    : AppColors.shadowLight,
                offset: const Offset(0, 4),
                blurRadius: _isFocused ? 12 : 6,
                spreadRadius: 0,
              ),
              const BoxShadow(
                color: Colors.white,
                offset: Offset(0, -1),
                blurRadius: 1,
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            textCapitalization: widget.textCapitalization,
            textInputAction: widget.textInputAction,
            style: GoogleFonts.nunito(
              fontSize: AppDimensions.fontSizeL(context),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.nunito(
                color: AppColors.textLight,
                fontSize: AppDimensions.fontSizeM(context),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 56,
                minHeight: 56,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL(context),
                vertical: AppDimensions.spacingL(context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusXXL(context),
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusXXL(context),
                ),
                borderSide: const BorderSide(
                  color: AppColors.dividerColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusXXL(context),
                ),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusXXL(context),
                ),
                borderSide: const BorderSide(
                  color: AppColors.primaryRed,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusXXL(context),
                ),
                borderSide: const BorderSide(
                  color: AppColors.primaryRed,
                  width: 2.5,
                ),
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
