import 'dart:io';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Servicio de cámara nativa para castigos (selfie y encontrar color).
/// Gestiona: inicialización, preview, captura de fotos, cambio de cámara.
/// Usa el plugin `camera` y `permission_handler` para permisos.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _currentCameraIndex = 0;

  // ── Getters ──

  /// Controller actual de la cámara (para CameraPreview)
  CameraController? get controller => _controller;

  /// Indica si la cámara está lista para usarse
  bool get isInitialized =>
      _isInitialized && (_controller?.value.isInitialized ?? false);

  /// Lista de cámaras disponibles en el dispositivo
  List<CameraDescription> get cameras => _cameras;

  // ══════════════════════════════════════
  // INICIALIZACIÓN
  // ══════════════════════════════════════

  /// Solicita permiso de cámara y lista las cámaras disponibles
  Future<void> requestPermissionAndLoadCameras() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw const PermissionException(
          message: 'Se requiere permiso de cámara para este castigo.',
        );
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw const AppCameraException(
          message: 'No se encontraron cámaras en el dispositivo.',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppCameraException(
        message: 'Error al inicializar cámaras: $e',
        originalError: e,
      );
    }
  }

  /// Inicializa la cámara frontal (para selfie) o trasera (para color).
  /// [useFrontCamera] = true para selfie, false para encontrar color.
  Future<void> initialize({bool useFrontCamera = true}) async {
    try {
      await requestPermissionAndLoadCameras();

      // Buscar la cámara apropiada
      _currentCameraIndex = _cameras.indexWhere(
        (camera) =>
            camera.lensDirection ==
            (useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
      );

      // Fallback a la primera cámara si no se encuentra
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;

      await _initController(_cameras[_currentCameraIndex]);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppCameraException(
        message: 'Error al inicializar cámara: $e',
        originalError: e,
      );
    }
  }

  /// Inicializa el controller con una cámara específica
  Future<void> _initController(CameraDescription camera) async {
    // Liberar controller anterior si existe
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  // ══════════════════════════════════════
  // CAPTURA DE FOTOS
  // ══════════════════════════════════════

  /// Captura una foto y retorna el archivo.
  /// Lanza [AppCameraException] si la cámara no está inicializada.
  Future<File> takePhoto() async {
    if (!isInitialized) {
      throw const AppCameraException(
        message: 'La cámara no está inicializada.',
      );
    }

    try {
      final xFile = await _controller!.takePicture();
      return File(xFile.path);
    } catch (e) {
      throw AppCameraException(
        message: 'Error al tomar la foto: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // CAMBIO DE CÁMARA
  // ══════════════════════════════════════

  /// Alterna entre cámara frontal y trasera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
      await _initController(_cameras[_currentCameraIndex]);
    } catch (e) {
      throw AppCameraException(
        message: 'Error al cambiar de cámara: $e',
        originalError: e,
      );
    }
  }

  /// Verifica si se puede alternar la cámara
  bool get canSwitchCamera => _cameras.length >= 2;

  // ══════════════════════════════════════
  // FLASH
  // ══════════════════════════════════════

  /// Activa o desactiva el flash
  Future<void> setFlashMode(FlashMode mode) async {
    if (!isInitialized) return;
    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      // No lanzar error por flash, no es crítico
    }
  }

  /// Alterna el flash (off → on → auto → off)
  Future<FlashMode> toggleFlash() async {
    if (!isInitialized) return FlashMode.off;

    final currentMode = _controller!.value.flashMode;
    FlashMode nextMode;

    switch (currentMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      default:
        nextMode = FlashMode.off;
    }

    await setFlashMode(nextMode);
    return nextMode;
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Libera los recursos de la cámara. Llamar al salir de la pantalla.
  Future<void> dispose() async {
    _isInitialized = false;
    await _controller?.dispose();
    _controller = null;
  }
}
