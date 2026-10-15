import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/core/utils/validators.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_text_field.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/loading_overlay.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de registro de nuevo usuario.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerWithEmail(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: AppStrings.creatingAccount,
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
                'Crear Cuenta',
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
                          SizedBox(height: AppDimensions.spacingL(context)),

                          // Header with icon badge
                          Column(
                            children: [
                              // Person icon badge
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.primaryBlue.withValues(
                                        alpha: 0.75,
                                      ),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              SizedBox(height: AppDimensions.spacingM(context)),
                              Text(
                                AppStrings.createAccountTitle,
                                style: GoogleFonts.nunito(
                                  fontSize: AppDimensions.fontSizeXXL(context),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(
                                height: AppDimensions.spacingXS(context),
                              ),
                              Text(
                                AppStrings.registerSubtitle,
                                style: GoogleFonts.nunito(
                                  fontSize: AppDimensions.fontSizeM(context),
                                  color: AppColors.textGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          SizedBox(height: AppDimensions.spacingXXL(context)),

                          // Formulario
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                AppTextField(
                                  controller: _usernameController,
                                  label: AppStrings.usernameLabel,
                                  hintText: AppStrings.usernameHint,
                                  prefixIcon: Icons.person_outline,
                                  prefixIconColor: AppColors.accentGreen,
                                  validator: Validators.username,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),

                                AppTextField.email(
                                  controller: _emailController,
                                  validator: Validators.email,
                                  textInputAction: TextInputAction.next,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),

                                AppTextField.password(
                                  controller: _passwordController,
                                  validator: Validators.password,
                                  textInputAction: TextInputAction.next,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),

                                AppTextField.password(
                                  controller: _confirmPasswordController,
                                  label: AppStrings.confirmPasswordLabel,
                                  validator: (value) =>
                                      Validators.confirmPassword(
                                        value,
                                        _passwordController.text,
                                      ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleRegister(),
                                ),

                                // Error message
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

                                // Botón registrarse
                                AppButton.orange(
                                  text: AppStrings.register,
                                  icon: Icons.person_add_alt_1,
                                  onPressed: _handleRegister,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: AppDimensions.spacingXL(context)),

                          // Link a login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.haveAccount,
                                style: GoogleFonts.nunito(
                                  color: AppColors.textGrey,
                                  fontSize: AppDimensions.fontSizeM(context),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.pop(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  AppStrings.loginHere,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primaryBlue,
                                    fontSize: AppDimensions.fontSizeM(context),
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: AppDimensions.spacingXL(context)),
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
