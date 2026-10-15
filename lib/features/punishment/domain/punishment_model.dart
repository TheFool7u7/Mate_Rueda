import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de castigo disponibles
enum PunishmentType {
  selfie, // Tomar una selfie
  sing, // Cantar una canción (grabación de audio)
  findColor; // Encontrar un objeto del color indicado

  /// Convierte desde un string de la base de datos
  static PunishmentType fromString(String? value) {
    switch (value) {
      case 'sing':
        return PunishmentType.sing;
      case 'findColor':
        return PunishmentType.findColor;
      default:
        return PunishmentType.selfie;
    }
  }

  /// Nombre para mostrar en la UI (en español)
  String get displayName {
    switch (this) {
      case PunishmentType.selfie:
        return '¡Tómate una selfie!';
      case PunishmentType.sing:
        return '¡Canta una canción!';
      case PunishmentType.findColor:
        return '¡Encuentra el color!';
    }
  }

  /// Icono SVG asociado al tipo de castigo
  String get iconAsset {
    switch (this) {
      case PunishmentType.selfie:
        return 'assets/icons/selfie.svg';
      case PunishmentType.sing:
        return 'assets/icons/notas_musicales.svg';
      case PunishmentType.findColor:
        return 'assets/icons/camara.svg';
    }
  }

  /// Descripción corta para la UI
  String get description {
    switch (this) {
      case PunishmentType.selfie:
        return 'Tómate una selfie y compártela con todos los jugadores';
      case PunishmentType.sing:
        return 'Graba un fragmento de tu canción favorita (máx 30s)';
      case PunishmentType.findColor:
        return 'Busca un objeto del color indicado y captura la foto';
    }
  }
}

/// Estado del castigo
enum PunishmentStatus {
  pending, // Aún no se ha ejecutado
  inProgress, // El jugador está ejecutando el castigo
  completed, // Castigo completado exitosamente
  skipped; // El jugador se saltó el castigo

  static PunishmentStatus fromString(String? value) {
    switch (value) {
      case 'inProgress':
        return PunishmentStatus.inProgress;
      case 'completed':
        return PunishmentStatus.completed;
      case 'skipped':
        return PunishmentStatus.skipped;
      default:
        return PunishmentStatus.pending;
    }
  }
}

/// Modelo de castigo para el jugador con menos puntos.
/// El archivo multimedia se almacena en Cloud Storage:
/// /punishments/{roomCode}/{uid}/{timestamp}
class PunishmentModel {
  final String punishmentId;
  final String roomCode;
  final String playerUid;
  final String playerUsername;
  final PunishmentType type;
  final PunishmentStatus status;
  final String? mediaUrl; // URL del archivo en Storage (foto o audio)
  final String? targetColor; // Solo para findColor (ej: "ROJO")
  final int? durationSeconds; // Solo para sing (duración de la grabación)
  final DateTime createdAt;
  final DateTime? completedAt;

  const PunishmentModel({
    required this.punishmentId,
    required this.roomCode,
    required this.playerUid,
    this.playerUsername = '',
    required this.type,
    this.status = PunishmentStatus.pending,
    this.mediaUrl,
    this.targetColor,
    this.durationSeconds,
    required this.createdAt,
    this.completedAt,
  });

  /// Constructor desde un Map (Firestore o RTDB)
  factory PunishmentModel.fromJson(
    Map<String, dynamic> json, {
    String? documentId,
  }) {
    return PunishmentModel(
      punishmentId: documentId ?? json['punishmentId'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      playerUid: json['playerUid'] as String? ?? '',
      playerUsername: json['playerUsername'] as String? ?? '',
      type: PunishmentType.fromString(json['type'] as String?),
      status: PunishmentStatus.fromString(json['status'] as String?),
      mediaUrl: json['mediaUrl'] as String?,
      targetColor: json['targetColor'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      createdAt: _parseDateTime(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? _parseDateTime(json['completedAt'])
          : null,
    );
  }

  /// Constructor desde un DocumentSnapshot de Firestore
  factory PunishmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PunishmentModel.fromJson(data, documentId: doc.id);
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'punishmentId': punishmentId,
      'roomCode': roomCode,
      'playerUid': playerUid,
      'playerUsername': playerUsername,
      'type': type.name,
      'status': status.name,
      'mediaUrl': mediaUrl,
      'targetColor': targetColor,
      'durationSeconds': durationSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  /// Crea una copia con campos modificados
  PunishmentModel copyWith({
    String? punishmentId,
    String? roomCode,
    String? playerUid,
    String? playerUsername,
    PunishmentType? type,
    PunishmentStatus? status,
    String? mediaUrl,
    String? targetColor,
    int? durationSeconds,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PunishmentModel(
      punishmentId: punishmentId ?? this.punishmentId,
      roomCode: roomCode ?? this.roomCode,
      playerUid: playerUid ?? this.playerUid,
      playerUsername: playerUsername ?? this.playerUsername,
      type: type ?? this.type,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      targetColor: targetColor ?? this.targetColor,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Ruta en Cloud Storage para el archivo multimedia
  String get storagePath =>
      'punishments/$roomCode/$playerUid/${createdAt.millisecondsSinceEpoch}';

  /// Verifica si el castigo ya fue completado
  bool get isCompleted => status == PunishmentStatus.completed;

  /// Verifica si el castigo requiere cámara
  bool get requiresCamera =>
      type == PunishmentType.selfie || type == PunishmentType.findColor;

  /// Verifica si el castigo requiere micrófono
  bool get requiresMicrophone => type == PunishmentType.sing;

  /// Verifica si tiene un archivo multimedia subido
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Colores disponibles para el castigo "Encontrar color"
  static const List<String> availableColors = [
    'ROJO',
    'AZUL',
    'VERDE',
    'AMARILLO',
    'NARANJA',
    'MORADO',
    'ROSA',
    'BLANCO',
    'NEGRO',
    'MARRÓN',
  ];

  /// Helper para parsear DateTime desde Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  String toString() =>
      'PunishmentModel(id: $punishmentId, type: ${type.name}, '
      'status: ${status.name}, player: $playerUid)';
}
