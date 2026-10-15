import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla de configuración / perfil del usuario.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textDark,
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              AppStrings.settingsTitle,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppDimensions.spacingXL(context)),

                  // Avatar y nombre
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            user?.username.isNotEmpty == true
                                ? user!.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(height: AppDimensions.spacingM(context)),
                        Text(
                          user?.username ?? 'Jugador',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeXL(context),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS(context),
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppDimensions.spacingXXL(context)),

                  // Stats
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingL(context)),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXL(context),
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          label: 'Partidas',
                          value: '${user?.gamesPlayed ?? 0}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.dividerColor,
                        ),
                        _StatColumn(
                          label: 'Victorias',
                          value: '${user?.gamesWon ?? 0}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.dividerColor,
                        ),
                        _StatColumn(
                          label: 'Puntos',
                          value: '${user?.totalPoints ?? 0}',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppDimensions.spacingXXL(context)),

                  // Configuración de Audio
                  const _AudioSettingsSection(),

                  SizedBox(height: AppDimensions.spacingXXL(context)),

                  // Opciones
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: AppStrings.changePassword,
                    onTap: () => context.push(AppRoutes.changePassword),
                  ),

                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: AppStrings.about,
                    onTap: () => _showAboutDialog(context),
                  ),

                  SizedBox(height: AppDimensions.spacingXXL(context)),

                  // Botón cerrar sesión
                  AppButton.outline(
                    text: AppStrings.logout,
                    icon: Icons.logout,
                    color: AppColors.primaryRed,
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),

                  SizedBox(height: AppDimensions.spacingXXL(context)),

                  // Versión
                  Center(
                    child: Text(
                      'Word Wonders Link v1.0.0',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeXS(context),
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),

                  SizedBox(height: AppDimensions.spacingXL(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        ),
        title: const Text('Acerca de'),
        content: const Text(
          'Word Wonders Link v1.0.0\n\n'
          'Un juego multijugador de palabras en tiempo real.\n\n'
          '© 2026 Word Wonders Link',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingS(context)),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeXL(context),
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeXS(context),
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}

class _AudioSettingsSection extends StatefulWidget {
  const _AudioSettingsSection();

  @override
  State<_AudioSettingsSection> createState() => _AudioSettingsSectionState();
}

class _AudioSettingsSectionState extends State<_AudioSettingsSection> {
  final _audioService = AudioManagerService();

  late bool _musicEnabled;
  late bool _sfxEnabled;
  late double _musicVolume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    _musicEnabled = _audioService.musicEnabled;
    _sfxEnabled = _audioService.sfxEnabled;
    _musicVolume = _audioService.musicVolume;
    _sfxVolume = _audioService.sfxVolume;
  }

  void _onMusicToggle(bool value) {
    setState(() => _musicEnabled = value);
    _audioService.toggleMusic(value);
  }

  void _onSfxToggle(bool value) {
    setState(() => _sfxEnabled = value);
    _audioService.toggleSfx(value);
  }

  void _onMusicVolumeChange(double value) {
    setState(() => _musicVolume = value);
    _audioService.setMusicVolume(value);
  }

  void _onSfxVolumeChange(double value) {
    setState(() => _sfxVolume = value);
    _audioService.setSfxVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingL(context)),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: AppColors.primaryBlue),
              SizedBox(width: AppDimensions.spacingS(context)),
              Text(
                'Audio',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL(context),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingM(context)),
          const Divider(color: AppColors.dividerColor, thickness: 1.5),
          SizedBox(height: AppDimensions.spacingM(context)),

          // Música
          Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: AppColors.textGrey,
                size: 24,
              ),
              SizedBox(width: AppDimensions.spacingS(context)),
              Text(
                'Música',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Switch(
                value: _musicEnabled,
                onChanged: _onMusicToggle,
                activeTrackColor: AppColors.accentGreen,
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Volumen:',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _musicVolume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: AppColors.primaryBlue,
                  onChanged: _musicEnabled ? _onMusicVolumeChange : null,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(_musicVolume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS(context),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingM(context)),

          // Efectos de sonido
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.textGrey,
                size: 24,
              ),
              SizedBox(width: AppDimensions.spacingS(context)),
              Text(
                'Efectos',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Switch(
                value: _sfxEnabled,
                onChanged: _onSfxToggle,
                activeTrackColor: AppColors.accentGreen,
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Volumen:',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _sfxVolume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: AppColors.primaryBlue,
                  onChanged: _sfxEnabled ? _onSfxVolumeChange : null,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(_sfxVolume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS(context),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
