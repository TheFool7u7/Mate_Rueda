/// Estado posible de una letra en la rueda
enum LetterStatus {
  free, // Disponible para reclamar
  locked, // Reclamada temporalmente por un jugador (respondiendo)
  used; // Ya fue usada en una respuesta

  /// Convierte desde un string de la base de datos
  static LetterStatus fromString(String? value) {
    switch (value) {
      case 'locked':
        return LetterStatus.locked;
      case 'used':
        return LetterStatus.used;
      default:
        return LetterStatus.free;
    }
  }
}

/// Modelo de una letra individual en la rueda de letras.
/// Se usa tanto en Firestore (embebido en RoundModel) como en
/// Realtime Database (/games/{roomCode}/letters/{char}) para el
/// bloqueo atómico en tiempo real.
class LetterModel {
  final String char;
  final LetterStatus status;
  final String? claimedBy; // UID del jugador que la reclamó
  final String? claimedByUsername;

  const LetterModel({
    required this.char,
    this.status = LetterStatus.free,
    this.claimedBy,
    this.claimedByUsername,
  });

  /// Constructor desde un Map (Firestore o RTDB)
  factory LetterModel.fromJson(Map<String, dynamic> json) {
    return LetterModel(
      char: json['char'] as String? ?? '',
      status: LetterStatus.fromString(json['status'] as String?),
      claimedBy: json['claimedBy'] as String?,
      claimedByUsername: json['claimedByUsername'] as String?,
    );
  }

  /// Constructor desde un snapshot de Realtime Database
  /// La key del snapshot es el carácter de la letra
  factory LetterModel.fromRtdb(String char, Map<String, dynamic> json) {
    return LetterModel(
      char: char,
      status: LetterStatus.fromString(json['status'] as String?),
      claimedBy: json['lockedBy'] as String?,
      claimedByUsername: json['lockedByUsername'] as String?,
    );
  }

  /// Convierte a Map para Firestore (embebido en RoundModel)
  Map<String, dynamic> toJson() {
    return {
      'char': char,
      'status': status.name,
      'claimedBy': claimedBy,
      'claimedByUsername': claimedByUsername,
    };
  }

  /// Convierte a Map para Realtime Database
  /// Usa 'lockedBy' en lugar de 'claimedBy' para el esquema RTDB
  Map<String, dynamic> toRtdb() {
    return {
      'status': status.name,
      'lockedBy': claimedBy,
      'lockedByUsername': claimedByUsername,
    };
  }

  /// Crea una copia con campos modificados
  LetterModel copyWith({
    String? char,
    LetterStatus? status,
    String? claimedBy,
    String? claimedByUsername,
  }) {
    return LetterModel(
      char: char ?? this.char,
      status: status ?? this.status,
      claimedBy: claimedBy ?? this.claimedBy,
      claimedByUsername: claimedByUsername ?? this.claimedByUsername,
    );
  }

  /// Verifica si la letra está disponible para reclamar
  bool get isFree => status == LetterStatus.free;

  /// Verifica si la letra está bloqueada por alguien
  bool get isLocked => status == LetterStatus.locked;

  /// Verifica si la letra ya fue usada
  bool get isUsed => status == LetterStatus.used;

  /// Verifica si un jugador específico tiene esta letra bloqueada
  bool isLockedBy(String uid) => isLocked && claimedBy == uid;

  @override
  String toString() =>
      'LetterModel(char: $char, status: ${status.name}, claimedBy: $claimedBy)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LetterModel &&
          runtimeType == other.runtimeType &&
          char == other.char;

  @override
  int get hashCode => char.hashCode;
}
