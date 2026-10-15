import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de badge asignado a una respuesta
enum VoteBadge {
  common, // Respuesta común
  excellent, // Respuesta excelente
  surprising; // Respuesta sorprendente

  /// Convierte desde un string de Firestore
  static VoteBadge fromString(String? value) {
    switch (value) {
      case 'excellent':
        return VoteBadge.excellent;
      case 'surprising':
        return VoteBadge.surprising;
      default:
        return VoteBadge.common;
    }
  }

  /// Nombre para mostrar en la UI (en español)
  String get displayName {
    switch (this) {
      case VoteBadge.common:
        return 'RESPUESTA COMÚN';
      case VoteBadge.excellent:
        return 'RESPUESTA EXCELENTE';
      case VoteBadge.surprising:
        return 'RESPUESTA SORPRENDENTE';
    }
  }

  /// Asset icon asociado al badge
  String get iconAsset {
    switch (this) {
      case VoteBadge.common:
        return 'assets/icons/respuesta_comun.svg';
      case VoteBadge.excellent:
        return 'assets/icons/respuesta_excelente.svg';
      case VoteBadge.surprising:
        return 'assets/icons/respuesta_sorprendente.svg';
    }
  }
}

/// Modelo de voto/calificación de un jugador.
/// Mapea a: /rooms/{roomCode}/rounds/{roundId}/responses/{letterId}/votes/{uid}
/// Cada jugador vota UNA vez por cada respuesta de otro jugador.
class VoteModel {
  final String voterId; // UID del jugador que vota
  final String voterUsername;
  final int score; // Calificación numérica (1-10)
  final VoteBadge badge; // Tipo de badge
  final DateTime votedAt;

  const VoteModel({
    required this.voterId,
    this.voterUsername = '',
    required this.score,
    this.badge = VoteBadge.common,
    required this.votedAt,
  });

  /// Constructor desde un documento de Firestore
  factory VoteModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    return VoteModel(
      voterId: documentId ?? json['voterId'] as String? ?? '',
      voterUsername: json['voterUsername'] as String? ?? '',
      score: (json['score'] as int?)?.clamp(1, 10) ?? 5,
      badge: VoteBadge.fromString(json['badge'] as String?),
      votedAt: _parseDateTime(json['votedAt']),
    );
  }

  /// Constructor desde un DocumentSnapshot de Firestore
  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VoteModel.fromJson(data, documentId: doc.id);
  }

  /// Convierte a Map para guardar en Firestore
  /// Nota: El voterId se usa como document ID, no se duplica en el body
  Map<String, dynamic> toJson() {
    return {
      'voterId': voterId,
      'voterUsername': voterUsername,
      'score': score.clamp(1, 10),
      'badge': badge.name,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }

  /// Crea una copia con campos modificados
  VoteModel copyWith({
    String? voterId,
    String? voterUsername,
    int? score,
    VoteBadge? badge,
    DateTime? votedAt,
  }) {
    return VoteModel(
      voterId: voterId ?? this.voterId,
      voterUsername: voterUsername ?? this.voterUsername,
      score: score ?? this.score,
      badge: badge ?? this.badge,
      votedAt: votedAt ?? this.votedAt,
    );
  }

  /// Valida que el score esté en el rango correcto
  bool get isValid => score >= 1 && score <= 10;

  /// Puntos bonus por badge (para cálculo de puntaje final)
  int get badgeBonus {
    switch (badge) {
      case VoteBadge.common:
        return 0;
      case VoteBadge.excellent:
        return 2;
      case VoteBadge.surprising:
        return 5;
    }
  }

  /// Puntaje total (score + bonus del badge)
  int get totalScore => score + badgeBonus;

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
      'VoteModel(voter: $voterId, score: $score, badge: ${badge.name})';
}
