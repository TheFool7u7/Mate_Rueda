import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/loading_overlay.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de creación de sala — rediseño game-show.
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RoomProvider, AuthProvider>(
      builder: (context, roomProvider, authProvider, _) {
        return LoadingOverlay(
          isLoading: roomProvider.isLoading,
          message: AppStrings.creatingRoom,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: AppBackground(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // AppBar custom
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Container(
                                  width: 36,
                                  height: 36,
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
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: AppColors.textDark,
                                    size: 18,
                                  ),
                                ),
                                onPressed: () => context.pop(),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    AppStrings.createRoomTitle,
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: AppDimensions.fontSizeXL(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 48),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.screenPadding(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: AppDimensions.spacingXXL(context),
                                ),

                                // Gamepad animado con pulse
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _pulseAnim,
                                    builder: (_, child) => Transform.scale(
                                      scale: _pulseAnim.value,
                                      child: child,
                                    ),
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.buttonBlueGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryBlue
                                                .withValues(alpha: 0.40),
                                            blurRadius: 24,
                                            spreadRadius: 4,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: AppIcon(
                                          AppIcon.control,
                                          size: 52,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingXL(context),
                                ),

                                Text(
                                  '¡Configura tu partida!',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeXXL(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Elige el número de jugadores y el tiempo',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeM(context),
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingXXL(context),
                                ),

                                // Stepper: Jugadores
                                _ConfigCard(
                                  leadingIcon: AppIcon.crearSalaJugadores,
                                  leadingColor: AppColors.primaryBlue,
                                  title: AppStrings.maxPlayersLabel,
                                  value: '${roomProvider.selectedMaxPlayers}',
                                  unit: 'jugadores',
                                  onIncrement: roomProvider.incrementPlayers,
                                  onDecrement: roomProvider.decrementPlayers,
                                  min: AppDimensions.minPlayers,
                                  max: AppDimensions.maxPlayers,
                                  current: roomProvider.selectedMaxPlayers,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingL(context),
                                ),

                                // Stepper: Tiempo
                                _ConfigCard(
                                  leadingIcon: null,
                                  leadingMaterialIcon: Icons.timer_outlined,
                                  leadingColor: AppColors.accentGold,
                                  title: AppStrings.timePerTurnLabel,
                                  value: '${roomProvider.selectedTimePerTurn}',
                                  unit: 'segundos',
                                  onIncrement: roomProvider.incrementTime,
                                  onDecrement: roomProvider.decrementTime,
                                  min: AppDimensions.minResponseTime,
                                  max: AppDimensions.maxResponseTime,
                                  current: roomProvider.selectedTimePerTurn,
                                ),

                                if (roomProvider.errorMessage != null) ...[
                                  SizedBox(
                                    height: AppDimensions.spacingL(context),
                                  ),
                                  Container(
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
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppColors.primaryRed,
                                          size: 18,
                                        ),
                                        SizedBox(
                                          width: AppDimensions.spacingS(
                                            context,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            roomProvider.errorMessage!,
                                            style: TextStyle(
                                              color: AppColors.primaryRed,
                                              fontSize: AppDimensions.fontSizeS(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const Spacer(),

                                AppButton.red(
                                  text: AppStrings.createAndShare,
                                  icon: Icons.rocket_launch_rounded,
                                  onPressed: () async {
                                    final user = authProvider.currentUser;
                                    if (user == null) return;
                                    final code = await roomProvider.createRoom(
                                      user,
                                    );
                                    if (code != null && context.mounted) {
                                      context.push(AppRoutes.lobby);
                                    }
                                  },
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingXXL(context),
                                ),
                              ],
                            ),
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
      },
    );
  }
}

/// Card de configuración con stepper +/-
class _ConfigCard extends StatelessWidget {
  final String? leadingIcon;
  final IconData? leadingMaterialIcon;
  final Color leadingColor;
  final String title;
  final String value;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int min;
  final int max;
  final int current;

  const _ConfigCard({
    this.leadingIcon,
    this.leadingMaterialIcon,
    required this.leadingColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.onIncrement,
    required this.onDecrement,
    required this.min,
    required this.max,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: leadingColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: leadingIcon != null
                ? Center(
                    child: AppIcon(leadingIcon!, size: 26, color: leadingColor),
                  )
                : Icon(leadingMaterialIcon, color: leadingColor, size: 26),
          ),
          SizedBox(width: AppDimensions.spacingM(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeM(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  unit,
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeXS(context),
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Stepper
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            enabled: current > min,
            color: leadingColor,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS(context),
            ),
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeXXL(context),
                fontWeight: FontWeight.w900,
                color: leadingColor,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            enabled: current < max,
            color: leadingColor,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color color;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? color : AppColors.dividerColor,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? Colors.white : AppColors.textLight,
        ),
      ),
    );
  }
}
