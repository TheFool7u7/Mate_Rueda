import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/game/presentation/providers/game_provider.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de respuesta — rediseño game-show.
/// Timer verde→amarillo→rojo, letra con glow pulse, campo pill con X.
class AnsweringScreen extends StatefulWidget {
  const AnsweringScreen({super.key});

  @override
  State<AnsweringScreen> createState() => _AnsweringScreenState();
}

class _AnsweringScreenState extends State<AnsweringScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _answerController;
  late final FocusNode _answerFocusNode;
  String? _letterError;

  // Pulse animation for letter badge
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('juego.mp3', loop: true);
    _answerController = TextEditingController(
      text: context.read<GameProvider>().currentAnswer,
    );
    _answerFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _answerFocusNode.requestFocus();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _validateFirstLetter(String word, String letter) {
    if (word.trim().isEmpty) return false;
    final firstChar = word.trim()[0].toUpperCase();
    return firstChar == letter.toUpperCase();
  }

  void _submitAnswer(String uid, String username, GameProvider gameProvider) {
    final answer = gameProvider.currentAnswer.trim();
    if (answer.isEmpty || gameProvider.isLoading) return;

    if (!_validateFirstLetter(answer, gameProvider.currentLetter)) {
      setState(() {
        _letterError =
            'La palabra debe empezar con "${gameProvider.currentLetter}"';
      });
      return;
    }

    setState(() => _letterError = null);
    AudioManagerService().playSfx('enviado.wav');
    gameProvider.submitAnswer(
      uid: uid,
      username: username,
      roundId: gameProvider.currentRoundId,
    );
  }

  /// Devuelve el color del timer según el tiempo restante.
  Color _timerColor(int remaining, int total) {
    final ratio = total > 0 ? remaining / total : 0.0;
    if (ratio > 0.5) return AppColors.accentGreen;
    if (ratio > 0.25) return AppColors.accentGold;
    return AppColors.primaryRed;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, AuthProvider>(
      builder: (context, gameProvider, authProvider, _) {
        final uid = authProvider.currentUid ?? '';
        final username = authProvider.currentUser?.username ?? '';
        final remaining = gameProvider.remainingSeconds;
        final isUrgent = remaining <= 10;
        final timerColor = _timerColor(remaining, 30);

        // Activar pulse cuando quedan ≤10s
        if (isUrgent && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!isUrgent && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.value = 1.0;
        }

        // Color de fondo dinámico según el timer

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.backgroundColor,
          body: AppBackground(
            tint: timerColor.withAlpha(15), // tint based on timer color
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.screenPadding(context),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: AppDimensions.spacingL(context)),

                        // Timer circular
                        _buildTimer(remaining, timerColor, isUrgent),

                        SizedBox(height: AppDimensions.spacingXL(context)),

                        // Letra + categoría
                        _buildLetterAndCategory(
                          gameProvider,
                          timerColor,
                          isUrgent,
                        ),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Input field
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.screenPadding(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label
                              Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Tu respuesta',
                                  style: GoogleFonts.nunito(
                                    fontSize: AppDimensions.fontSizeM(context),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              // Field
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXXL(context),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _letterError != null
                                          ? AppColors.primaryRed.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.shadowBlue,
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _answerController,
                                  focusNode: _answerFocusNode,
                                  enabled: !gameProvider.isLoading,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: gameProvider.isLoading
                                      ? null
                                      : (_) => _submitAnswer(
                                          uid,
                                          username,
                                          gameProvider,
                                        ),
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Escribe tu respuesta...',
                                    hintStyle: GoogleFonts.nunito(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusXXL(context),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusXXL(context),
                                      ),
                                      borderSide: BorderSide(
                                        color: _letterError != null
                                            ? AppColors.primaryRed
                                            : AppColors.dividerColor,
                                        width: _letterError != null ? 2 : 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusXXL(context),
                                      ),
                                      borderSide: BorderSide(
                                        color: _letterError != null
                                            ? AppColors.primaryRed
                                            : AppColors.primaryBlue,
                                        width: 2.5,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 18,
                                    ),
                                    suffixIcon:
                                        _answerController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryRed
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: AppColors.primaryRed,
                                                size: 16,
                                              ),
                                            ),
                                            onPressed: gameProvider.isLoading
                                                ? null
                                                : () {
                                                    _answerController.clear();
                                                    gameProvider.updateAnswer(
                                                      '',
                                                    );
                                                    setState(
                                                      () => _letterError = null,
                                                    );
                                                  },
                                          )
                                        : null,
                                  ),
                                  onChanged: (val) {
                                    gameProvider.updateAnswer(val);
                                    setState(() {});
                                    if (_letterError != null) {
                                      setState(() => _letterError = null);
                                    }
                                  },
                                ),
                              ),
                              // Error de letra
                              if (_letterError != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8, left: 16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.primaryRed,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        _letterError!,
                                        style: GoogleFonts.nunito(
                                          color: AppColors.primaryRed,
                                          fontSize: AppDimensions.fontSizeS(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Botón enviar
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.screenPadding(context),
                          ),
                          child: AppButton(
                            text: AppStrings.submitWord,
                            icon: Icons.send_rounded,
                            gradient:
                                gameProvider.currentAnswer.trim().isNotEmpty
                                ? AppColors.buttonBlueGradient
                                : null,
                            isLoading: gameProvider.isLoading,
                            onPressed:
                                (gameProvider.currentAnswer.trim().isNotEmpty &&
                                    !gameProvider.isLoading)
                                ? () =>
                                      _submitAnswer(uid, username, gameProvider)
                                : null,
                          ),
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

  Widget _buildTimer(int remaining, Color color, bool isUrgent) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isUrgent ? 0.35 : 0.15),
                blurRadius: isUrgent ? 20 : 10,
                spreadRadius: isUrgent ? 4 : 0,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: remaining / 30.0,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: AppColors.dividerColor,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$remaining',
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              'seg',
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeXS(context),
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLetterAndCategory(
    GameProvider gameProvider,
    Color timerColor,
    bool isUrgent,
  ) {
    return Column(
      children: [
        // Letra sin animaciones para evitar parpadeos
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.buttonRedGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withValues(
                  alpha: isUrgent ? 0.6 : 0.35,
                ),
                blurRadius: isUrgent ? 28 : 16,
                spreadRadius: isUrgent ? 6 : 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              gameProvider.currentLetter,
              style: GoogleFonts.nunito(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingM(context)),
        // Categoría
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL(context),
            vertical: AppDimensions.spacingS(context),
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusXXL(context),
            ),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            gameProvider.currentCategory,
            style: GoogleFonts.nunito(
              fontSize: AppDimensions.fontSizeXL(context),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingXS(context)),
        Text(
          '${AppStrings.wordStartsWith} "${gameProvider.currentLetter}"',
          style: GoogleFonts.nunito(
            fontSize: AppDimensions.fontSizeM(context),
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
