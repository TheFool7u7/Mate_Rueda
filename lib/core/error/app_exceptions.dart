// Excepciones personalizadas de Word Wonders Link.
// Cada capa del sistema lanza la excepción apropiada para que
// los providers puedan mostrar mensajes amigables al usuario.

/// Excepción base de la aplicación
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({required this.message, this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

/// Error de autenticación (login, registro, cambio de contraseña)
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Error de red / conexión
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Error de conexión. Verifica tu internet.',
    super.code = 'network-error',
    super.originalError,
  });
}

/// Error de Firestore (lectura/escritura de datos)
class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Error de Realtime Database (estado en vivo del juego)
class RealtimeDbException extends AppException {
  const RealtimeDbException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Error de Storage (subida/descarga de archivos)
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Error de sala (sala no encontrada, llena, etc.)
class RoomException extends AppException {
  const RoomException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Error de juego (turno inválido, letra ya tomada, etc.)
class GameException extends AppException {
  const GameException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Error de cámara
class AppCameraException extends AppException {
  const AppCameraException({
    required super.message,
    super.code = 'camera-error',
    super.originalError,
  });
}

/// Error de audio (grabación / reproducción)
class AudioException extends AppException {
  const AudioException({
    required super.message,
    super.code = 'audio-error',
    super.originalError,
  });
}

/// Error de permisos (cámara, micrófono, etc.)
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code = 'permission-denied',
    super.originalError,
  });
}
