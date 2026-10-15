import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/features/punishment/domain/punishment_model.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/features/punishment/presentation/providers/punishment_provider.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/presentation/widgets/punishment/camera_preview_widget.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de castigo — rediseño game-show.
class PunishmentScreen extends StatefulWidget {
  const PunishmentScreen({super.key});

  @override
  State<PunishmentScreen> createState() => _PunishmentScreenState();
}

class _PunishmentScreenState extends State<PunishmentScreen>
    with TickerProviderStateMixin {
  StreamSubscription? _punishmentSubscription;
  String? _punishmentMediaUrl;
  String? _punishmentType;
  String? _punishmentTargetColor;
  bool _isPlayingAudio = false;

  int _countdownSeconds = 15;
  Timer? _countdownTimer;
  bool _countdownStarted = false;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    AudioManagerService().pauseTrack();
    AudioManagerService().playSfx('redoble.wav');
    AudioManagerService().startLoopSfx('risas.wav');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final gameProvider = context.read<GameProvider>();
      final punishProvider = context.read<PunishmentProvider>();

      final isLoser = authProvider.currentUid == gameProvider.loserUid;
      if (isLoser) {
        punishProvider.clearPunishment();
        punishProvider.assignRandomPunishment(
          roomCode: gameProvider.roomCode!,
          playerUid: authProvider.currentUid!,
          playerUsername: authProvider.currentUser?.username ?? 'Jugador',
        );
      }

      final existingUrl = gameProvider.punishmentMediaUrl;
      if (existingUrl != null && existingUrl.isNotEmpty && !_countdownStarted) {
        setState(() {
          _punishmentMediaUrl = existingUrl;
          _punishmentType = gameProvider.punishmentType;
        });
        _startCountdown();
      }

      final roomCode = gameProvider.roomCode;
      if (roomCode != null) {
        _punishmentSubscription = FirebaseDatabase.instance
            .ref('games/$roomCode/state')
            .onValue
            .listen((event) {
              if (!mounted) return;
              final state = event.snapshot.value as Map?;
              final providerUrl = gameProvider.punishmentMediaUrl;
              final rtdbUrl = state?['punishmentMediaUrl']?.toString();
              final mediaUrl = rtdbUrl?.isNotEmpty == true
                  ? rtdbUrl
                  : providerUrl;
              final mediaType =
                  state?['punishmentType']?.toString() ??
                  gameProvider.punishmentType;
              final targetColor = state?['punishmentTargetColor']?.toString();

              if (mediaUrl != null && mediaUrl.isNotEmpty) {
                if (_punishmentMediaUrl != mediaUrl) {
                  setState(() {
                    _punishmentMediaUrl = mediaUrl;
                    _punishmentType = mediaType;
                    _punishmentTargetColor = targetColor;
                  });
                  if (!_countdownStarted) {
                    _startCountdown();
                  }
                }
              }
            });
      }
    });
  }

  void _startCountdown() {
    if (_countdownStarted) return;
    final totalSeconds = _punishmentType == 'audio' ? 45 : 15;
    setState(() {
      _countdownStarted = true;
      _countdownSeconds = totalSeconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        final gameProv = context.read<GameProvider>();
        final authProv = context.read<AuthProvider>();
        if (gameProv.roomHostUid == authProv.currentUid) {
          gameProv.endGame();
        }
        // Cada jugador navega de forma independiente cuando su contador termina
        context.go(AppRoutes.results);
      }
    });
  }

  @override
  void dispose() {
    _punishmentSubscription?.cancel();
    _countdownTimer?.cancel();
    _bounceController.dispose();
    AudioManagerService().stopLoopSfx();
    AudioManagerService().resumeTrack();
    try {
      context.read<PunishmentProvider>().audioService.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final gameProvider = context.watch<GameProvider>();
    final roomProvider = context.watch<RoomProvider>();
    final punishProvider = context.watch<PunishmentProvider>();

    final uid = authProvider.currentUid ?? '';
    final isLoser = uid == gameProvider.loserUid;
    final room = roomProvider.currentRoom;

    // ─── Vista de multimedia (perdedor y espectadores) ───
    if (_punishmentMediaUrl != null) {
      final loserPlayer = room?.players.cast<PlayerRef?>().firstWhere(
        (p) => p?.uid == gameProvider.loserUid,
        orElse: () => null,
      );
      final loserUsername = loserPlayer?.username ?? 'el perdedor';

      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: AppBackground(
          tint: AppColors.primaryRed.withValues(alpha: 0.05),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding(context),
                    vertical: AppDimensions.screenPadding(context),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            _punishmentType == 'photo'
                                ? (_punishmentTargetColor != null ? 'assets/icons/camara.svg' : 'assets/icons/selfie.svg')
                                : 'assets/icons/notas_musicales.svg',
                            size: 28,
                          ),
                          SizedBox(width: AppDimensions.spacingM(context)),
                          Expanded(
                            child: Text(
                              _punishmentType == 'photo'
                                  ? (_punishmentTargetColor != null ? '$loserUsername buscó el color ${_punishmentTargetColor!}' : '$loserUsername tomó su selfie')
                                  : '$loserUsername cantó su canción',
                              style: GoogleFonts.nunito(
                                fontSize: AppDimensions.fontSizeXL(context),
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.spacingXL(context)),

                      // Multimedia
                      Expanded(
                        child: Center(
                          child: _punishmentType == 'photo'
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXL(context),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadowBlue,
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXL(context),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: _punishmentMediaUrl!,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(
                                            color: AppColors.primaryBlue,
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.error,
                                            size: 64,
                                            color: AppColors.primaryRed,
                                          ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _bounceAnim,
                                      builder: (_, child) => Transform.scale(
                                        scale: _bounceAnim.value,
                                        child: child,
                                      ),
                                      child: Icon(
                                        Icons.music_note_rounded,
                                        size: 96,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    SizedBox(
                                      height: AppDimensions.spacingXL(context),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final audioService =
                                            punishProvider.audioService;
                                        if (_isPlayingAudio) {
                                          await audioService.stop();
                                          if (mounted)
                                            setState(
                                              () => _isPlayingAudio = false,
                                            );
                                        } else {
                                          setState(
                                            () => _isPlayingAudio = true,
                                          );
                                          try {
                                            await audioService.playFromUrl(
                                              _punishmentMediaUrl!,
                                            );
                                            audioService.playerStateStream
                                                .listen((state) {
                                                  if (state.processingState ==
                                                      ProcessingState
                                                          .completed) {
                                                    if (mounted)
                                                      setState(
                                                        () => _isPlayingAudio =
                                                            false,
                                                      );
                                                  }
                                                });
                                          } catch (e) {
                                            debugPrint(
                                              'Error al reproducir audio: $e',
                                            );
                                            if (mounted)
                                              setState(
                                                () => _isPlayingAudio = false,
                                              );
                                          }
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.cardWhite,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isPlayingAudio
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: AppColors.primaryBlue,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: AppDimensions.spacingM(context),
                                    ),
                                    Text(
                                      _isPlayingAudio
                                          ? 'Reproduciendo...'
                                          : 'Presiona para escuchar',
                                      style: GoogleFonts.nunito(
                                        fontSize: AppDimensions.fontSizeM(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: AppDimensions.spacingXL(context)),

                      // Countdown progress
                      if (_countdownStarted) ...[
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value:
                                  _countdownSeconds /
                                  (_punishmentType == 'audio' ? 45 : 15),
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Siguiente pantalla en $_countdownSeconds s',
                          style: GoogleFonts.nunito(
                            fontSize: AppDimensions.fontSizeS(context),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      SizedBox(height: AppDimensions.spacingXL(context)),

                      Builder(
                        builder: (ctx) => AppButton.blue(
                          text: 'Ver resultados',
                          icon: Icons.chevron_right_rounded,
                          onPressed: () {
                            final gameProv = context.read<GameProvider>();
                            final authProv = context.read<AuthProvider>();
                            if (gameProv.roomHostUid == authProv.currentUid) {
                              gameProv.endGame();
                            }
                            ctx.go(AppRoutes.results);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ─── Vista de espectador esperando el castigo ───
    if (!isLoser) {
      final loserPlayer = room?.players.cast<PlayerRef?>().firstWhere(
        (p) => p?.uid == gameProvider.loserUid,
        orElse: () => null,
      );
      final loserUsername = loserPlayer?.username ?? 'el perdedor';

      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: AppBackground(
          tint: AppColors.primaryRed.withValues(alpha: 0.05),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, child) =>
                        Transform.scale(scale: _bounceAnim.value, child: child),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(AppIcon.castigoSkull, size: 80),
                        SizedBox(width: 16),
                        AppIcon(AppIcon.castigoClock, size: 80),
                      ],
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXL(context)),
                  Text(
                    'Fase de Castigo',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFC0392B),
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.spacingM(context)),
                  Text(
                    'Esperando que $loserUsername cumpla con su castigo...',
                    style: GoogleFonts.nunito(
                      fontSize: AppDimensions.fontSizeL(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.spacingXXL(context)),
                  const CircularProgressIndicator(color: AppColors.primaryRed),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ─── Vista del perdedor subiendo el castigo ───
    final punishment = punishProvider.currentPunishment;

    if (punishment == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: AppBackground(
        tint: AppColors.primaryRed.withValues(alpha: 0.05),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppDimensions.spacingXL(context)),
                _buildHeader(punishment),
                SizedBox(height: AppDimensions.spacingXL(context)),
                Expanded(
                  child: _buildContent(context, punishment, punishProvider),
                ),
                SizedBox(height: AppDimensions.spacingL(context)),
                _buildActions(context, punishment, punishProvider),
                SizedBox(height: AppDimensions.spacingXL(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PunishmentModel punishment) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) =>
              Transform.scale(scale: _bounceAnim.value, child: child),
          child: AppIcon(AppIcon.castigoSkull, size: 64),
        ),
        SizedBox(height: AppDimensions.spacingM(context)),
        Text(
          '¡TE TOCA CASTIGO!',
          style: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeXXL(context),
            fontWeight: FontWeight.w900,
            color: const Color(0xFFC0392B),
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: AppDimensions.spacingS(context)),
        Text(
          punishment.type.description,
          style: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeL(context),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        if (punishment.targetColor != null) ...[
          SizedBox(height: AppDimensions.spacingM(context)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusXL(context),
              ),
              border: Border.all(color: AppColors.primaryBlue, width: 2),
            ),
            child: Text(
              'Color a buscar: ${punishment.targetColor!.toUpperCase()}',
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeXL(context),
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    PunishmentModel punishment,
    PunishmentProvider provider,
  ) {
    if (punishment.requiresCamera) {
      return ClipRRect(
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusXL(context)),
        ),
        child: CameraPreviewWidget(
          controller: provider.cameraService.controller,
          capturedImage: provider.capturedPhoto,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlue,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) =>
                  Transform.scale(scale: _bounceAnim.value, child: child),
              child: Icon(
                Icons.mic_rounded,
                size: 80,
                color: AppColors.primaryRed,
              ),
            ),
            SizedBox(height: AppDimensions.spacingL(context)),
            Text(
              provider.isRecording
                  ? 'Grabando...'
                  : provider.recordedAudioPath != null
                  ? 'Audio grabado'
                  : 'Presiona el micrófono para grabar',
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeM(context),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActions(
    BuildContext context,
    PunishmentModel punishment,
    PunishmentProvider provider,
  ) {
    if (provider.hasMedia) {
      return Row(
        children: [
          Expanded(
            child: AppButton.outline(
              text: 'Rehacer',
              icon: Icons.refresh,
              color: AppColors.primaryRed,
              onPressed: () {
                if (punishment.requiresCamera) {
                  provider.retakePhoto();
                } else {
                  provider.discardRecording();
                }
              },
            ),
          ),
          SizedBox(width: AppDimensions.spacingM(context)),
          Expanded(
            child: AppButton.blue(
              text: 'Enviar',
              icon: Icons.send,
              isLoading: provider.isUploading,
              onPressed: () => provider.submitPunishment(),
            ),
          ),
        ],
      );
    }

    if (punishment.requiresCamera) {
      return AppButton.red(
        text: 'Tomar foto',
        iconWidget: AppIcon(
          punishment.type == PunishmentType.findColor
              ? 'assets/icons/camara.svg'
              : 'assets/icons/selfie.svg',
          color: Colors.white,
          size: 24,
        ),
        onPressed: () {
          AudioManagerService().playSfx('camara.wav');
          provider.takePhoto();
        },
      );
    } else {
      return AppButton.red(
        text: provider.isRecording ? 'Detener' : 'Grabar audio',
        icon: provider.isRecording ? Icons.stop : Icons.mic,
        onPressed: () {
          if (provider.isRecording) {
            provider.stopRecording();
          } else {
            provider.startRecording();
          }
        },
      );
    }
  }
}
