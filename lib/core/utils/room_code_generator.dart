import 'dart:math';

/// Generador de códigos de sala.
/// Formato: XXX-XXXX (3 + guión + 4 caracteres alfanuméricos).
/// Excluye caracteres ambiguos: 0, O, I, l, 1.
class RoomCodeGenerator {
  RoomCodeGenerator._();

  /// Caracteres permitidos (sin ambiguos: 0, O, I, l, 1)
  static const String _allowedChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static final Random _random = Random.secure();

  /// Genera un código de sala único con formato XXX-XXXX
  static String generate() {
    final part1 = _generatePart(3);
    final part2 = _generatePart(4);
    return '$part1-$part2';
  }

  /// Genera una parte del código con la longitud especificada
  static String _generatePart(int length) {
    return List.generate(
      length,
      (_) => _allowedChars[_random.nextInt(_allowedChars.length)],
    ).join();
  }

  /// Valida que un código tenga el formato correcto (XXX-XXXX)
  static bool isValidFormat(String code) {
    final regex = RegExp(r'^[A-HJ-NP-Z2-9]{3}-[A-HJ-NP-Z2-9]{4}$');
    return regex.hasMatch(code.toUpperCase());
  }

  /// Normaliza el código (mayúsculas, quita espacios)
  static String normalize(String code) {
    return code.trim().toUpperCase();
  }
}
