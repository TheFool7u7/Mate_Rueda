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

/// Pantalla para unirse a una sala — rediseño game-show.
class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final roomProvider = context.read<RoomProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final success = await roomProvider.joinRoom(code, user);
    if (success && mounted) {
      context.push(AppRoutes.lobby);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        return LoadingOverlay(
          isLoading: roomProvider.isLoading,
          message: AppStrings.joiningRoom,
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
                        // Custom AppBar
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
                                    AppStrings.joinRoomTitle,
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
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.screenPadding(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: AppDimensions.spacingXXXL(context),
                                ),

                                // Chain icon in teal/blue circle
                                Center(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.buttonBlueGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.35),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: AppIcon(
                                        AppIcon.unirseASalaCadena,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingXL(context),
                                ),

                                Text(
                                  '¡Únete a la partida!',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeXXL(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  AppStrings.enterCode,
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeM(context),
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingXXXL(context),
                                ),

                                // Code input field — pill card
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardWhite,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXXL(context),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadowBlue,
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _codeController,
                                    textAlign: TextAlign.center,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                      color: AppColors.textDark,
                                    ),
                                    maxLength: 8,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: 'XXX-XXXX',
                                      hintStyle: GoogleFonts.nunitoSans(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 6,
                                        color: AppColors.textLight,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: AppDimensions.spacingXL(
                                          context,
                                        ),
                                        horizontal: AppDimensions.spacingL(
                                          context,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => _handleJoin(),
                                  ),
                                ),

                                // Error
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
                                      border: Border.all(
                                        color: AppColors.primaryRed.withValues(
                                          alpha: 0.3,
                                        ),
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
                                            style: GoogleFonts.nunito(
                                              color: AppColors.primaryRed,
                                              fontSize: AppDimensions.fontSizeS(
                                                context,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(
                                  height: AppDimensions.spacingXXXL(context),
                                ),

                                AppButton.blue(
                                  text: 'UNIRSE AL JUEGO',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: _handleJoin,
                                ),

                                SizedBox(
                                  height: AppDimensions.spacingXL(context),
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
