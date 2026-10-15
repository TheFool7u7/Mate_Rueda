import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManagerService {
  static final AudioManagerService _instance = AudioManagerService._internal();
  factory AudioManagerService() => _instance;
  AudioManagerService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();

  double _musicVolume = 0.5; // 0.0 a 1.0
  double _sfxVolume = 0.7;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  String? _currentTrack;

  // Getters
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.7;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
    _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;

    await _bgmPlayer.setVolume(_musicVolume);
  }

  Future<void> playTrack(String trackName, {bool loop = true}) async {
    if (!_musicEnabled) return;
    if (_currentTrack == trackName) return; // ya sonando

    _currentTrack = trackName;
    try {
      await _bgmPlayer.setAsset('assets/audio/$trackName');
      await _bgmPlayer.setVolume(_musicVolume);
      if (loop) {
        await _bgmPlayer.setLoopMode(LoopMode.one);
      } else {
        await _bgmPlayer.setLoopMode(LoopMode.off);
      }
      await _bgmPlayer.play();
    } catch (e) {
      // Si el asset no existe aún, ignorar el error por ahora
      debugPrint('Error reproduciendo audio $trackName: $e');
    }
  }

  Future<void> stopTrack() async {
    await _bgmPlayer.stop();
    _currentTrack = null;
  }

  Future<void> pauseTrack() async {
    await _bgmPlayer.pause();
  }

  Future<void> resumeTrack() async {
    if (_musicEnabled && _currentTrack != null) {
      await _bgmPlayer.play();
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    await _bgmPlayer.setVolume(volume);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', volume);
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', volume);
  }

  Future<void> toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await _bgmPlayer.pause();
    } else if (_currentTrack != null) {
      await _bgmPlayer.play();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
  }

  Future<void> toggleSfx(bool enabled) async {
    _sfxEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', enabled);
  }

  // --- SFX (Efectos de sonido) ---

  AudioPlayer? _loopSfxPlayer;

  Future<void> playSfx(String fileName) async {
    if (!_sfxEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setAsset('assets/audio/$fileName');
      await player.setVolume(_sfxVolume);
      player.play().then((_) => player.dispose());
    } catch (e) {
      debugPrint('Error reproduciendo sfx $fileName: $e');
    }
  }

  Future<void> startLoopSfx(String fileName) async {
    if (!_sfxEnabled) return;
    try {
      _loopSfxPlayer?.dispose();
      _loopSfxPlayer = AudioPlayer();
      await _loopSfxPlayer!.setAsset('assets/audio/$fileName');
      await _loopSfxPlayer!.setVolume(_sfxVolume);
      await _loopSfxPlayer!.setLoopMode(LoopMode.one);
      await _loopSfxPlayer!.play();
    } catch (e) {
      debugPrint('Error loop sfx $fileName: $e');
    }
  }

  Future<void> stopLoopSfx() async {
    await _loopSfxPlayer?.stop();
    await _loopSfxPlayer?.dispose();
    _loopSfxPlayer = null;
  }

  void dispose() {
    _bgmPlayer.dispose();
    _loopSfxPlayer?.dispose();
  }
}
