import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';

import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de splash con logo animado y verificación de sesión.
/// Duración ~2 segundos, luego navega a Login o Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _dotsController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    // Animación del logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoController.forward();

    // Animación de dots
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.initialize();

    // Esperar la animación del splash
    await Future.delayed(
      const Duration(milliseconds: AppDimensions.splashDurationMs),
    );

    if (!mounted) return;

    // Navegar según el estado de autenticación
    if (authProvider.isLoggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(scale: _logoScale.value, child: child),
                );
              },
              child: _buildLogo(),
            ),

            SizedBox(height: AppDimensions.spacingXXL(context)),

            // Subtítulo
            FadeTransition(
              opacity: _logoOpacity,
              child: Text(
                AppStrings.splashSubtitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL(context),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SizedBox(height: AppDimensions.spacingXXXL(context)),

            // Dots animados de carga
            _buildAnimatedDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset('assets/images/logo.png', height: 120);
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = ((_dotsController.value + delay) % 1.0);
            final scale = 0.5 + (0.5 * _dotCurve(animValue));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue.withValues(
                      alpha: 0.3 + (0.7 * _dotCurve(animValue)),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _dotCurve(double t) {
    // Curva suave para los dots
    if (t < 0.5) return 2 * t;
    return 2 * (1 - t);
  }
}
