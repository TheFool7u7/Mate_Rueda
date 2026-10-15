import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:wordwonderslink/features/auth/domain/user_model.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/game/domain/round_model.dart';
import 'package:wordwonderslink/features/evaluation/domain/vote_model.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Servicio de Cloud Firestore para datos persistentes ("fríos").
/// Gestiona: usuarios, salas, rondas, respuestas, votos y leaderboard.
/// Los providers llaman a este servicio; nunca se usa directamente desde UI.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Referencias a colecciones ──
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('rooms');

  CollectionReference<Map<String, dynamic>> get _leaderboardRef =>
      _db.collection('leaderboard');

  // ══════════════════════════════════════
  // USUARIOS
  // ══════════════════════════════════════

  /// Crea el perfil de un nuevo usuario en Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).set(user.toJson());
    } catch (e) {
      throw FirestoreException(
        message: 'Error al crear perfil de usuario: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene el perfil de un usuario por su UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener usuario: $e',
        originalError: e,
      );
    }
  }

  /// Actualiza campos específicos del perfil de usuario
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersRef.doc(uid).update(data);
    } catch (e) {
      throw FirestoreException(
        message: 'Error al actualizar usuario: $e',
        originalError: e,
      );
    }
  }

  /// Incrementa las estadísticas del usuario después de una partida
  Future<void> updateUserStats({
    required String uid,
    required int pointsEarned,
    required bool won,
  }) async {
    try {
      await _usersRef.doc(uid).update({
        'totalPoints': FieldValue.increment(pointsEarned),
        'gamesPlayed': FieldValue.increment(1),
        if (won) 'gamesWon': FieldValue.increment(1),
      });
    } catch (e) {
      throw FirestoreException(
        message: 'Error al actualizar estadísticas: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // SALAS
  // ══════════════════════════════════════

  /// Crea una nueva sala de juego
  Future<void> createRoom(RoomModel room) async {
    try {
      await _roomsRef.doc(room.roomCode).set(room.toJson());
    } catch (e) {
      throw FirestoreException(
        message: 'Error al crear sala: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene una sala por su código
  Future<RoomModel?> getRoom(String roomCode) async {
    try {
      final doc = await _roomsRef.doc(roomCode).get();
      if (!doc.exists) return null;
      return RoomModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener sala: $e',
        originalError: e,
      );
    }
  }

  /// Stream de cambios en una sala (para el lobby en tiempo real)
  Stream<RoomModel?> watchRoom(String roomCode) {
    return _roomsRef.doc(roomCode).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RoomModel.fromFirestore(doc);
    });
  }

  /// Agrega un jugador a una sala existente
  Future<void> joinRoom(String roomCode, PlayerRef player) async {
    try {
      await _roomsRef.doc(roomCode).update({
        'players': FieldValue.arrayUnion([player.toJson()]),
      });
    } catch (e) {
      throw FirestoreException(
        message: 'Error al unirse a la sala: $e',
        originalError: e,
      );
    }
  }

  /// Remueve un jugador de una sala
  Future<void> leaveRoom(String roomCode, PlayerRef player) async {
    try {
      await _roomsRef.doc(roomCode).update({
        'players': FieldValue.arrayRemove([player.toJson()]),
      });
    } catch (e) {
      throw FirestoreException(
        message: 'Error al salir de la sala: $e',
        originalError: e,
      );
    }
  }

  /// Actualiza el estado de la sala (waiting → playing → finished)
  Future<void> updateRoomStatus(String roomCode, RoomStatus status) async {
    try {
      await _roomsRef.doc(roomCode).update({'status': status.name});
    } catch (e) {
      throw FirestoreException(
        message: 'Error al actualizar estado de la sala: $e',
        originalError: e,
      );
    }
  }

  /// Elimina una sala completamente (cuando el host abandona el lobby)
  Future<void> deleteRoom(String roomCode) async {
    try {
      await _roomsRef.doc(roomCode).delete();
    } catch (e) {
      throw FirestoreException(
        message: 'Error al eliminar sala: $e',
        originalError: e,
      );
    }
  }

  /// Actualiza el host de una sala (migración automática de host)
  Future<void> updateRoomHost(String roomCode, String newHostUid) async {
    try {
      await _roomsRef.doc(roomCode).update({'hostUid': newHostUid});
    } catch (e) {
      throw FirestoreException(
        message: 'Error al actualizar host de la sala: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // RONDAS
  // ══════════════════════════════════════

  /// Crea una nueva ronda dentro de una sala
  Future<void> createRound(String roomCode, RoundModel round) async {
    try {
      await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .doc(round.roundId)
          .set(round.toJson());
    } catch (e) {
      throw FirestoreException(
        message: 'Error al crear ronda: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene una ronda específica
  Future<RoundModel?> getRound(String roomCode, String roundId) async {
    try {
      final doc = await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .doc(roundId)
          .get();
      if (!doc.exists) return null;
      return RoundModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener ronda: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene todas las rondas de una sala
  Future<List<RoundModel>> getRounds(String roomCode) async {
    try {
      final snapshot = await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .orderBy('roundNumber')
          .get();
      return snapshot.docs.map((doc) => RoundModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener rondas: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // RESPUESTAS
  // ══════════════════════════════════════

  /// Guarda una respuesta para una letra en una ronda
  Future<void> submitResponse(
    String roomCode,
    String roundId,
    ResponseModel response,
  ) async {
    try {
      await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .doc(roundId)
          .collection('responses')
          .doc(response.letterId)
          .set(response.toJson());
    } catch (e) {
      throw FirestoreException(
        message: 'Error al enviar respuesta: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene una respuesta específica
  Future<ResponseModel?> getResponse(
    String roomCode,
    String roundId,
    String letterId,
  ) async {
    try {
      final doc = await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .doc(roundId)
          .collection('responses')
          .doc(letterId)
          .get();
      if (!doc.exists) return null;
      return ResponseModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener respuesta: $e',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════
  // VOTOS
  // ══════════════════════════════════════

  /// Guarda el voto de un jugador sobre una respuesta.
  /// El documento usa el voterId como ID para evitar votos duplicados.
  /// Regla de seguridad: request.auth.uid == voteId
  Future<void> submitVote(
    String roomCode,
    String roundId,
    String letterId,
    VoteModel vote,
  ) async {
    try {
      await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .doc(roundId)
          .collection('responses')
          .doc(letterId)
          .collection('votes')
          .doc(vote.voterId)
          .set(vote.toJson());
    } catch (e) {
      throw FirestoreException(
        message: 'Error al enviar voto: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene todos los votos de una respuesta
  Future<List<VoteModel>> getVotes(
    String roomCode,
    String roundId,
    String letterId,
  ) async {
    try {
      final snapshot = await _roomsRef
          .doc(roomCode)
          .collection('rounds')
          .doc(roundId)
          .collection('responses')
          .doc(letterId)
          .collection('votes')
          .get();
      return snapshot.docs.map((doc) => VoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener votos: $e',
        originalError: e,
      );
    }
  }

  /// Stream de todos los votos de una respuesta en tiempo real
  Stream<List<VoteModel>> watchVotes(
    String roomCode,
    String roundId,
    String letterId,
  ) {
    return _roomsRef
        .doc(roomCode)
        .collection('rounds')
        .doc(roundId)
        .collection('responses')
        .doc(letterId)
        .collection('votes')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => VoteModel.fromFirestore(doc)).toList(),
        );
  }

  // ══════════════════════════════════════
  // LEADERBOARD
  // ══════════════════════════════════════

  /// Actualiza el puntaje de un usuario en el leaderboard global
  Future<void> updateLeaderboard(String uid, UserModel user) async {
    try {
      await _leaderboardRef
          .doc(uid)
          .set(user.toLeaderboard(), SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException(
        message: 'Error al actualizar leaderboard: $e',
        originalError: e,
      );
    }
  }

  /// Incrementa estadísticas en el leaderboard directamente
  Future<void> updateLeaderboardStats({
    required String uid,
    required int pointsEarned,
  }) async {
    try {
      await _leaderboardRef.doc(uid).update({
        'totalPoints': FieldValue.increment(pointsEarned),
      });
    } catch (e) {
      // Ignoramos si el doc no existe, se creará al próximo login
      debugPrint('Error al actualizar leaderboardStats: $e');
    }
  }

  /// Obtiene el top N jugadores del leaderboard
  Future<List<Map<String, dynamic>>> getTopPlayers({int limit = 4}) async {
    try {
      final snapshot = await _leaderboardRef
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw FirestoreException(
        message: 'Error al obtener leaderboard: $e',
        originalError: e,
      );
    }
  }

  /// Stream del leaderboard en tiempo real
  Stream<List<Map<String, dynamic>>> watchTopPlayers({int limit = 4}) {
    return _leaderboardRef
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
