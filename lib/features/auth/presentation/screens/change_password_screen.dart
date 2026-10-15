import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/core/utils/validators.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_text_field.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/loading_overlay.dart';

/// Pantalla para cambiar contraseña del usuario actual.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.passwordChanged),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
                onPressed: () => context.pop(),
              ),
              title: Text(
                AppStrings.changePassword,
                style: GoogleFonts.nunito(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: AppDimensions.fontSizeL(context),
                ),
              ),
              centerTitle: true,
            ),
            body: AppBackground(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPadding(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: AppDimensions.spacingXXL(context)),

                          // Lock icon badge — larger circle with blue gradient
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryBlue,
                                    AppColors.primaryBlue.withValues(
                                      alpha: 0.72,
                                    ),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.38,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.lock_reset,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(height: AppDimensions.spacingXXL(context)),

                          // Formulario
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                AppTextField.password(
                                  controller: _currentPasswordController,
                                  label: AppStrings.currentPassword,
                                  textInputAction: TextInputAction.next,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),

                                AppTextField.password(
                                  controller: _newPasswordController,
                                  label: AppStrings.newPassword,
                                  validator: Validators.password,
                                  textInputAction: TextInputAction.next,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),

                                AppTextField.password(
                                  controller: _confirmPasswordController,
                                  label: AppStrings.confirmNewPassword,
                                  validator: (value) =>
                                      Validators.confirmPassword(
                                        value,
                                        _newPasswordController.text,
                                      ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleChangePassword(),
                                ),

                                // Error
                                if (authProvider.errorMessage != null) ...[
                                  SizedBox(
                                    height: AppDimensions.spacingL(context),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(
                                      AppDimensions.spacingM(context),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusM(context),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppColors.primaryRed,
                                          size: 20,
                                        ),
                                        SizedBox(
                                          width: AppDimensions.spacingS(
                                            context,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            authProvider.errorMessage!,
                                            style: GoogleFonts.nunito(
                                              color: AppColors.primaryRed,
                                              fontSize: AppDimensions.fontSizeS(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(
                                  height: AppDimensions.spacingXXL(context),
                                ),

                                AppButton.blue(
                                  text: AppStrings.changePassword,
                                  icon: Icons.check,
                                  onPressed: _handleChangePassword,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
