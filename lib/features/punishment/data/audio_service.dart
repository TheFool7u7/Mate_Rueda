import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:wordwonderslink/core/error/app_exceptions.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';

/// Servicio de audio para grabación (castigo cantar) y reproducción.
/// Usa `record` para grabar y `just_audio` para reproducir.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  Timer? _recordingTimer;
  String? _currentRecordingPath;

  // ── Getters ──

  /// Indica si se está grabando actualmente
  Future<bool> get isRecording => _recorder.isRecording();

  /// Indica si se está reproduciendo audio
  bool get isPlaying => _player.playing;

  /// Ruta del último archivo grabado
  String? get lastRecordingPath => _currentRecordingPath;

  /// Stream del estado de reproducción
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream de la posición de reproducción
  Stream<Duration> get positionStream => _player.positionStream;

  /// Duración total del audio cargado
  Duration? get duration => _player.duration;

  // ══════════════════════════════════════
  // GRABACIÓN
  // ══════════════════════════════════════

  /// Solicita permiso de micrófono
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw const PermissionException(
        message: 'Se requiere permiso de micrófono para grabar.',
      );
    }
    return true;
  }

  /// Inicia la grabación de audio.
  /// Se detiene automáticamente después de [maxSeconds] (default 30s).
  /// Retorna la ruta del archivo temporal donde se grabará.
  Future<String> startRecording({
    int maxSeconds = AppDimensions.maxPunishmentRecordingSeconds,
  }) async {
    try {
      await requestMicrophonePermission();

      // Verificar que el micrófono está disponible
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw const AudioException(
          message: 'No se puede acceder al micrófono.',
        );
      }

      // Generar ruta temporal para el archivo
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${dir.path}/punishment_$timestamp.m4a';

      // Configurar y comenzar grabación
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      // Timer de seguridad: detener después del máximo permitido
      _recordingTimer?.cancel();
      _recordingTimer = Timer(Duration(seconds: maxSeconds), () {
        stopRecording();
      });

      return _currentRecordingPath!;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AudioException(
        message: 'Error al iniciar grabación: $e',
        originalError: e,
      );
    }
  }

  /// Detiene la grabación y retorna la ruta del archivo grabado.
  /// Retorna null si no había grabación activa.
  Future<String?> stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final recording = await _recorder.isRecording();
      if (!recording) return _currentRecordingPath;

      final path = await _recorder.stop();
      _currentRecordingPath = path;

      // Verificar que el archivo existe y tiene contenido
      if (path != null) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          return path;
        }
      }

      return null;
    } catch (e) {
      throw AudioException(
        message: 'Error al detener grabación: $e',
        originalError: e,
      );
    }
  }

  /// Cancela la grabación actual y elimina el archivo
  Future<void> cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final recording = await _recorder.isRecording();
      if (recording) {
        await _recorder.stop();
      }

      // Eliminar archivo temporal si existe
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      // Silenciar errores de cancelación
    }
  }

  // ══════════════════════════════════════
  // REPRODUCCIÓN
  // ══════════════════════════════════════

  /// Reproduce un archivo de audio desde una URL (para escuchar castigos de otros)
  Future<void> playFromUrl(String url) async {
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      throw AudioException(
        message: 'Error al reproducir audio: $e',
        originalError: e,
      );
    }
  }

  /// Reproduce un archivo de audio local (preview antes de enviar)
  Future<void> playFromFile(String filePath) async {
    try {
      await _player.stop();
      await _player.setFilePath(filePath);
      await _player.play();
    } catch (e) {
      throw AudioException(
        message: 'Error al reproducir archivo: $e',
        originalError: e,
      );
    }
  }

  /// Pausa la reproducción actual
  Future<void> pause() async {
    await _player.pause();
  }

  /// Reanuda la reproducción
  Future<void> resume() async {
    await _player.play();
  }

  /// Detiene la reproducción
  Future<void> stop() async {
    await _player.stop();
  }

  /// Busca una posición específica en el audio
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Libera todos los recursos. Llamar al salir de la pantalla.
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final recording = await _recorder.isRecording();
      if (recording) {
        await _recorder.stop();
      }
    } catch (_) {}

    await _player.dispose();
    _recorder.dispose();
  }
}
