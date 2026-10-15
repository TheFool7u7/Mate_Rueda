import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuario de Word Wonders Link.
/// Mapea a Firestore: /users/{uid}
/// Contiene perfil, estadísticas y metadata de creación.
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String avatarUrl;
  final int totalPoints;
  final int gamesPlayed;
  final int gamesWon;
  final DateTime createdAt;
  final bool isDisabled;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl = '',
    this.totalPoints = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    required this.createdAt,
    this.isDisabled = false,
  });

  /// Constructor desde un documento de Firestore
  factory UserModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    return UserModel(
      uid: documentId ?? json['uid'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      isDisabled: json['isDisabled'] as bool? ?? false,
    );
  }

  /// Constructor desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data, documentId: doc.id);
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDisabled': isDisabled,
    };
  }

  /// Crea una copia con campos modificados
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? avatarUrl,
    int? totalPoints,
    int? gamesPlayed,
    int? gamesWon,
    DateTime? createdAt,
    bool? isDisabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      createdAt: createdAt ?? this.createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  /// Datos mínimos para embeber en la lista de jugadores de una sala
  Map<String, dynamic> toPlayerRef() {
    return {'uid': uid, 'username': username, 'avatarUrl': avatarUrl};
  }

  /// Datos para el leaderboard (/leaderboard/{uid})
  Map<String, dynamic> toLeaderboard() {
    return {'username': username, 'totalPoints': totalPoints};
  }

  /// Helper para parsear DateTime desde Firestore (Timestamp o int)
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
      'UserModel(uid: $uid, username: $username, pts: $totalPoints)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
