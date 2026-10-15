import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/features/game/data/realtime_db_service.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

// ── Screens ──
import 'package:wordwonderslink/features/splash/presentation/screens/splash_screen.dart';
import 'package:wordwonderslink/features/auth/presentation/screens/login_screen.dart';
import 'package:wordwonderslink/features/auth/presentation/screens/register_screen.dart';
import 'package:wordwonderslink/features/auth/presentation/screens/change_password_screen.dart';
import 'package:wordwonderslink/features/home/presentation/screens/home_screen.dart';
import 'package:wordwonderslink/features/room/presentation/screens/create_room_screen.dart';
import 'package:wordwonderslink/features/room/presentation/screens/join_room_screen.dart';
import 'package:wordwonderslink/features/room/presentation/screens/lobby_screen.dart';
import 'package:wordwonderslink/features/game/presentation/screens/game_screen.dart';
import 'package:wordwonderslink/features/game/presentation/screens/answering_screen.dart';
import 'package:wordwonderslink/features/evaluation/presentation/screens/evaluation_screen.dart';
import 'package:wordwonderslink/features/punishment/presentation/screens/punishment_screen.dart';
import 'package:wordwonderslink/features/results/presentation/screens/results_screen.dart';
import 'package:wordwonderslink/settings/presentation/screens/settings_screen.dart';
import 'package:wordwonderslink/features/challenge/presentation/screens/math_challenge_demo_screen.dart';

/// Rutas con nombre para navegación segura.
/// Las pantallas de juego obtienen el roomCode del Provider, no de la URL.
class AppRoutes {
  AppRoutes._();

  // ── Públicas (sin auth) ──
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // ── Protegidas (requieren auth) ──
  static const String home = '/home';
  static const String createRoom = '/create-room';
  static const String joinRoom = '/join-room';
  static const String lobby = '/lobby';
  static const String game = '/game';
  static const String answering = '/answering';
  static const String evaluation = '/evaluation';
  static const String punishment = '/punishment';
  static const String results = '/results';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';

  // ── MateRueda ──
  /// Reto matemático en modo demo local (sin Firebase).
  static const String reto = '/reto';

  /// Ruta inicial; se puede cambiar con
  /// `flutter run --dart-define=INITIAL_ROUTE=/`
  static const String initial = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: reto,
  );

  /// Rutas que NO requieren autenticación
  static const _publicRoutes = {splash, login, register, reto};

  /// Verifica si una ruta es pública
  static bool isPublicRoute(String path) => _publicRoutes.contains(path);
}

/// Configuración centralizada de GoRouter con auth guards.
///
/// El redirect funciona así:
/// 1. Si estamos en splash → dejar pasar (la verificación la hace SplashScreen)
/// 2. Si NO hay sesión y la ruta es protegida → redirigir a /login
/// 3. Si SÍ hay sesión y la ruta es login/register → redirigir a /home
/// 4. En cualquier otro caso → dejar pasar
class SfxNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      AudioManagerService().playSfx('whoosh.wav');
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      AudioManagerService().playSfx('whoosh.wav');
    }
    super.didPop(route, previousRoute);
  }
}

class AppRouter {
  AppRouter._();

  /// Crea el GoRouter con redirect reactivo basado en AuthProvider y GameProvider.
  static GoRouter createRouter(
    AuthProvider authProvider,
    GameProvider gameProvider,
  ) {
    return GoRouter(
      initialLocation: AppRoutes.initial,
      debugLogDiagnostics: true,
      observers: [SfxNavigatorObserver()],

      // ══════════════════════════════════════
      // REDIRECT / AUTH & GAME GUARD
      // ══════════════════════════════════════
      refreshListenable: Listenable.merge([authProvider, gameProvider]),
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final currentPath = state.matchedLocation;

        // 1. Splash: siempre permitir (maneja su propia lógica)
        if (currentPath == AppRoutes.splash) return null;

        // 2. No autenticado → redirigir a login (si ruta protegida)
        if (!isLoggedIn && !AppRoutes.isPublicRoute(currentPath)) {
          return AppRoutes.login;
        }

        // 3. Autenticado → redirigir a home (si en login/register)
        if (isLoggedIn &&
            (currentPath == AppRoutes.login ||
                currentPath == AppRoutes.register)) {
          return AppRoutes.home;
        }

        // 4. Lógica de Fases del Juego
        const gameRoutes = [
          AppRoutes.game,
          AppRoutes.answering,
          AppRoutes.evaluation,
          AppRoutes.punishment,
          AppRoutes.results,
        ];

        if (gameRoutes.contains(currentPath)) {
          final phase = gameProvider.currentPhase;
          final isMyTurn = gameProvider.isMyTurn(authProvider.currentUid ?? '');

          switch (phase) {
            case GamePhase.selecting:
              if (currentPath != AppRoutes.game) return AppRoutes.game;
              break;
            case GamePhase.answering:
              if (isMyTurn) {
                if (currentPath != AppRoutes.answering)
                  return AppRoutes.answering;
              } else {
                if (currentPath != AppRoutes.game) return AppRoutes.game;
              }
              break;
            case GamePhase.evaluating:
              if (currentPath != AppRoutes.evaluation)
                return AppRoutes.evaluation;
              break;
            case GamePhase.punishment:
              // Permitir /results ademas de /punishment:
              // el usuario puede presionar "Ver resultados" manualmente
              // para navegar sin esperar el countdown del host.
              if (currentPath != AppRoutes.punishment &&
                  currentPath != AppRoutes.results) {
                return AppRoutes.punishment;
              }
              break;
            case GamePhase.results:
              // No redirigir automáticamente desde /punishment:
              // cada usuario navega a resultados manualmente con el botón.
              if (currentPath != AppRoutes.results &&
                  currentPath != AppRoutes.punishment) {
                return AppRoutes.results;
              }
              break;
          }
        }

        // 5. Sin cambios
        return null;
      },

      // ══════════════════════════════════════
      // DEFINICIÓN DE RUTAS
      // ══════════════════════════════════════
      routes: [
        // ── Splash ──
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Auth (públicas) ──
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // ── Auth (protegidas) ──
        GoRoute(
          path: AppRoutes.changePassword,
          name: 'changePassword',
          builder: (context, state) => const ChangePasswordScreen(),
        ),

        // ── Home ──
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),

        // ── Room ──
        GoRoute(
          path: AppRoutes.createRoom,
          name: 'createRoom',
          builder: (context, state) => const CreateRoomScreen(),
        ),
        GoRoute(
          path: AppRoutes.joinRoom,
          name: 'joinRoom',
          builder: (context, state) => const JoinRoomScreen(),
        ),
        GoRoute(
          path: AppRoutes.lobby,
          name: 'lobby',
          builder: (context, state) => const LobbyScreen(),
        ),

        // ── Game ──
        GoRoute(
          path: AppRoutes.game,
          name: 'game',
          builder: (context, state) => const GameScreen(),
        ),
        GoRoute(
          path: AppRoutes.answering,
          name: 'answering',
          builder: (context, state) => const AnsweringScreen(),
        ),
        GoRoute(
          path: AppRoutes.evaluation,
          name: 'evaluation',
          builder: (context, state) => const EvaluationScreen(),
        ),
        GoRoute(
          path: AppRoutes.punishment,
          name: 'punishment',
          builder: (context, state) => const PunishmentScreen(),
        ),
        GoRoute(
          path: AppRoutes.results,
          name: 'results',
          builder: (context, state) => const ResultsScreen(),
        ),

        // ── MateRueda: Reto matemático (demo local) ──
        GoRoute(
          path: AppRoutes.reto,
          name: 'reto',
          builder: (context, state) => const MathChallengeDemoScreen(),
        ),

        // ── Settings ──
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],

      // ══════════════════════════════════════
      // ERROR 404
      // ══════════════════════════════════════
      errorBuilder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFFE8EDF5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home),
                label: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Router estático para acceso sin auth (usado por el widget test)
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
}
