import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Servicio de Cloud Storage para archivos multimedia de castigos.
/// Almacena fotos (selfies, colores) y audios (cantar) en:
///   /punishments/{roomCode}/{uid}/{timestamp}
/// TTL de 24 horas configurado via Object Lifecycle Rules en Firebase Console.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Referencia base para castigos ──
  Reference _punishmentsRef(String roomCode, String uid) =>
      _storage.ref('punishments/$roomCode/$uid');

  // ══════════════════════════════════════
  // SUBIDA DE ARCHIVOS
  // ══════════════════════════════════════

  /// Sube una imagen (selfie o captura de color) a Storage.
  /// Retorna la URL de descarga pública.
  Future<String> uploadImage({
    required String roomCode,
    required String uid,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _punishmentsRef(roomCode, uid).child('$timestamp.jpg');

      // Configurar metadata del archivo
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'roomCode': roomCode,
          'uid': uid,
          'type': 'punishment_image',
          'uploadedAt': timestamp.toString(),
        },
      );

      // Subir archivo
      final uploadTask = await ref.putFile(imageFile, metadata);

      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al subir imagen: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error al subir imagen: $e',
        originalError: e,
      );
    }
  }

  /// Sube un archivo de audio (grabación de canto) a Storage.
  /// Retorna la URL de descarga pública.
  Future<String> uploadAudio({
    required String roomCode,
    required String uid,
    required String audioFilePath,
  }) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw const StorageException(
          message: 'El archivo de audio no existe.',
          code: 'file-not-found',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _punishmentsRef(roomCode, uid).child('$timestamp.m4a');

      final metadata = SettableMetadata(
        contentType: 'audio/mp4',
        customMetadata: {
          'roomCode': roomCode,
          'uid': uid,
          'type': 'punishment_audio',
          'uploadedAt': timestamp.toString(),
        },
      );

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al subir audio: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'Error al subir audio: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // DESCARGA / CONSULTA
  // ══════════════════════════════════════

  /// Obtiene la URL de descarga de un archivo por su ruta completa
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al obtener URL: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }

  /// Lista todos los archivos de castigos de una sala/jugador
  Future<List<String>> listPunishmentFiles(String roomCode, String uid) async {
    try {
      final ref = _punishmentsRef(roomCode, uid);
      final result = await ref.listAll();
      final urls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al listar archivos: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Elimina todos los archivos de castigos de una sala.
  /// Se usa al finalizar partida (además del TTL automático de 24h).
  Future<void> deletePunishmentFiles(String roomCode) async {
    try {
      final ref = _storage.ref('punishments/$roomCode');
      final result = await ref.listAll();

      // Eliminar archivos en subdirectorios (por jugador)
      for (final prefix in result.prefixes) {
        final subResult = await prefix.listAll();
        for (final item in subResult.items) {
          await item.delete();
        }
      }

      // Eliminar archivos directos (si los hay)
      for (final item in result.items) {
        await item.delete();
      }
    } on FirebaseException catch (e) {
      // No lanzar error si la carpeta no existe
      if (e.code == 'object-not-found') return;
      throw StorageException(
        message: 'Error al eliminar archivos: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }
}
