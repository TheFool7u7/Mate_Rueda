import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/auth/domain/user_model.dart';
import 'package:wordwonderslink/features/room/data/firestore_service.dart';
import 'package:wordwonderslink/features/game/data/realtime_db_service.dart';
import 'package:wordwonderslink/core/utils/room_code_generator.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Provider de salas de juego.
/// Gestiona: creación de sala, unirse, lobby en tiempo real, configuración.
class RoomProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final RealtimeDbService _rtdbService = RealtimeDbService();

  // ── Estado ──
  RoomModel? _currentRoom;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedMaxPlayers = AppDimensions.defaultPlayers;
  int _selectedTimePerTurn = AppDimensions.defaultResponseTime;
  StreamSubscription? _roomSubscription;

  // ── Getters ──
  RoomModel? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedMaxPlayers => _selectedMaxPlayers;
  int get selectedTimePerTurn => _selectedTimePerTurn;
  String? get currentRoomCode => _currentRoom?.roomCode;

  // ══════════════════════════════════════
  // CREAR SALA
  // ══════════════════════════════════════

  /// Crea una nueva sala con código aleatorio
  Future<String?> createRoom(UserModel host) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Generar código único
      final roomCode = RoomCodeGenerator.generate();

      // Crear referencia del host como jugador
      final hostPlayer = PlayerRef(
        uid: host.uid,
        username: host.username,
        avatarUrl: host.avatarUrl,
      );

      // Crear modelo de sala
      final room = RoomModel(
        roomCode: roomCode,
        hostUid: host.uid,
        maxPlayers: _selectedMaxPlayers,
        timePerTurn: _selectedTimePerTurn,
        status: RoomStatus.waiting,
        players: [hostPlayer],
        createdAt: DateTime.now(),
      );

      // Guardar en Firestore
      await _firestoreService.createRoom(room);
      _currentRoom = room;

      // Escuchar cambios en la sala (para el lobby)
      _watchRoom(roomCode);

      return roomCode;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Error al crear sala: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════
  // UNIRSE A SALA
  // ══════════════════════════════════════

  /// Se une a una sala existente con el código proporcionado.
  /// Permite reconexión si el jugador ya está en la lista de players.
  Future<bool> joinRoom(String code, UserModel user) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final normalizedCode = RoomCodeGenerator.normalize(code);

      // Verificar que el código tiene formato válido
      if (!RoomCodeGenerator.isValidFormat(normalizedCode)) {
        _errorMessage = AppStrings.invalidCode;
        return false;
      }

      // Obtener la sala de Firestore
      final room = await _firestoreService.getRoom(normalizedCode);

      if (room == null) {
        _errorMessage = AppStrings.roomNotFound;
        return false;
      }

      // Priorizar reconexión: si el jugador ya está en la sala,
      // permitir acceso sin importar el estado (waiting o playing)
      if (room.hasPlayer(user.uid)) {
        _currentRoom = room;
        _watchRoom(normalizedCode);
        return true;
      }

      // Verificar que la sala está en estado waiting para nuevos jugadores
      if (room.status != RoomStatus.waiting) {
        _errorMessage = 'La sala ya está en juego.';
        return false;
      }

      // Verificar que la sala no está llena
      if (room.isFull) {
        _errorMessage = AppStrings.roomFull;
        return false;
      }

      // Unirse a la sala
      final playerRef = PlayerRef(
        uid: user.uid,
        username: user.username,
        avatarUrl: user.avatarUrl,
      );

      await _firestoreService.joinRoom(normalizedCode, playerRef);
      _currentRoom = room.copyWith(players: [...room.players, playerRef]);

      // Escuchar cambios en la sala
      _watchRoom(normalizedCode);

      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al unirse: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════
  // LOBBY
  // ══════════════════════════════════════

  /// Inicia la escucha en tiempo real de cambios en la sala.
  /// Si la sala es eliminada (null), resetea el estado local.
  void _watchRoom(String roomCode) {
    _roomSubscription?.cancel();
    _roomSubscription = _firestoreService
        .watchRoom(roomCode)
        .listen(
          (room) {
            if (room != null) {
              final previousCount = _currentRoom?.players.length ?? 0;
              final wasWaiting = _currentRoom?.status == RoomStatus.waiting;
              
              _currentRoom = room;
              
              if (room.players.length > previousCount) {
                AudioManagerService().playSfx('dingding.wav');
              }
              if (wasWaiting && room.status == RoomStatus.playing) {
                AudioManagerService().playSfx('lets_go.wav');
              }
            } else if (_currentRoom != null) {
              // La sala fue eliminada (host cerró el lobby)
              debugPrint('=== ROOM: Sala $roomCode eliminada, limpiando estado');
              _currentRoom = null;
            }
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error en watchRoom: $e');
          },
        );
  }

  /// Inicia el juego (solo el host puede llamar esto)
  Future<bool> startGame(String uid) async {
    if (_currentRoom == null) return false;
    if (!_currentRoom!.isHost(uid)) return false;
    if (!_currentRoom!.canStart) {
      _errorMessage = AppStrings.minPlayersRequired;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final roomCode = _currentRoom!.roomCode;

      // Actualizar estado de la sala a "playing"
      await _firestoreService.updateRoomStatus(roomCode, RoomStatus.playing);

      // Seleccionar categoría aleatoria para la primera ronda
      final categories = List<String>.from(AppStrings.gameCategories)
        ..shuffle();
      final firstCategory = categories.first;

      // Inicializar estado del juego en RTDB
      final playerUids = _currentRoom!.players.map((p) => p.uid).toList();
      await _rtdbService.initializeGame(
        roomCode: roomCode,
        firstCategory: firstCategory,
        playerUids: playerUids,
      );

      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al iniciar juego: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════
  // CONFIGURACIÓN DE SALA
  // ══════════════════════════════════════

  /// Incrementa la cantidad de jugadores (máx 8)
  void incrementPlayers() {
    if (_selectedMaxPlayers < AppDimensions.maxPlayers) {
      _selectedMaxPlayers++;
      notifyListeners();
    }
  }

  /// Decrementa la cantidad de jugadores (mín 2)
  void decrementPlayers() {
    if (_selectedMaxPlayers > AppDimensions.minPlayers) {
      _selectedMaxPlayers--;
      notifyListeners();
    }
  }

  /// Incrementa el tiempo de respuesta (máx 60s, en pasos de 5)
  void incrementTime() {
    if (_selectedTimePerTurn < AppDimensions.maxResponseTime) {
      _selectedTimePerTurn += 5;
      notifyListeners();
    }
  }

  /// Decrementa el tiempo de respuesta (mín 15s, en pasos de 5)
  void decrementTime() {
    if (_selectedTimePerTurn > AppDimensions.minResponseTime) {
      _selectedTimePerTurn -= 5;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════
  // UTILIDADES
  // ══════════════════════════════════════

  /// Copia el código de sala al portapapeles
  Future<void> copyRoomCode() async {
    if (_currentRoom?.roomCode != null) {
      await Clipboard.setData(ClipboardData(text: _currentRoom!.roomCode));
    }
  }

  /// Sale de la sala actual.
  /// Si el host abandona una sala en estado 'waiting', la sala se elimina.
  Future<void> leaveRoom(UserModel user) async {
    if (_currentRoom == null) return;

    try {
      final roomCode = _currentRoom!.roomCode;
      final isHost = _currentRoom!.isHost(user.uid);
      final isWaiting = _currentRoom!.status == RoomStatus.waiting;

      if (isHost && isWaiting) {
        // El host abandona el lobby → eliminar la sala completamente
        await _firestoreService.deleteRoom(roomCode);
        debugPrint('=== ROOM: Host abandonó lobby, sala $roomCode eliminada');
      } else {
        // Jugador normal sale o sala en juego → solo remover al jugador
        final playerRef = PlayerRef(
          uid: user.uid,
          username: user.username,
          avatarUrl: user.avatarUrl,
        );
        await _firestoreService.leaveRoom(roomCode, playerRef);
      }

      _roomSubscription?.cancel();
      _currentRoom = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al salir de sala: $e');
    }
  }

  /// Resetea el estado del provider (al volver al menú principal)
  void reset() {
    _roomSubscription?.cancel();
    _currentRoom = null;
    _errorMessage = null;
    _selectedMaxPlayers = AppDimensions.defaultPlayers;
    _selectedTimePerTurn = AppDimensions.defaultResponseTime;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
