import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Servicio de autenticación con Firebase Auth.
/// Soporta: email/password y Google Sign-In.
/// Los providers llaman a este servicio; nunca se usa directamente desde UI.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Estado actual ──

  /// Usuario actualmente autenticado (null si no hay sesión)
  User? get currentUser => _auth.currentUser;

  /// UID del usuario actual
  String? get currentUid => _auth.currentUser?.uid;

  /// Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Verifica si hay una sesión activa
  bool get isLoggedIn => _auth.currentUser != null;

  // ── Registro con email y contraseña ──

  /// Registra un nuevo usuario con email y contraseña.
  /// Retorna el User creado o lanza [AuthException].
  Future<User> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) {
        throw const AuthException(
          message: 'No se pudo crear la cuenta. Intenta de nuevo.',
          code: 'user-null',
        );
      }
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Error al registrar: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Login con email y contraseña ──

  /// Inicia sesión con email y contraseña.
  /// Retorna el User autenticado o lanza [AuthException].
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) {
        throw const AuthException(
          message: 'Error de inicio de sesión. Intenta de nuevo.',
          code: 'user-null',
        );
      }
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Error al iniciar sesión: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Google Sign-In ──

  /// Inicia sesión con Google.
  /// Retorna el User autenticado o lanza [AuthException].
  Future<User> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
          message: 'Inicio de sesión con Google cancelado.',
          code: 'google-cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw const AuthException(
          message: 'Error al vincular cuenta de Google.',
          code: 'google-user-null',
        );
      }
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Error con Google Sign-In: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Cambiar contraseña ──

  /// Cambia la contraseña del usuario actual.
  /// Requiere re-autenticación con la contraseña actual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw const AuthException(
          message: 'No hay sesión activa.',
          code: 'no-user',
        );
      }

      // Re-autenticar antes de cambiar contraseña
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cambiar la contraseña
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Error al cambiar contraseña: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Recuperar contraseña ──

  /// Envía un email de recuperación de contraseña.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw AuthException(
        message: 'Error al enviar email de recuperación: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Cerrar sesión ──

  /// Cierra la sesión actual (Firebase + Google).
  Future<void> logout() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw AuthException(
        message: 'Error al cerrar sesión: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Mapeo de errores de Firebase Auth ──

  /// Convierte errores de FirebaseAuth en mensajes amigables en español.
  AuthException _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          message: 'Usuario no encontrado.',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthException(
          message: 'Contraseña incorrecta.',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthException(
          message: 'Este correo ya está registrado.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthException(
          message: 'La contraseña es muy débil. Usa al menos 6 caracteres.',
          code: 'weak-password',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'El correo electrónico no es válido.',
          code: 'invalid-email',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Demasiados intentos. Espera un momento e intenta de nuevo.',
          code: 'too-many-requests',
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Error de conexión. Verifica tu internet.',
          code: 'network-error',
        );
      case 'invalid-credential':
        return const AuthException(
          message: 'Credenciales inválidas. Verifica tu correo y contraseña.',
          code: 'invalid-credential',
        );
      default:
        return AuthException(
          message: 'Error de autenticación: ${e.message ?? e.code}',
          code: e.code,
          originalError: e,
        );
    }
  }
}
