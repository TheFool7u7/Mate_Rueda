import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/evaluation/domain/vote_model.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/evaluation/presentation/providers/evaluation_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de evaluación — rediseño game-show.
class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final ValueNotifier<int> _evalCountdown = ValueNotifier<int>(30);
  Timer? _evalTimer;
  final AutoSizeGroup _badgeGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    final evalProvider = context.read<EvaluationProvider>();
    Future.microtask(() => evalProvider.reset());

    // Iniciar el timer visual de 30 segundos
    _evalCountdown.value = 30;
    _evalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_evalCountdown.value > 0) {
        _evalCountdown.value--;
      } else {
        timer.cancel();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final evalProvider = context.read<EvaluationProvider>();
      final gameProvider = context.read<GameProvider>();
      final roomProvider = context.read<RoomProvider>();
      final authProvider = context.read<AuthProvider>();

      // Calcular votos esperados basándose en jugadores CONECTADOS,
      // excluyendo al autor de la respuesta.
      final players = roomProvider.currentRoom?.players ?? [];
      final authorUid = gameProvider.activePlayerUid;
      final List<String> voterUids = [];
      for (final p in players) {
        if (p.uid == authorUid) continue; // El autor no vota
        if (gameProvider.isPlayerConnected(p.uid)) {
          voterUids.add(p.uid);
        }
      }
      final expectedVotes = voterUids.isNotEmpty ? voterUids.length : 1;

      final isHost = gameProvider.roomHostUid == authProvider.currentUid;

      evalProvider.startEvaluation(
        roomCode: gameProvider.roomCode ?? '',
        roundId: gameProvider.currentRoundId,
        letterId: gameProvider.currentLetter,
        expectedVotes: expectedVotes,
        voterUids: voterUids,
        isHost: isHost,
        onAllVotesSubmitted: () {
          debugPrint(
            '=== onAllVotesSubmitted: isHost=$isHost, allLettersUsed=${gameProvider.allLettersUsed}, gameFinished=${gameProvider.gameFinished}',
          );

          if (!isHost) return;

          if (gameProvider.allLettersUsed) {
            gameProvider.triggerFinishGame();
          } else if (!gameProvider.gameFinished) {
            gameProvider.nextCategory();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _evalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<EvaluationProvider, GameProvider, AuthProvider>(
      builder: (context, evalProvider, gameProvider, authProvider, _) {
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
            final roomProvider = context.read<RoomProvider>();
            final room = roomProvider.currentRoom;
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

        if (evalProvider.responseBeingEvaluated == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        final isMyResponse =
            authProvider.currentUid ==
            evalProvider.responseBeingEvaluated?.submittedBy;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.backgroundColor,
          body: AppBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding(context),
                      vertical: AppDimensions.spacingL(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título con estrella
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              'assets/icons/estrella_calificar.svg',
                              size: 32,
                            ),
                            SizedBox(width: AppDimensions.spacingM(context)),
                            Text(
                              AppStrings.evaluateResponse,
                              style: GoogleFonts.nunito(
                                fontSize: AppDimensions.fontSizeXL(context),
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Categoría + Letra + Palabra
                        _buildResponseCard(gameProvider, evalProvider),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        if (isMyResponse) ...[
                          // Es la respuesta del propio usuario — mostrar mensaje de espera
                          Container(
                            padding: EdgeInsets.all(
                              AppDimensions.spacingXL(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL(context),
                              ),
                            ),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),
                                Text(
                                  'Calificación en progreso',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeL(context),
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                SizedBox(
                                  height: AppDimensions.spacingS(context),
                                ),
                                Text(
                                  'Esperando que los demás califiquen tu respuesta...',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (!evalProvider.hasVoted) ...[
                          // Selector de puntaje 1-10 en Wrap
                          _buildScoreSelector(evalProvider),

                          SizedBox(height: AppDimensions.spacingXL(context)),

                          // Badges
                          _buildBadgeSelector(evalProvider),

                          SizedBox(height: AppDimensions.spacingXXL(context)),

                          // Botón votar
                          AppButton.blue(
                            text: AppStrings.submitVote,
                            icon: Icons.how_to_vote_rounded,
                            isLoading: evalProvider.isLoading,
                            onPressed: () {
                              evalProvider.submitVote(
                                roomCode: gameProvider.roomCode ?? '',
                                roundId: gameProvider.currentRoundId,
                                letterId: gameProvider.currentLetter,
                                voterId: authProvider.currentUid ?? '',
                                voterUsername:
                                    authProvider.currentUser?.username ?? '',
                              );
                            },
                          ),
                        ] else ...[
                          // Ya votó — mostrar resultado
                          Container(
                            padding: EdgeInsets.all(
                              AppDimensions.spacingXL(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL(context),
                              ),
                            ),
                            child: Column(
                              children: [
                                AppIcon('assets/icons/check_verde.svg', size: 48),
                                SizedBox(
                                  height: AppDimensions.spacingM(context),
                                ),
                                Text(
                                  AppStrings.voteSubmitted,
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeL(context),
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                                SizedBox(
                                  height: AppDimensions.spacingXS(context),
                                ),
                                Text(
                                  AppStrings.waitingOtherVotes,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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

  Widget _buildResponseCard(
    GameProvider gameProvider,
    EvaluationProvider evalProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingL(context)),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Pill + Timer
          Row(
            children: [
              // Timer circular (movido a la izquierda)
              ValueListenableBuilder<int>(
                valueListenable: _evalCountdown,
                builder: (context, countdown, _) {
                  return SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: countdown / 30,
                          strokeWidth: 3,
                          backgroundColor: AppColors.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            countdown <= 10
                                ? const Color(0xFFE53935)
                                : AppColors.primaryBlue,
                          ),
                        ),
                        Text(
                          '$countdown',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: countdown <= 10
                                ? const Color(0xFFE53935)
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              // Category Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusXXL(context),
                  ),
                ),
                child: Text(
                  gameProvider.currentCategory,
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeS(context),
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              // Spacer invisible para mantener la categoría centrada
              const SizedBox(width: 36),
            ],
          ),
          SizedBox(height: AppDimensions.spacingM(context)),

          Row(
            children: [
              // Letter Avatar
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.buttonRedGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66E82020),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    gameProvider.currentLetter,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.spacingL(context)),

              // Word
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evalProvider.responseBeingEvaluated?.word ?? '...',
                      style: GoogleFonts.nunito(
                        fontSize: AppDimensions.fontSizeXXL(context),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (evalProvider.responseBeingEvaluated != null)
                      Text(
                        'por ${evalProvider.responseBeingEvaluated!.submittedByUsername}',
                        style: GoogleFonts.nunito(
                          fontSize: AppDimensions.fontSizeM(context),
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int score, EvaluationProvider evalProvider) {
    final isSelected = evalProvider.selectedScore == score;
    return GestureDetector(
      onTap: () {
        evalProvider.selectScore(score);
        if (score >= 6) {
          AudioManagerService().playSfx('positiva.wav');
        } else {
          AudioManagerService().playSfx('nagativa.wav');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.buttonBlueGradient : null,
          color: isSelected ? null : AppColors.cardWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.dividerColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            '$score',
            style: GoogleFonts.nunito(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSelector(EvaluationProvider evalProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.spacingL(context)),
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
      child: Column(
        children: [
          Text(
            'Califica la respuesta',
            style: GoogleFonts.nunito(
              fontSize: AppDimensions.fontSizeL(context),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: AppDimensions.spacingL(context)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(
              10,
              (i) => _buildNumberButton(i + 1, evalProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSelector(EvaluationProvider evalProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.spacingL(context)),
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
      child: Column(
        children: [
          Text(
            'Calidad de la respuesta',
            style: GoogleFonts.nunito(
              fontSize: AppDimensions.fontSizeL(context),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: AppDimensions.spacingL(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: VoteBadge.values.map((badge) {
              final isSelected = evalProvider.selectedBadge == badge;
              return Expanded(
                child: GestureDetector(
                  onTap: () => evalProvider.selectBadge(badge),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.08)
                          : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL(context),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.dividerColor,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        AppIcon(badge.iconAsset, size: 32),
                        SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            badge.displayName.split(' ').last.toUpperCase(),
                            style: GoogleFonts.nunito(
                              fontSize: AppDimensions.fontSizeS(context),
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textGrey,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
