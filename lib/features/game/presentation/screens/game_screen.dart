import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/features/game/data/realtime_db_service.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/presentation/widgets/game/letter_wheel_widget.dart';
import 'package:wordwonderslink/shared/presentation/widgets/game/scoreboard_widget.dart';
import 'package:wordwonderslink/shared/presentation/widgets/game/power_ups_widget.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/audio_settings_dialog.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla principal del juego — rediseño game-show.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('juego.mp3', loop: true);
    _connectToGame();
  }

  void _connectToGame() {
    final roomProvider = context.read<RoomProvider>();
    final authProvider = context.read<AuthProvider>();
    final gameProvider = context.read<GameProvider>();
    final roomCode = roomProvider.currentRoomCode;
    final uid = authProvider.currentUid;
    final hostUid = roomProvider.currentRoom?.hostUid;

    if (roomCode != null && uid != null) {
      gameProvider.connectToGame(roomCode, uid, hostUid: hostUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<GameProvider, RoomProvider, AuthProvider>(
      builder: (context, gameProvider, roomProvider, authProvider, _) {
        final uid = authProvider.currentUid ?? '';
        final room = roomProvider.currentRoom;

        // Mostrar notificación de desconexión/reconexión de jugadores
        final notification = gameProvider.disconnectNotification;
        if (notification != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            gameProvider.clearDisconnectNotification();

            final isReconnect = notification.startsWith('reconnected:');
            final playerUid = isReconnect
                ? notification.replaceFirst('reconnected:', '')
                : notification;

            // Resolver UID a username
            String username = playerUid;
            if (room != null) {
              final player = room.players.where((p) => p.uid == playerUid);
              if (player.isNotEmpty) {
                username = player.first.username;
              }
            }

            final message = isReconnect
                ? '$username se ha vuelto a unir a la sala'
                : '$username ha abandonado la sala';

            final iconPath = isReconnect
                ? 'assets/icons/conectado.svg'
                : 'assets/icons/desconectado.svg';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    AppIcon(iconPath, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: isReconnect
                    ? AppColors.accentGreen
                    : const Color(0xFFE53935),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 160,
                  left: 16,
                  right: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          });
        }
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: AppBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      SizedBox(height: AppDimensions.spacingM(context)),

                      // ── Top bar: Icono Audio + Scoreboard ──
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPadding(context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Scoreboard
                            if (room != null)
                              _StyledScoreboard(
                                players: room.players,
                                playersData: gameProvider.playersData,
                                activePlayerUid: gameProvider.activePlayerUid,
                              ),

                            // Settings / Audio Icon
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => const AudioSettingsDialog(),
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowBlue,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppDimensions.spacingM(context)),

                      // ── Categoría Centrada ──
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Label con lápiz
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  'assets/icons/lapiz.svg',
                                  size: 16,
                                  color: AppColors.textGrey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'CATEGORÍA',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeS(context),
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Pill badge azul
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingL(context),
                                vertical: AppDimensions.spacingS(context),
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.buttonBlueGradient,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusRound(context),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                  const BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(0, -1),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                gameProvider.currentCategory.toUpperCase(),
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: AppDimensions.fontSizeL(context),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            
                            if (gameProvider.currentPhase == GamePhase.answering && gameProvider.activePlayerUid.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final activePlayer = room?.players.cast<PlayerRef?>().firstWhere(
                                        (p) => p?.uid == gameProvider.activePlayerUid,
                                        orElse: () => null,
                                      );
                                  if (activePlayer == null) return const SizedBox.shrink();
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      '${activePlayer.username} está respondiendo la "${gameProvider.currentLetter}"',
                                      style: GoogleFonts.nunito(
                                        color: AppColors.primaryBlue,
                                        fontSize: AppDimensions.fontSizeM(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppDimensions.spacingL(context)),

                      // ── Rueda + power-ups ──
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Triángulo indicador
                                    CustomPaint(
                                      painter: _TrianglePainter(),
                                      size: const Size(26, 30),
                                    ),
                                    const SizedBox(height: 4),
                                    LetterWheelWidget(
                                      letters: gameProvider.letters,
                                      enabled: gameProvider.canSelectLetter,
                                      onLetterTap: (char) {
                                        gameProvider.claimLetter(
                                          char: char,
                                          uid: uid,
                                          username:
                                              authProvider
                                                  .currentUser
                                                  ?.username ??
                                              'Jugador',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    // Power-ups en cards redondeadas
                                    const PowerUpsWidget(),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Error message
                      if (gameProvider.errorMessage != null)
                        Padding(
                          padding: EdgeInsets.all(
                            AppDimensions.spacingM(context),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(
                              AppDimensions.spacingM(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusL(context),
                              ),
                              border: Border.all(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.primaryRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    gameProvider.errorMessage!,
                                    style: GoogleFonts.nunito(
                                      color: AppColors.primaryRed,
                                      fontSize: AppDimensions.fontSizeS(
                                        context,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: AppDimensions.spacingL(context)),
                    ],
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

/// Scoreboard con estilo game-show: card blanca con header azul.
class _StyledScoreboard extends StatelessWidget {
  final List<PlayerRef> players;
  final Map<String, dynamic> playersData;
  final String activePlayerUid;

  const _StyledScoreboard({
    required this.players,
    required this.playersData,
    required this.activePlayerUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Usar el widget original
            ScoreboardWidget(
              players: players,
              playersData: playersData,
              activePlayerUid: activePlayerUid,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Triángulo indicador en la cima de la rueda
// ─────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primaryBlue
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = AppColors.primaryBlue);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
