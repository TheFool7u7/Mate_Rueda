import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:wordwonderslink/features/punishment/domain/punishment_model.dart';
import 'package:wordwonderslink/features/punishment/data/camera_service.dart';
import 'package:wordwonderslink/features/punishment/data/audio_service.dart';
import 'package:wordwonderslink/features/punishment/data/storage_service.dart';
import 'package:wordwonderslink/features/game/data/realtime_db_service.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Provider de castigos.
/// Gestiona: selección aleatoria de castigo, cámara, grabación, subida a Storage.
class PunishmentProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  final RealtimeDbService _rtdbService = RealtimeDbService();

  // ── Estado ──
  PunishmentModel? _currentPunishment;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isUploading = false;
  String? _errorMessage;
  File? _capturedPhoto;
  String? _recordedAudioPath;
  String? _uploadedMediaUrl;

  // ── Getters ──
  PunishmentModel? get currentPunishment => _currentPunishment;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  File? get capturedPhoto => _capturedPhoto;
  String? get recordedAudioPath => _recordedAudioPath;
  String? get uploadedMediaUrl => _uploadedMediaUrl;
  CameraService get cameraService => _cameraService;
  AudioService get audioService => _audioService;
  bool get hasMedia => _capturedPhoto != null || _recordedAudioPath != null;
  bool get isCompleted =>
      _currentPunishment?.status == PunishmentStatus.completed;

  // ══════════════════════════════════════
  // SELECCIÓN DE CASTIGO
  // ══════════════════════════════════════

  /// Selecciona un castigo aleatorio para el jugador con menos puntos
  Future<void> assignRandomPunishment({
    required String roomCode,
    required String playerUid,
    required String playerUsername,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _capturedPhoto = null;
    _recordedAudioPath = null;
    _uploadedMediaUrl = null;

    try {
      // Seleccionar tipo aleatorio
      final random = Random();
      final types = PunishmentType.values;
      final selectedType = types[random.nextInt(types.length)];

      // Para "findColor", elegir un color aleatorio
      String? targetColor;
      if (selectedType == PunishmentType.findColor) {
        final colors = PunishmentModel.availableColors;
        targetColor = colors[random.nextInt(colors.length)];
      }

      _currentPunishment = PunishmentModel(
        punishmentId:
            '${roomCode}_${playerUid}_${DateTime.now().millisecondsSinceEpoch}',
        roomCode: roomCode,
        playerUid: playerUid,
        playerUsername: playerUsername,
        type: selectedType,
        status: PunishmentStatus.pending,
        targetColor: targetColor,
        createdAt: DateTime.now(),
      );

      // Inicializar cámara o micrófono según el tipo
      if (_currentPunishment!.requiresCamera) {
        final useFront = selectedType == PunishmentType.selfie;
        await _cameraService.initialize(useFrontCamera: useFront);
      }
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error al asignar castigo: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Limpia todo el estado del castigo anterior.
  /// Debe llamarse cuando el castigado entra a la pantalla de castigo
  /// para garantizar que no queda caché de una partida anterior.
  void clearPunishment() {
    try {
      _audioService.stop();
    } catch (_) {}
    try {
      _cameraService.dispose();
    } catch (_) {}
    _currentPunishment = null;
    _capturedPhoto = null;
    _recordedAudioPath = null;
    _uploadedMediaUrl = null;
    _isLoading = false;
    _isRecording = false;
    _isUploading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // SELFIE / ENCONTRAR COLOR
  // ══════════════════════════════════════

  /// Captura una foto (selfie o color)
  Future<void> takePhoto() async {
    _errorMessage = null;

    try {
      _capturedPhoto = await _cameraService.takePhoto();
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al tomar foto: $e';
      notifyListeners();
    }
  }

  /// Descarta la foto capturada y permite tomar otra
  void retakePhoto() {
    _capturedPhoto = null;
    notifyListeners();
  }

  /// Alterna la cámara (frontal/trasera)
  Future<void> switchCamera() async {
    try {
      await _cameraService.switchCamera();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cambiar cámara: $e');
    }
  }

  // ══════════════════════════════════════
  // CANTAR (GRABACIÓN DE AUDIO)
  // ══════════════════════════════════════

  /// Inicia la grabación de audio
  Future<void> startRecording() async {
    _errorMessage = null;

    try {
      await _audioService.startRecording();
      _isRecording = true;
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al iniciar grabación: $e';
      notifyListeners();
    }
  }

  /// Detiene la grabación
  Future<void> stopRecording() async {
    try {
      _recordedAudioPath = await _audioService.stopRecording();
      _isRecording = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al detener grabación: $e';
      _isRecording = false;
      notifyListeners();
    }
  }

  /// Reproduce el audio grabado (preview)
  Future<void> playRecording() async {
    if (_recordedAudioPath != null) {
      await _audioService.playFromFile(_recordedAudioPath!);
    }
  }

  /// Detiene la reproducción del preview
  Future<void> stopPlayback() async {
    await _audioService.stop();
  }

  /// Descarta la grabación y permite grabar de nuevo
  Future<void> discardRecording() async {
    await _audioService.cancelRecording();
    _recordedAudioPath = null;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // SUBIDA Y FINALIZACIÓN
  // ══════════════════════════════════════

  /// Sube el archivo multimedia a Storage, lo publica en RTDB para que todos
  /// lo vean y, tras 15 segundos de visualización, avanza la fase a "results".
  Future<String?> submitPunishment() async {
    if (_currentPunishment == null) return null;

    debugPrint('=== CASTIGO: Iniciando subida...');
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String mediaUrl;
      final String type = _currentPunishment!.type == PunishmentType.sing
          ? 'audio'
          : 'photo';

      if (_currentPunishment!.type == PunishmentType.sing) {
        // Subir audio
        if (_recordedAudioPath == null) {
          _errorMessage = 'No hay grabación para enviar.';
          _isUploading = false;
          notifyListeners();
          return null;
        }
        mediaUrl = await _storageService.uploadAudio(
          roomCode: _currentPunishment!.roomCode,
          uid: _currentPunishment!.playerUid,
          audioFilePath: _recordedAudioPath!,
        );
      } else {
        // Subir imagen (selfie o color)
        if (_capturedPhoto == null) {
          _errorMessage = 'No hay foto para enviar.';
          _isUploading = false;
          notifyListeners();
          return null;
        }
        mediaUrl = await _storageService.uploadImage(
          roomCode: _currentPunishment!.roomCode,
          uid: _currentPunishment!.playerUid,
          imageFile: _capturedPhoto!,
        );
      }

      // Actualizar modelo con URL y estado completado
      _currentPunishment = _currentPunishment!.copyWith(
        status: PunishmentStatus.completed,
        mediaUrl: mediaUrl,
        completedAt: DateTime.now(),
      );

      _uploadedMediaUrl = mediaUrl;
      debugPrint('=== CASTIGO: URL obtenida: $mediaUrl');

      // 1. Publicar URL en RTDB → todos ven la multimedia inmediatamente
      debugPrint('=== CASTIGO: Guardando en RTDB...');
      // Capturar roomCode ahora antes de cualquier await largo (evita NPE si el provider se resetea)
      final roomCode = _currentPunishment!.roomCode;
      await _rtdbService.setPunishmentMedia(
        roomCode: roomCode,
        mediaUrl: mediaUrl,
        punishmentType: type,
        targetColor: _currentPunishment!.targetColor,
      );

      _isUploading = false;
      notifyListeners();

      // 2. Esperar para que TODOS vean el castigo antes de avanzar
      // Audio: 45 segundos (tiempo para escuchar la grabación)
      // Foto: 15 segundos (tiempo para ver la imagen)
      final delaySeconds = type == 'audio' ? 45 : 15;
      debugPrint(
        '=== CASTIGO: Esperando $delaySeconds segundos para visualización...',
      );
      await Future.delayed(Duration(seconds: delaySeconds));

      // 3. Avanzar fase a resultados
      debugPrint(
        '=== CASTIGO: Cambiando fase a results (roomCode=$roomCode)...',
      );
      await _rtdbService.updateGamePhase(roomCode, GamePhase.results);

      debugPrint('=== CASTIGO: Fase cambiada a results exitosamente.');
      return mediaUrl;
    } on AppException catch (e) {
      debugPrint('=== CASTIGO ERROR (AppException): ${e.message}');
      _errorMessage = e.message;
      return null;
    } catch (e) {
      debugPrint('=== CASTIGO ERROR (catch): $e');
      _errorMessage = 'Error al enviar castigo: $e';
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Salta el castigo (el jugador no quiere hacerlo)
  Future<void> skipPunishment() async {
    if (_currentPunishment == null) return;

    _currentPunishment = _currentPunishment!.copyWith(
      status: PunishmentStatus.skipped,
    );

    try {
      await _rtdbService.updateGamePhase(
        _currentPunishment!.roomCode,
        GamePhase.results,
      );
    } catch (e) {
      debugPrint('Error al saltar castigo: $e');
    }

    notifyListeners();
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Resetea todo el estado del castigo
  Future<void> reset() async {
    await _cameraService.dispose();
    await _audioService.dispose();

    _currentPunishment = null;
    _capturedPhoto = null;
    _recordedAudioPath = null;
    _uploadedMediaUrl = null;
    _isRecording = false;
    _isUploading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
