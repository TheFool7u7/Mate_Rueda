import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:wordwonderslink/features/evaluation/domain/vote_model.dart';
import 'package:wordwonderslink/features/game/domain/round_model.dart';
import 'package:wordwonderslink/features/room/data/firestore_service.dart';
import 'package:wordwonderslink/features/game/data/realtime_db_service.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Provider de evaluación / calificación de respuestas.
/// Gestiona: selección de score, badge, envío de votos, resultados.
class EvaluationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final RealtimeDbService _rtdbService = RealtimeDbService();

  // ── Estado de la evaluación actual ──
  int _selectedScore = 5;
  VoteBadge _selectedBadge = VoteBadge.common;
  ResponseModel? _responseBeingEvaluated;
  bool _isLoading = false;
  bool _hasVoted = false;
  String? _errorMessage;
  List<VoteModel> _currentVotes = [];

  // ── Getters ──
  int get selectedScore => _selectedScore;
  VoteBadge get selectedBadge => _selectedBadge;
  ResponseModel? get responseBeingEvaluated => _responseBeingEvaluated;
  bool get isLoading => _isLoading;
  bool get hasVoted => _hasVoted;
  String? get errorMessage => _errorMessage;
  List<VoteModel> get currentVotes => _currentVotes;

  /// Promedio de votos de la evaluación actual
  double get averageScore {
    if (_currentVotes.isEmpty) return 0;
    final total = _currentVotes.fold<int>(0, (sum, v) => sum + v.score);
    return total / _currentVotes.length;
  }

  /// Badge más frecuente en los votos actuales
  VoteBadge get mostCommonBadge {
    if (_currentVotes.isEmpty) return VoteBadge.common;

    final counts = <VoteBadge, int>{};
    for (final vote in _currentVotes) {
      counts[vote.badge] = (counts[vote.badge] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ══════════════════════════════════════
  // CONFIGURACIÓN DE EVALUACIÓN
  // ══════════════════════════════════════

  StreamSubscription? _votesSubscription;
  Timer? _safetyTimer;

  /// Carga la respuesta que se va a evaluar y comienza a escuchar los votos.
  /// Incluye un timer de seguridad de 30s para evitar que el juego se congele
  /// si un votante se desconecta.
  /// [voterUids] contiene los UIDs de los votantes esperados (conectados, sin el autor).
  Future<void> startEvaluation({
    required String roomCode,
    required String roundId,
    required String letterId,
    required int expectedVotes,
    required List<String> voterUids,
    required VoidCallback onAllVotesSubmitted,
    required bool isHost,
  }) async {
    _setLoading(true);
    _hasVoted = false;
    _selectedScore = 5;
    _selectedBadge = VoteBadge.common;
    _errorMessage = null;
    _currentVotes = [];
    _votesSubscription?.cancel();
    _safetyTimer?.cancel();

    try {
      _responseBeingEvaluated = await _firestoreService.getResponse(
        roomCode,
        roundId,
        letterId,
      );

      bool hasAdvanced = false;

      // Escuchar los votos en tiempo real
      _votesSubscription = _firestoreService
          .watchVotes(roomCode, roundId, letterId)
          .listen((votes) {
            _currentVotes = votes;
            notifyListeners();

            // Si ya votaron todos los demás, avanzar
            if (votes.length >= expectedVotes && expectedVotes > 0 && !hasAdvanced) {
              hasAdvanced = true;
              _safetyTimer?.cancel();
              onAllVotesSubmitted();
            }
          });

      // Timer de seguridad: si después de 30s no se completan los votos,
      // generar votos automáticos para los faltantes y luego avanzar.
      _safetyTimer = Timer(const Duration(seconds: 30), () async {
        if (!hasAdvanced) {
          hasAdvanced = true;
          debugPrint(
            '=== EVAL SAFETY: Timer de 30s expirado con ${_currentVotes.length}/$expectedVotes votos.',
          );

          // Generar votos automáticos para votantes faltantes (SOLO EL HOST)
          if (isHost) {
            await _submitAutoVotes(
              roomCode: roomCode,
              roundId: roundId,
              letterId: letterId,
              voterUids: voterUids,
            );
          } else {
            debugPrint('=== EVAL SAFETY: No es host, saltando auto-votos.');
          }

          onAllVotesSubmitted();
        }
      });
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error al cargar respuesta: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Genera votos automáticos (score=5, badge=common) para votantes que no votaron.
  /// Actualiza el puntaje del autor de la respuesta en RTDB por cada voto generado.
  Future<void> _submitAutoVotes({
    required String roomCode,
    required String roundId,
    required String letterId,
    required List<String> voterUids,
  }) async {
    // Determinar quiénes ya votaron
    final votedUids = _currentVotes.map((v) => v.voterId).toSet();

    for (final uid in voterUids) {
      if (votedUids.contains(uid)) continue; // Ya votó

      try {
        final autoVote = VoteModel(
          voterId: uid,
          voterUsername: 'Auto',
          score: 5,
          badge: VoteBadge.common,
          votedAt: DateTime.now(),
        );

        // Guardar voto automático en Firestore
        await _firestoreService.submitVote(roomCode, roundId, letterId, autoVote);

        // Actualizar puntaje del autor de la respuesta en RTDB
        if (_responseBeingEvaluated != null) {
          await _rtdbService.updatePlayerScore(
            roomCode,
            _responseBeingEvaluated!.submittedBy,
            autoVote.totalScore,
          );
        }

        debugPrint('=== EVAL SAFETY: Voto automático generado para $uid (score=5)');
      } catch (e) {
        debugPrint('Error al generar voto automático para $uid: $e');
      }
    }
  }

  // ══════════════════════════════════════
  // SELECCIÓN DE VOTO
  // ══════════════════════════════════════

  /// Selecciona la calificación numérica (1-10)
  void selectScore(int score) {
    _selectedScore = score.clamp(1, 10);
    notifyListeners();
  }

  /// Selecciona el badge de la respuesta
  void selectBadge(VoteBadge badge) {
    _selectedBadge = badge;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // ENVÍO DE VOTO
  // ══════════════════════════════════════

  /// Envía el voto del jugador actual.
  /// El voto se guarda con el voterId como document ID para seguridad.
  Future<bool> submitVote({
    required String roomCode,
    required String roundId,
    required String letterId,
    required String voterId,
    required String voterUsername,
  }) async {
    if (_hasVoted) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final vote = VoteModel(
        voterId: voterId,
        voterUsername: voterUsername,
        score: _selectedScore,
        badge: _selectedBadge,
        votedAt: DateTime.now(),
      );

      // Guardar voto en Firestore (docID = voterId para evitar duplicados)
      await _firestoreService.submitVote(roomCode, roundId, letterId, vote);

      // Actualizar puntaje del jugador evaluado en RTDB
      if (_responseBeingEvaluated != null) {
        await _rtdbService.updatePlayerScore(
          roomCode,
          _responseBeingEvaluated!.submittedBy,
          vote.totalScore,
        );
      }

      _hasVoted = true;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al enviar voto: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════
  // CONSULTA DE VOTOS
  // ══════════════════════════════════════

  /// Carga todos los votos de la respuesta actual (para ver resultados)
  Future<void> loadVotes({
    required String roomCode,
    required String roundId,
    required String letterId,
  }) async {
    try {
      _currentVotes = await _firestoreService.getVotes(
        roomCode,
        roundId,
        letterId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar votos: $e');
    }
  }

  // ══════════════════════════════════════
  // LIMPIEZA
  // ══════════════════════════════════════

  /// Resetea el estado para una nueva evaluación
  void reset() {
    _selectedScore = 5;
    _selectedBadge = VoteBadge.common;
    _responseBeingEvaluated = null;
    _hasVoted = false;
    _errorMessage = null;
    _currentVotes = [];
    _safetyTimer?.cancel();
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
}
