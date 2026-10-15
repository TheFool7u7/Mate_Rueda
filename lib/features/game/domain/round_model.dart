import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordwonderslink/features/game/domain/letter_model.dart';

/// Modelo de una ronda de juego.
/// Mapea a Firestore: /rooms/{roomCode}/rounds/{roundId}
/// Cada ronda tiene una categoría y un conjunto de letras disponibles.
class RoundModel {
  final String roundId;
  final String category;
  final int roundNumber;
  final List<LetterModel> letters;
  final DateTime createdAt;

  const RoundModel({
    required this.roundId,
    required this.category,
    this.roundNumber = 1,
    this.letters = const [],
    required this.createdAt,
  });

  /// Constructor desde un documento de Firestore
  factory RoundModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    // Parsear lista de letras
    final lettersList =
        (json['letters'] as List<dynamic>?)
            ?.map((l) => LetterModel.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];

    return RoundModel(
      roundId: documentId ?? json['roundId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      roundNumber: json['roundNumber'] as int? ?? 1,
      letters: lettersList,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  /// Constructor desde un DocumentSnapshot de Firestore
  factory RoundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoundModel.fromJson(data, documentId: doc.id);
  }

  /// Genera las letras del alfabeto español para una nueva ronda
  factory RoundModel.newRound({
    required String roundId,
    required String category,
    required int roundNumber,
  }) {
    // Alfabeto español completo (27 letras)
    const spanishAlphabet = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'Ñ',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ];

    final letters = spanishAlphabet
        .map((char) => LetterModel(char: char))
        .toList();

    return RoundModel(
      roundId: roundId,
      category: category,
      roundNumber: roundNumber,
      letters: letters,
      createdAt: DateTime.now(),
    );
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'roundId': roundId,
      'category': category,
      'roundNumber': roundNumber,
      'letters': letters.map((l) => l.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea una copia con campos modificados
  RoundModel copyWith({
    String? roundId,
    String? category,
    int? roundNumber,
    List<LetterModel>? letters,
    DateTime? createdAt,
  }) {
    return RoundModel(
      roundId: roundId ?? this.roundId,
      category: category ?? this.category,
      roundNumber: roundNumber ?? this.roundNumber,
      letters: letters ?? this.letters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Obtiene las letras que aún están disponibles (free)
  List<LetterModel> get availableLetters =>
      letters.where((l) => l.status == LetterStatus.free).toList();

  /// Obtiene las letras ya usadas
  List<LetterModel> get usedLetters =>
      letters.where((l) => l.status == LetterStatus.used).toList();

  /// Verifica si quedan letras disponibles
  bool get hasAvailableLetters => availableLetters.isNotEmpty;

  /// Busca una letra específica por su carácter
  LetterModel? getLetterByChar(String char) {
    try {
      return letters.firstWhere((l) => l.char == char.toUpperCase());
    } catch (_) {
      return null;
    }
  }

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
      'RoundModel(id: $roundId, category: $category, round: $roundNumber, '
      'available: ${availableLetters.length}/${letters.length})';
}

/// Modelo de una respuesta enviada por un jugador para una letra.
/// Mapea a: /rooms/{roomCode}/rounds/{roundId}/responses/{letterId}
class ResponseModel {
  final String letterId;
  final String word;
  final String submittedBy;
  final String submittedByUsername;
  final DateTime submittedAt;

  const ResponseModel({
    required this.letterId,
    required this.word,
    required this.submittedBy,
    this.submittedByUsername = '',
    required this.submittedAt,
  });

  factory ResponseModel.fromJson(
    Map<String, dynamic> json, {
    String? documentId,
  }) {
    return ResponseModel(
      letterId: documentId ?? json['letterId'] as String? ?? '',
      word: json['word'] as String? ?? '',
      submittedBy: json['submittedBy'] as String? ?? '',
      submittedByUsername: json['submittedByUsername'] as String? ?? '',
      submittedAt: _parseDateTime(json['submittedAt']),
    );
  }

  factory ResponseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ResponseModel.fromJson(data, documentId: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'letterId': letterId,
      'word': word,
      'submittedBy': submittedBy,
      'submittedByUsername': submittedByUsername,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  ResponseModel copyWith({
    String? letterId,
    String? word,
    String? submittedBy,
    String? submittedByUsername,
    DateTime? submittedAt,
  }) {
    return ResponseModel(
      letterId: letterId ?? this.letterId,
      word: word ?? this.word,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedByUsername: submittedByUsername ?? this.submittedByUsername,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

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
      'ResponseModel(letter: $letterId, word: $word, by: $submittedBy)';
}
