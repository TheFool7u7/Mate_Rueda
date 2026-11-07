import 'package:firebase_core/firebase_core.dart';
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
import 'package:wordwonderslink/firebase_options.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Punto de entrada de MateRueda (soporta modo 1 dispositivo sin internet y
/// modo varios dispositivos con Firebase).
///
/// Ejecutar con: `flutter run -t lib/main_demo.dart` (o `flutter run`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase no inicializado (modo local sigue disponible): $e');
  }
  await AudioManagerService().init();
  runApp(const MateRuedaDemoApp());
}

/// App principal de MateRueda.
class MateRuedaDemoApp extends StatefulWidget {
  const MateRuedaDemoApp({
    super.key,
    this.splashDuration,
    this.controller,
  });

  /// Permite acortar el splash (útil en pruebas).
  final Duration? splashDuration;

  /// Controlador externo opcional (útil para pruebas multidispositivo).
  final LocalGameController? controller;

  @override
  State<MateRuedaDemoApp> createState() => _MateRuedaDemoAppState();
}

class _MateRuedaDemoAppState extends State<MateRuedaDemoApp> {
  late final LocalGameController _game =
      widget.controller ?? LocalGameController();
  late final bool _ownsController = widget.controller == null;

  late final GoRouter _router = GoRouter(
    initialLocation: LocalRoutes.splash,
    refreshListenable: _game,
    redirect: (context, state) {
      if (!_game.isOnline) return null;
      final target = switch (_game.phase) {
        LocalPhase.lobby => LocalRoutes.lobby,
        LocalPhase.spinning => LocalRoutes.spin,
        LocalPhase.challenge => LocalRoutes.challenge,
        LocalPhase.feedback => LocalRoutes.feedback,
        LocalPhase.results => LocalRoutes.results,
      };
      final loc = state.matchedLocation;
      const onlineRoutes = {
        LocalRoutes.setup,
        LocalRoutes.join,
        LocalRoutes.lobby,
        LocalRoutes.spin,
        LocalRoutes.challenge,
        LocalRoutes.feedback,
        LocalRoutes.results,
      };
      if (onlineRoutes.contains(loc) && loc != target) return target;
      return null;
    },
    routes: [
      GoRoute(
        path: LocalRoutes.splash,
        builder: (_, __) => widget.splashDuration == null
            ? const LocalSplashScreen()
            : LocalSplashScreen(duration: widget.splashDuration!),
      ),
      GoRoute(
        path: LocalRoutes.menu,
        builder: (_, __) => const LocalMenuScreen(),
      ),
      GoRoute(
        path: LocalRoutes.setup,
        builder: (_, __) => const LocalSetupScreen(),
      ),
      GoRoute(
        path: LocalRoutes.join,
        builder: (_, __) => const LocalJoinScreen(),
      ),
      GoRoute(
        path: LocalRoutes.lobby,
        builder: (_, __) => const LocalLobbyScreen(),
      ),
      GoRoute(
        path: LocalRoutes.spin,
        builder: (_, __) => const LocalSpinScreen(),
      ),
      GoRoute(
        path: LocalRoutes.challenge,
        builder: (_, __) => const LocalChallengeScreen(),
      ),
      GoRoute(
        path: LocalRoutes.feedback,
        builder: (_, __) => const LocalFeedbackScreen(),
      ),
      GoRoute(
        path: LocalRoutes.results,
        builder: (_, __) => const LocalResultsScreen(),
      ),
    ],
  );

  @override
  void dispose() {
    if (_ownsController) _game.dispose();
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
