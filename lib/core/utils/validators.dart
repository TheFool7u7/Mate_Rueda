import 'package:wordwonderslink/core/constants/app_strings.dart';

/// Validadores de formularios centralizados.
/// Retornan null si el valor es válido, o un mensaje de error en español.
class Validators {
  Validators._();

  /// Valida que el campo no esté vacío
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  /// Valida formato de correo electrónico
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Valida contraseña (mínimo 6 caracteres)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Valida que la confirmación de contraseña coincida
  static String? confirmPassword(String? value, String password) {
    final passwordError = Validators.password(value);
    if (passwordError != null) return passwordError;

    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  /// Valida nombre de usuario (mínimo 3 caracteres)
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.trim().length < 3) {
      return AppStrings.usernameTooShort;
    }
    return null;
  }

  /// Valida código de sala (formato XXX-XXXX)
  static String? roomCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final regex = RegExp(r'^[A-HJ-NP-Z2-9]{3}-[A-HJ-NP-Z2-9]{4}$');
    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return AppStrings.invalidCode;
    }
    return null;
  }
}
