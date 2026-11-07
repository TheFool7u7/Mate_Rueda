import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Acceso a la sala compartida del modo "varios dispositivos".
///
/// Se define como interfaz para poder probar la lógica sin Firebase
/// ([InMemoryMateRoomBackend]) y usar [FirebaseMateRoomBackend] en la app.
///
/// Estructura (Realtime Database):
/// ```text
/// mate/{code}/host                 uid de la docente
/// mate/{code}/members/{uid}        {joinedAt}  (una mesa por dispositivo)
/// mate/{code}/state                estado de la partida (lo publica la docente)
/// mate/{code}/answers/{uid}        {round, index}  (respuesta de una mesa)
/// ```
abstract class MateRoomBackend {
  /// UID del usuario actual (disponible tras [ensureSignedIn]).
  String? get uid;

  /// Inicia sesión anónima si hace falta (sin datos personales: RNF03).
  Future<void> ensureSignedIn();

  /// Crea una sala nueva con la docente como anfitriona; devuelve el código.
  Future<String> createRoom();

  /// Une este dispositivo como una mesa. `false` si la sala no existe.
  Future<bool> joinRoom(String code);

  /// Sale de la sala (la mesa deja de aparecer).
  Future<void> leaveRoom(String code);

  /// Cierra la sala (solo la docente).
  Future<void> closeRoom(String code);

  /// Estado publicado por la docente (`null` mientras no exista).
  Stream<Map<String, dynamic>?> watchState(String code);

  Future<void> publishState(String code, Map<String, dynamic> state);

  /// UIDs de las mesas conectadas, en orden de llegada.
  Stream<List<String>> watchMembers(String code);

  /// Envía la respuesta de esta mesa para la ronda [round].
  Future<void> sendAnswer(String code, {required int round, required int index});

  /// Limpia respuestas previas al iniciar/reiniciar una partida (anfitrión).
  Future<void> clearAnswers(String code);

  /// Respuestas por mesa: `{uid: {round, index}}`.
  Stream<Map<String, Map<String, dynamic>>> watchAnswers(String code);
}

/// Normaliza un código escrito por el usuario (mayúsculas, sin espacios
/// ni guiones).
String normalizeRoomCode(String raw) =>
    raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// Códigos cortos y sin caracteres ambiguos (0/O, 1/I) pensados para niños.
const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int roomCodeLength = 5;

String _randomCode(Random rng) => List.generate(
  roomCodeLength,
  (_) => _codeChars[rng.nextInt(_codeChars.length)],
).join();

// ═══════════════════════════════════════════════════════════
// FIREBASE
// ═══════════════════════════════════════════════════════════

class FirebaseMateRoomBackend implements MateRoomBackend {
  FirebaseMateRoomBackend({FirebaseAuth? auth, FirebaseDatabase? database})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = database ?? FirebaseDatabase.instance;

  final FirebaseAuth _auth;
  final FirebaseDatabase _db;
  final Random _rng = Random.secure();

  DatabaseReference _room(String code) => _db.ref('mate/$code');

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Future<void> ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) {
      await _auth.signInAnonymously();
    } else if (!user.isAnonymous) {
      // Si el celular tenía iniciada una sesión previa con correo o Google,
      // se cierra para que cada dispositivo tenga su propio UID anónimo único.
      await _auth.signOut();
      await _auth.signInAnonymously();
    }
  }

  @override
  Future<String> createRoom() async {
    await ensureSignedIn();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _randomCode(_rng);
      // Transacción: solo se reserva el código si nadie lo usa.
      final result = await _room(code).child('host').runTransaction((current) {
        if (current != null) return Transaction.abort();
        return Transaction.success(uid);
      });
      if (result.committed) {
        await _room(code).child('createdAt').set(ServerValue.timestamp);
        return code;
      }
    }
    throw StateError('No se pudo generar un código de sala libre.');
  }

  @override
  Future<bool> joinRoom(String code) async {
    await ensureSignedIn();
    final host = await _room(code).child('host').get();
    if (!host.exists) return false;

    // Si este dispositivo compartía UID con el anfitrión o con otra mesa ya
    // unida (p. ej. respaldo de Android, emulador clonado o sesión previa),
    // se renueva la sesión anónima para garantizar una mesa independiente.
    final currentUid = uid;
    if (currentUid == null || host.value == currentUid) {
      await _auth.signOut();
      await _auth.signInAnonymously();
    } else {
      final existing = await _room(code).child('members/$currentUid').get();
      if (existing.exists) {
        await _auth.signOut();
        await _auth.signInAnonymously();
      }
    }

    final ref = _room(code).child('members/$uid');
    await ref.set({'joinedAt': ServerValue.timestamp});
    return true;
  }

  @override
  Future<void> leaveRoom(String code) async {
    final id = uid;
    if (id == null) return;
    await _room(code).child('members/$id').remove();
    await _room(code).child('answers/$id').remove();
  }

  @override
  Future<void> closeRoom(String code) => _room(code).remove();

  @override
  Stream<Map<String, dynamic>?> watchState(String code) =>
      _room(code).child('state').onValue.map((e) => _asMap(e.snapshot.value));

  @override
  Future<void> publishState(String code, Map<String, dynamic> state) =>
      _room(code).child('state').set(state);

  @override
  Stream<List<String>> watchMembers(String code) =>
      _room(code).child('members').onValue.map((event) {
        final map = _asMap(event.snapshot.value) ?? const {};
        num joinedAtOf(Object? v) {
          if (v is Map) {
            final raw = v['joinedAt'];
            if (raw is num) return raw;
          }
          return 0;
        }

        final entries = map.entries.toList()
          ..sort((a, b) {
            final c = joinedAtOf(a.value).compareTo(joinedAtOf(b.value));
            return c != 0 ? c : a.key.compareTo(b.key);
          });
        return [for (final e in entries) e.key];
      });

  @override
  Future<void> sendAnswer(
    String code, {
    required int round,
    required int index,
  }) => _room(code).child('answers/$uid').set({
    'round': round,
    'index': index,
    'at': ServerValue.timestamp,
  });

  @override
  Future<void> clearAnswers(String code) => _room(code).child('answers').remove();

  @override
  Stream<Map<String, Map<String, dynamic>>> watchAnswers(String code) =>
      _room(code).child('answers').onValue.map((event) {
        final map = _asMap(event.snapshot.value) ?? const {};
        return {
          for (final e in map.entries)
            if (e.value is Map) e.key: Map<String, dynamic>.from(e.value as Map),
        };
      });
}

/// Convierte lo que devuelve RTDB (mapas/listas dinámicos) a tipos de Dart
/// concretos.
Map<String, dynamic>? _asMap(Object? value) {
  final converted = _deepConvert(value);
  return converted is Map<String, dynamic> ? converted : null;
}

Object? _deepConvert(Object? v) {
  if (v is Map) {
    return {for (final e in v.entries) e.key.toString(): _deepConvert(e.value)};
  }
  if (v is List) return [for (final e in v) _deepConvert(e)];
  return v;
}

// ═══════════════════════════════════════════════════════════
// EN MEMORIA (pruebas)
// ═══════════════════════════════════════════════════════════

/// Sala simulada en memoria. Varias instancias pueden compartir los mismos
/// datos pasando el mismo [shared] para simular varios dispositivos.
class InMemoryMateRoomBackend implements MateRoomBackend {
  InMemoryMateRoomBackend({required this.uid, InMemoryRooms? shared})
    : _rooms = shared ?? InMemoryRooms();

  @override
  final String? uid;

  final InMemoryRooms _rooms;

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<String> createRoom() async {
    final code = _randomCode(Random(_rooms._rooms.length + 1));
    _rooms._rooms[code] = _Room(host: uid!);
    return code;
  }

  @override
  Future<bool> joinRoom(String code) async {
    final room = _rooms._rooms[code];
    if (room == null) return false;
    if (!room.members.contains(uid)) room.members.add(uid!);
    room.membersCtrl.add(List.of(room.members));
    return true;
  }

  @override
  Future<void> leaveRoom(String code) async {
    final room = _rooms._rooms[code];
    if (room == null) return;
    room.members.remove(uid);
    room.answers.remove(uid);
    room.membersCtrl.add(List.of(room.members));
  }

  @override
  Future<void> closeRoom(String code) async {
    _rooms._rooms.remove(code);
  }

  @override
  Stream<Map<String, dynamic>?> watchState(String code) {
    final room = _rooms._rooms[code];
    if (room == null) return const Stream.empty();
    return Stream.multi((controller) {
      controller.add(room.state);
      final sub = room.stateCtrl.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> publishState(String code, Map<String, dynamic> state) async {
    final room = _rooms._rooms[code];
    if (room == null) return;
    // Copia profunda vía JSON-like para no compartir referencias mutables.
    room.state = _deepConvert(state) as Map<String, dynamic>;
    room.stateCtrl.add(room.state);
  }

  @override
  Stream<List<String>> watchMembers(String code) {
    final room = _rooms._rooms[code];
    if (room == null) return const Stream.empty();
    return Stream.multi((controller) {
      controller.add(List.of(room.members));
      final sub = room.membersCtrl.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> sendAnswer(
    String code, {
    required int round,
    required int index,
  }) async {
    final room = _rooms._rooms[code];
    if (room == null) return;
    room.answers[uid!] = {'round': round, 'index': index};
    room.answersCtrl.add({
      for (final e in room.answers.entries) e.key: Map.of(e.value),
    });
  }

  @override
  Future<void> clearAnswers(String code) async {
    final room = _rooms._rooms[code];
    if (room == null) return;
    room.answers.clear();
    room.answersCtrl.add(const {});
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> watchAnswers(String code) {
    final room = _rooms._rooms[code];
    if (room == null) return const Stream.empty();
    return Stream.multi((controller) {
      controller.add({
        for (final e in room.answers.entries) e.key: Map.of(e.value),
      });
      final sub = room.answersCtrl.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }
}

/// Almacén compartido entre varios [InMemoryMateRoomBackend].
class InMemoryRooms {
  final Map<String, _Room> _rooms = {};
}

class _Room {
  _Room({required this.host});

  final String host;
  final List<String> members = [];
  Map<String, dynamic>? state;
  final Map<String, Map<String, dynamic>> answers = {};

  final StreamController<Map<String, dynamic>?> stateCtrl =
      StreamController<Map<String, dynamic>?>.broadcast();
  final StreamController<List<String>> membersCtrl =
      StreamController<List<String>>.broadcast();
  final StreamController<Map<String, Map<String, dynamic>>> answersCtrl =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();
}
