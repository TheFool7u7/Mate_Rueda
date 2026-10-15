import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado posible de una sala de juego
enum RoomStatus {
  waiting, // Esperando jugadores en el lobby
  playing, // Juego en progreso
  finished; // Juego terminado

  /// Convierte desde un string de Firestore
  static RoomStatus fromString(String? value) {
    switch (value) {
      case 'playing':
        return RoomStatus.playing;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }
}

/// Datos mínimos de un jugador dentro de una sala
class PlayerRef {
  final String uid;
  final String username;
  final String avatarUrl;

  const PlayerRef({
    required this.uid,
    required this.username,
    this.avatarUrl = '',
  });

  factory PlayerRef.fromJson(Map<String, dynamic> json) {
    return PlayerRef(
      uid: json['uid'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'username': username, 'avatarUrl': avatarUrl};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerRef &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

/// Modelo de sala de juego.
/// Mapea a Firestore: /rooms/{roomCode}
class RoomModel {
  final String roomCode;
  final String hostUid;
  final int maxPlayers;
  final int timePerTurn;
  final RoomStatus status;
  final List<PlayerRef> players;
  final DateTime createdAt;

  const RoomModel({
    required this.roomCode,
    required this.hostUid,
    this.maxPlayers = 4,
    this.timePerTurn = 30,
    this.status = RoomStatus.waiting,
    this.players = const [],
    required this.createdAt,
  });

  /// Constructor desde un documento de Firestore
  factory RoomModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    // Parsear lista de jugadores
    final playersList =
        (json['players'] as List<dynamic>?)
            ?.map((p) => PlayerRef.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return RoomModel(
      roomCode: documentId ?? json['roomCode'] as String? ?? '',
      hostUid: json['hostUid'] as String? ?? '',
      maxPlayers: json['maxPlayers'] as int? ?? 4,
      timePerTurn: json['timePerTurn'] as int? ?? 30,
      status: RoomStatus.fromString(json['status'] as String?),
      players: playersList,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  /// Constructor desde un DocumentSnapshot de Firestore
  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoomModel.fromJson(data, documentId: doc.id);
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostUid': hostUid,
      'maxPlayers': maxPlayers,
      'timePerTurn': timePerTurn,
      'status': status.name,
      'players': players.map((p) => p.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea una copia con campos modificados
  RoomModel copyWith({
    String? roomCode,
    String? hostUid,
    int? maxPlayers,
    int? timePerTurn,
    RoomStatus? status,
    List<PlayerRef>? players,
    DateTime? createdAt,
  }) {
    return RoomModel(
      roomCode: roomCode ?? this.roomCode,
      hostUid: hostUid ?? this.hostUid,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      timePerTurn: timePerTurn ?? this.timePerTurn,
      status: status ?? this.status,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Verifica si la sala está llena
  bool get isFull => players.length >= maxPlayers;

  /// Verifica si un jugador ya está en la sala
  bool hasPlayer(String uid) => players.any((p) => p.uid == uid);

  /// Verifica si un uid es el host
  bool isHost(String uid) => hostUid == uid;

  /// Cantidad actual de jugadores
  int get playerCount => players.length;

  /// Verifica si hay suficientes jugadores para iniciar
  bool get canStart => players.length >= 2;

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
      'RoomModel(code: $roomCode, status: ${status.name}, players: $playerCount/$maxPlayers)';
}
