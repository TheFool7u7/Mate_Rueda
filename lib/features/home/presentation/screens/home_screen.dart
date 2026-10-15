import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/core/services/version_service.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_background.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/audio_settings_dialog.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_text_field.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';
import 'package:wordwonderslink/features/room/data/firestore_service.dart';
import 'package:wordwonderslink/features/auth/domain/user_model.dart';

/// Pantalla principal / menÃº del juego.
/// Muestra leaderboard, botones de crear/unirse y configuraciÃ³n.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _topPlayers = [];

  bool _nicknameDialogShown = false;

  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
    _loadLeaderboard();
    
    // Check for mandatory updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        VersionService.checkVersion(context);
      }
    });
  }

  Future<void> _loadLeaderboard() async {
    try {
      final players = await _firestoreService.getTopPlayers(limit: 4);
      if (mounted) setState(() => _topPlayers = players);
    } catch (e) {
      debugPrint('Error cargando leaderboard: $e');
    }
  }

  void _checkNickname(UserModel user) {
    if (_nicknameDialogShown) return;
    final un = user.username;
    if (un.length < 6 || un.length > 12 || un == 'Jugador') {
      _nicknameDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: _NicknameDialog(
              onSave: (newNickname) async {
                final auth = context.read<AuthProvider>();
                await auth.updateUsername(newNickname);
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        if (user != null) {
          _checkNickname(user);
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: AppBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppDimensions.spacingL(context)),

                        // Barra superior: saludo + settings
                        _buildTopBar(user?.username ?? 'Jugador'),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Logo compacto
                        _buildCompactLogo(),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Botones principales
                        AppButton.red(
                          text: AppStrings.createRoom,
                          icon: Icons.add_circle_outline,
                          onPressed: () => context.push(AppRoutes.createRoom),
                        ),

                        SizedBox(height: AppDimensions.spacingM(context)),

                        AppButton.blue(
                          text: AppStrings.joinRoom,
                          icon: Icons.login_rounded,
                          onPressed: () => context.push(AppRoutes.joinRoom),
                        ),

                        SizedBox(height: AppDimensions.spacingM(context)),

                        AppButton.green(
                          text: AppStrings.howToPlay,
                          icon: Icons.help_outline,
                          onPressed: () => _showHowToPlay(),
                        ),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Leaderboard mini
                        _buildLeaderboard(),

                        SizedBox(height: AppDimensions.spacingXXL(context)),

                        // Stats del jugador
                        if (user != null) _buildUserStats(user),

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

  Widget _buildTopBar(String username) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL(context),
        vertical: AppDimensions.spacingM(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcon.saludo, size: 26),
                    SizedBox(width: AppDimensions.spacingS(context)),
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                            fontSize: AppDimensions.fontSizeXL(context),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          children: [
                            const TextSpan(text: '¡Hola, '),
                            TextSpan(
                              text: username,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const TextSpan(text: '!'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.readyToPlay,
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeS(context),
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.spacingM(context)),
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
          SizedBox(width: AppDimensions.spacingS(context)),
          GestureDetector(
            onTap: () => context.push(AppRoutes.settings),
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
                Icons.settings_rounded,
                color: AppColors.textDark,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo circular con efecto glow
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Logo encima
          Image.asset('assets/images/logo.png', height: 110),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header con gradiente dorado
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL(context),
              vertical: AppDimensions.spacingM(context),
            ),
            decoration: const BoxDecoration(gradient: AppColors.goldGradient),
            child: Row(
              children: [
                AppIcon(AppIcon.topJugadores, size: 24, color: Colors.white),
                SizedBox(width: AppDimensions.spacingS(context)),
                Text(
                  AppStrings.topPlayers,
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeL(context),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Contenido del leaderboard
          Padding(
            padding: EdgeInsets.all(AppDimensions.spacingM(context)),
            child: Column(
              children: [
                if (_topPlayers.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL(context)),
                    child: Text(
                      AppStrings.noPlayersYet,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(color: AppColors.textGrey),
                    ),
                  )
                else
                  ..._topPlayers.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final player = entry.value;
                    final medalAssets = [
                      AppIcon.medallaOro,
                      AppIcon.medallaPlata,
                      AppIcon.medallaBronce,
                      AppIcon.medallaSinRango,
                    ];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: AppDimensions.spacingS(context),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingM(context),
                          vertical: AppDimensions.spacingM(context),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusL(context),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            rank <= 4
                                ? AppIcon(medalAssets[rank - 1], size: 28)
                                : Text(
                                    '$rank',
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                            SizedBox(width: AppDimensions.spacingM(context)),
                            Expanded(
                              child: Text(
                                player['username'] as String? ?? 'Jugador',
                                style: GoogleFonts.nunito(
                                  fontSize: rank == 1
                                      ? AppDimensions.fontSizeL(context)
                                      : AppDimensions.fontSizeM(context),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${player['totalPoints'] ?? 0} pts',
                              style: GoogleFonts.nunito(
                                fontSize: AppDimensions.fontSizeM(context),
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(dynamic user) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingL(context)),
      decoration: BoxDecoration(
        gradient: AppColors.statsGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _StatItem(
                label: 'Partidas',
                value: '${user.gamesPlayed}',
                iconAsset: AppIcon.control,
              ),
            ),
            // Divisor vertical
            Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
              child: _StatItem(
                label: 'Victorias',
                value: '${user.gamesWon}',
                iconAsset: AppIcon.trofeo,
              ),
            ),
            // Divisor vertical
            Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
              child: _StatItem(
                label: 'Puntos',
                value: '${user.totalPoints}',
                iconAsset: AppIcon.puntos,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXXL(context)),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Gradient header area
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.buttonBlueGradient,
                ),
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.spacingXL(context),
                  AppDimensions.spacingM(context),
                  AppDimensions.spacingXL(context),
                  AppDimensions.spacingXL(context),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingL(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(AppIcon.libro, size: 32, color: Colors.white),
                        SizedBox(width: AppDimensions.spacingS(context)),
                        Text(
                          '¿Cómo se juega?',
                          style: GoogleFonts.nunito(
                            fontSize: AppDimensions.fontSizeXL(context),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista scrolleable
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.spacingXL(context),
                    AppDimensions.spacingL(context),
                    AppDimensions.spacingXL(context),
                    AppDimensions.spacingXXL(context),
                  ),
                  children: [
                    ...AppStrings.howToPlaySteps.asMap().entries.map((e) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: AppDimensions.spacingM(context),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: AppColors.buttonBlueGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppDimensions.spacingM(context)),
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.nunito(
                                  fontSize: AppDimensions.fontSizeM(context),
                                  color: AppColors.textDark,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String iconAsset;

  const _StatItem({
    required this.label,
    required this.value,
    required this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(iconAsset, size: 32, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: AppDimensions.fontSizeXL(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: AppDimensions.fontSizeXS(context),
          ),
        ),
      ],
    );
  }
}

class _NicknameDialog extends StatefulWidget {
  final Future<void> Function(String) onSave;

  const _NicknameDialog({required this.onSave});

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _submit() async {
    final text = _controller.text.trim();
    if (text.length < 6 || text.length > 12) {
      setState(() => _error = 'Debe tener entre 6 y 12 caracteres');
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await widget.onSave(text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al guardar. Intenta de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(AppDimensions.spacingXL(context)),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_pin_rounded,
                color: AppColors.primaryBlue,
                size: 40,
              ),
            ),
            SizedBox(height: AppDimensions.spacingM(context)),
            Text(
              '¡Elige tu Nickname!',
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeXL(context),
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingS(context)),
            Text(
              'Para jugar, necesitas un nombre único de 6 a 12 caracteres.',
              style: GoogleFonts.nunito(
                fontSize: AppDimensions.fontSizeS(context),
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingL(context)),
            AppTextField(
              controller: _controller,
              label: 'Nickname',
              hintText: 'Ej. JuanPerez',
              keyboardType: TextInputType.name,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              SizedBox(height: AppDimensions.spacingS(context)),
              Text(
                _error!,
                style: GoogleFonts.nunito(
                  color: AppColors.primaryRed,
                  fontSize: AppDimensions.fontSizeS(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: AppDimensions.spacingXL(context)),
            _isLoading
                ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                : AppButton.blue(text: 'Guardar', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
