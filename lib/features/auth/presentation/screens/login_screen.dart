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

/// Pantalla de inicio de sesión.
/// Email/contraseña + botón social Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();
    if (success && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: AppStrings.loggingIn,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
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
                          SizedBox(height: AppDimensions.spacingXXXL(context)),

                          // Header
                          _buildHeader(),

                          SizedBox(height: AppDimensions.spacingXXXL(context)),

                          // Formulario
                          _buildForm(authProvider),

                          SizedBox(height: AppDimensions.spacingXL(context)),

                          // Separador "O inicia sesión con"
                          _buildDivider(),

                          SizedBox(height: AppDimensions.spacingXL(context)),

                          // Botones sociales
                          _buildSocialButtons(),

                          SizedBox(height: AppDimensions.spacingXXL(context)),

                          // Link a registro
                          _buildRegisterLink(),

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

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with radial glow halo
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.08),
                    AppColors.primaryBlue.withValues(alpha: 0.0),
                  ],
                  radius: 0.85,
                ),
              ),
            ),
            Image.asset('assets/images/logo.png', height: 120),
          ],
        ),
        SizedBox(height: AppDimensions.spacingM(context)),
        Text(
          AppStrings.welcomeBack,
          style: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeXXL(context),
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.spacingXS(context)),
        Text(
          AppStrings.loginSubtitle,
          style: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeM(context),
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField.email(
            controller: _emailController,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),

          SizedBox(height: AppDimensions.spacingL(context)),

          AppTextField.password(
            controller: _passwordController,
            validator: Validators.password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
          ),

          // Olvidé mi contraseña
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(authProvider),
              child: Text(
                AppStrings.forgotPassword,
                style: GoogleFonts.nunito(
                  color: AppColors.primaryBlue,
                  fontSize: AppDimensions.fontSizeS(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Error message
          if (authProvider.errorMessage != null) ...[
            SizedBox(height: AppDimensions.spacingS(context)),
            Container(
              padding: EdgeInsets.all(AppDimensions.spacingM(context)),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
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
                  SizedBox(width: AppDimensions.spacingS(context)),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage!,
                      style: GoogleFonts.nunito(
                        color: AppColors.primaryRed,
                        fontSize: AppDimensions.fontSizeS(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: AppDimensions.spacingXL(context)),

          // Botón login
          AppButton.red(text: AppStrings.login, onPressed: _handleLogin),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.dividerColor)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM(context),
          ),
          child: Text(
            AppStrings.orLoginWith,
            style: GoogleFonts.nunito(
              color: AppColors.textGrey,
              fontSize: AppDimensions.fontSizeS(context),
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.dividerColor)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return GestureDetector(
      onTap: _handleGoogleLogin,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusRound(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryRed,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Iniciar con Google',
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeM(context),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.noAccount,
          style: GoogleFonts.nunito(
            color: AppColors.textGrey,
            fontSize: AppDimensions.fontSizeM(context),
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.register),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            AppStrings.createAccount,
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
    );
  }

  void _showForgotPasswordDialog(AuthProvider authProvider) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusXL(context),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Blue top stripe
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusXL(context)),
                    topRight: Radius.circular(AppDimensions.radiusXL(context)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Recuperar contraseña',
                      style: GoogleFonts.nunito(
                        fontSize: AppDimensions.fontSizeL(context),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                      style: GoogleFonts.nunito(
                        fontSize: AppDimensions.fontSizeS(context),
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(height: 20),
                    AppTextField.email(
                      controller: emailController,
                      label: 'Tu correo registrado',
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primaryBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusRound(context),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await authProvider.sendPasswordReset(
                                emailController.text,
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(AppStrings.resetEmailSent),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusRound(context),
                                ),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Enviar',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
