import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:wordwonderslink/firebase_options.dart';

// ── Core ──
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/core/theme/app_theme.dart';

// ── Providers ──
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/features/evaluation/presentation/providers/evaluation_provider.dart';
import 'package:wordwonderslink/features/punishment/presentation/providers/punishment_provider.dart';

// ── Navegación ──
import 'package:wordwonderslink/core/routes/app_router.dart';

// ── Servicios ──
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Punto de entrada de Word Wonders Link.
/// Inicializa Firebase, configura los providers y lanza la app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación vertical (juego diseñado para portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar AudioManagerService
  await AudioManagerService().init();

  runApp(const WordWondersApp());
}

/// Widget raíz de la aplicación.
/// Envuelve todo con MultiProvider y MaterialApp.router con GoRouter.
///
/// Orden de providers:
/// 1. AuthProvider — independiente, base de toda la app
/// 2. RoomProvider — depende de auth para crear/unirse
/// 3. GameProvider — depende de room para conectarse
/// 4. EvaluationProvider — depende de game para obtener la respuesta
/// 5. PunishmentProvider — depende de game para saber el perdedor
class WordWondersApp extends StatelessWidget {
  const WordWondersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => EvaluationProvider()),
        ChangeNotifierProvider(create: (_) => PunishmentProvider()),
      ],
      child: const _AppWithAuth(),
    );
  }
}

/// Widget interno que tiene acceso a AuthProvider para configurar
/// el redirect de GoRouter basado en el estado de autenticación.
class _AppWithAuth extends StatefulWidget {
  const _AppWithAuth();

  @override
  State<_AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends State<_AppWithAuth> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final gameProvider = context.read<GameProvider>();
    _router = AppRouter.createRouter(authProvider, gameProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
