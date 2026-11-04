import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/local_game/presentation/local_routes.dart';
import 'package:wordwonderslink/features/local_game/presentation/screens/local_challenge_feedback_screens.dart';
import 'package:wordwonderslink/features/local_game/presentation/screens/local_intro_screens.dart';
import 'package:wordwonderslink/features/local_game/presentation/screens/local_results_screen.dart';
import 'package:wordwonderslink/features/local_game/presentation/screens/local_spin_screen.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Punto de entrada del modo DEMO (sin Firebase).
///
/// Ejecutar con: `flutter run -t lib/main_demo.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await AudioManagerService().init();
  runApp(const MateRuedaDemoApp());
}

/// App MateRueda en modo demo local: una sola partida en un dispositivo,
/// sin autenticación ni conexión a internet.
class MateRuedaDemoApp extends StatefulWidget {
  const MateRuedaDemoApp({super.key, this.splashDuration});

  /// Permite acortar el splash (útil en pruebas).
  final Duration? splashDuration;

  @override
  State<MateRuedaDemoApp> createState() => _MateRuedaDemoAppState();
}

class _MateRuedaDemoAppState extends State<MateRuedaDemoApp> {
  late final LocalGameController _game = LocalGameController();
  late final GoRouter _router = GoRouter(
    initialLocation: LocalRoutes.splash,
    routes: [
      GoRoute(
        path: LocalRoutes.splash,
        builder: (_, __) => widget.splashDuration == null
            ? const LocalSplashScreen()
            : LocalSplashScreen(duration: widget.splashDuration!),
      ),
      GoRoute(path: LocalRoutes.menu, builder: (_, __) => const LocalMenuScreen()),
      GoRoute(path: LocalRoutes.setup, builder: (_, __) => const LocalSetupScreen()),
      GoRoute(path: LocalRoutes.lobby, builder: (_, __) => const LocalLobbyScreen()),
      GoRoute(path: LocalRoutes.spin, builder: (_, __) => const LocalSpinScreen()),
      GoRoute(path: LocalRoutes.challenge, builder: (_, __) => const LocalChallengeScreen()),
      GoRoute(path: LocalRoutes.feedback, builder: (_, __) => const LocalFeedbackScreen()),
      GoRoute(path: LocalRoutes.results, builder: (_, __) => const LocalResultsScreen()),
    ],
  );

  @override
  void dispose() {
    _game.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _game,
      child: MaterialApp.router(
        title: 'MateRueda',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Fredoka',
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF6A4C93),
        ),
        routerConfig: _router,
      ),
    );
  }
}
