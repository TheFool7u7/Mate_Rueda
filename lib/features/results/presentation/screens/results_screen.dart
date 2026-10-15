import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de resultados — rediseño game-show.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, int> _fallbackScores = {};
  bool _loadingFallback = false;

  int _countdownSeconds = 45;
  bool _canReplay = false;
  Timer? _replayTimer;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('final.mp3', loop: false);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _startReplayCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AudioManagerService().playSfx('redoble.wav');
      
      final gameProvider = context.read<GameProvider>();
      final authProvider = context.read<AuthProvider>();
      final finalScores = gameProvider.finalScores;
      final allZero =
          finalScores.values.isNotEmpty &&
          finalScores.values.every((v) => v == 0);
          
      if (finalScores.isEmpty || allZero) {
        _loadFallbackScores(gameProvider.roomCode).then((_) {
           _playWinOrLose(gameProvider, authProvider);
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          _playWinOrLose(gameProvider, authProvider);
        });
      }
    });
  }

  void _playWinOrLose(GameProvider gameProvider, AuthProvider authProvider) {
    if (!mounted) return;
    final uid = authProvider.currentUid ?? '';
    final scores = _fallbackScores.isNotEmpty ? _fallbackScores : gameProvider.finalScores;
    if (scores.isEmpty) return;

    final leaderboard = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final minScore = leaderboard.last.value;
    final winnerUid = leaderboard.first.key;
    
    if (uid == winnerUid) {
      AudioManagerService().playSfx('win.mp3');
    } else {
      final myScore = scores[uid] ?? 0;
      if (myScore == minScore && leaderboard.length > 1) {
        AudioManagerService().playSfx('perdedor.m4a');
      }
    }
  }

  void _startReplayCountdown() {
    _replayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        setState(() => _canReplay = true);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _replayTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFallbackScores(String? roomCode) async {
    if (roomCode == null) return;
    if (mounted) setState(() => _loadingFallback = true);
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('games/$roomCode/state/finalScores')
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final Map<String, int> scores = {};
        final data = snapshot.value as Map;
        data.forEach((uid, value) {
          scores[uid.toString()] = (value as num).toInt();
        });
        if (mounted) {
          setState(() {
            _fallbackScores = scores;
            _loadingFallback = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingFallback = false);
      }
    } catch (e) {
      debugPrint('Error al cargar fallback de puntajes: $e');
      if (mounted) setState(() => _loadingFallback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFallback && _fallbackScores.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Consumer3<GameProvider, RoomProvider, AuthProvider>(
      builder: (context, gameProvider, roomProvider, authProvider, _) {
        final room = roomProvider.currentRoom;
        final players = room?.players ?? [];
        final uid = authProvider.currentUid ?? '';
        final finalScores = gameProvider.finalScores;

        final Map<String, int> scoresToUse;
        final allZero =
            finalScores.values.isNotEmpty &&
            finalScores.values.every((v) => v == 0);
        if (finalScores.isNotEmpty && !allZero) {
          scoresToUse = finalScores;
        } else if (_fallbackScores.isNotEmpty) {
          scoresToUse = _fallbackScores;
        } else {
          scoresToUse = {
            for (final p in players) p.uid: gameProvider.getPlayerScore(p.uid),
          };
        }

        final List<MapEntry<String, int>> leaderboard =
            scoresToUse.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        final minScore = leaderboard.isNotEmpty
            ? leaderboard.map((e) => e.value).reduce((a, b) => a < b ? a : b)
            : -1;

        String winnerName = 'Nadie';
        int winnerScore = 0;
        if (leaderboard.isNotEmpty) {
          final winnerUid = leaderboard.first.key;
          winnerScore = leaderboard.first.value;
          final winnerPlayer = players.cast<PlayerRef?>().firstWhere(
            (p) => p?.uid == winnerUid,
            orElse: () => null,
          );
          winnerName = winnerPlayer?.username ?? 'Jugador';
        }

        final isHost = room?.isHost(uid) ?? false;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: AppBackground(
            tint: const Color(0xFFFFF8E7), // victoryBg tint
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Header con trofeo SVG animado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _bounceAnim,
                              builder: (_, child) => Transform.scale(
                                scale: _bounceAnim.value,
                                child: child,
                              ),
                              child: AppIcon(AppIcon.trofeo, size: 90),
                            ),
                          ],
                        ),
                        SizedBox(height: AppDimensions.spacingL(context)),

                        Text(
                          AppStrings.gameOver,
                          style: GoogleFonts.nunito(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: AppColors.accentGold.withValues(
                                  alpha: 0.3,
                                ),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Ganador card
                        if (leaderboard.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(
                              AppDimensions.spacingXL(context),
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL(context),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF8C00,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                AppIcon(
                                  AppIcon.trofeo,
                                  size: 36,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  height: AppDimensions.spacingS(context),
                                ),
                                Text(
                                  winnerName.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeXXL(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  '$winnerScore pts',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeL(context),
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: AppDimensions.spacingXL(context)),

                          // Ranking completo
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: leaderboard.length,
                              itemBuilder: (context, index) {
                                final item = leaderboard[index];
                                final playerUid = item.key;
                                final score = item.value;

                                final player = players
                                    .cast<PlayerRef?>()
                                    .firstWhere(
                                      (p) => p?.uid == playerUid,
                                      orElse: () => null,
                                    );
                                final username = player?.username ?? 'Jugador';
                                final isMe = playerUid == uid;

                                final medalAssets = [
                                  AppIcon.medallaOro,
                                  AppIcon.medallaPlata,
                                  AppIcon.medallaBronce,
                                ];

                                final medalWidget = index < 3
                                    ? AppIcon(medalAssets[index], size: 36)
                                    : Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.dividerColor
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: GoogleFonts.nunito(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        ),
                                      );

                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: AppDimensions.spacingM(context),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spacingL(context),
                                    vertical: AppDimensions.spacingM(context),
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primaryBlue.withValues(
                                            alpha: 0.08,
                                          )
                                        : AppColors.cardWhite,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusL(context),
                                    ),
                                    border: isMe
                                        ? Border.all(
                                            color: AppColors.primaryBlue,
                                            width: 2.0,
                                          )
                                        : null,
                                    boxShadow: isMe
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: AppColors.shadowLight,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    children: [
                                      medalWidget,
                                      SizedBox(
                                        width: AppDimensions.spacingL(context),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$username${isMe ? ' (Tú)' : ''}',
                                              style: GoogleFonts.nunito(
                                                fontSize:
                                                    AppDimensions.fontSizeM(
                                                      context,
                                                    ),
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (score == minScore &&
                                                leaderboard.length > 1)
                                              Container(
                                                margin: EdgeInsets.only(top: 4),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryRed
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppDimensions.radiusXXL(
                                                          context,
                                                        ),
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Último Lugar',
                                                      style: GoogleFonts.nunito(
                                                        color: AppColors
                                                            .primaryRed,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    AppIcon(
                                                      AppIcon.castigoSkull,
                                                      size: 12,
                                                      color:
                                                          AppColors.primaryRed,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '$score pts',
                                        style: GoogleFonts.nunito(
                                          fontSize: AppDimensions.fontSizeL(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w900,
                                          color:
                                              AppColors.playerColors[index %
                                                  AppColors
                                                      .playerColors
                                                      .length],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        SizedBox(height: AppDimensions.spacingL(context)),

                        // Botones
                        Column(
                          children: [
                            if (isHost) ...[
                              if (!_canReplay)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: AppDimensions.spacingM(context),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.dividerColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusRound(context),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Esperando $_countdownSeconds s...',
                                        style: GoogleFonts.nunito(
                                          fontSize: AppDimensions.fontSizeM(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                AppButton.red(
                                  text: 'REPETIR JUEGO',
                                  icon: Icons.replay_rounded,
                                  isLoading: gameProvider.isLoading,
                                  onPressed: () async {
                                    final success = await gameProvider
                                        .restartGame();
                                    if (success && context.mounted) {
                                      context.go(AppRoutes.game);
                                    }
                                  },
                                ),
                              SizedBox(height: AppDimensions.spacingM(context)),
                            ],
                            AppButton.outline(
                              text: 'MENÚ PRINCIPAL',
                              icon: Icons.home_rounded,
                              color: AppColors.primaryBlue,
                              onPressed: () async {
                                final roomCode = gameProvider.roomCode;
                                if (roomCode != null && isHost) {
                                  await gameProvider.cleanupGame(roomCode);
                                }
                                final user = authProvider.currentUser;
                                if (user != null) {
                                  await roomProvider.leaveRoom(user);
                                }
                                gameProvider.disconnectFromGame(uid);
                                roomProvider.reset();
                                if (context.mounted) {
                                  context.go(AppRoutes.home);
                                }
                              },
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
        );
      },
    );
  }
}
