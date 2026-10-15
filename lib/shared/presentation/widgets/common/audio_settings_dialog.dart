import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';

class AudioSettingsDialog extends StatefulWidget {
  const AudioSettingsDialog({super.key});

  @override
  State<AudioSettingsDialog> createState() => _AudioSettingsDialogState();
}

class _AudioSettingsDialogState extends State<AudioSettingsDialog> {
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
      ),
      backgroundColor: AppColors.cardWhite,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
                SizedBox(width: AppDimensions.spacingM(context)),
                Text(
                  'Audio',
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeXL(context),
                    fontWeight: FontWeight.w900,
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
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeL(context),
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
                  style: GoogleFonts.nunito(
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
                    style: GoogleFonts.nunito(
                      fontSize: AppDimensions.fontSizeS(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacingL(context)),

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
                  style: GoogleFonts.nunito(
                    fontSize: AppDimensions.fontSizeL(context),
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
                  style: GoogleFonts.nunito(
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
                    style: GoogleFonts.nunito(
                      fontSize: AppDimensions.fontSizeS(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimensions.spacingXL(context)),

            // CERRAR
            AppButton.blue(
              text: 'CERRAR',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
