import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:wordwonderslink/features/auth/domain/user_model.dart';
import 'package:wordwonderslink/features/auth/data/auth_service.dart';
import 'package:wordwonderslink/features/room/data/firestore_service.dart';
import 'package:wordwonderslink/core/error/app_exceptions.dart';

/// Provider de autenticación.
/// Gestiona: estado de sesión, login/registro, perfil del usuario actual.
/// Los screens observan este provider para reaccionar a cambios de auth.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // ── Estado ──
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription? _forceLogoutSubscription;

  // ── Getters ──
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.isLoggedIn && _currentUser != null;
  String? get currentUid => _authService.currentUid;

  /// Inicializa el listener de cambios de autenticación.
  /// Llamar desde el SplashScreen al arrancar la app.
  void initialize() {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  /// Reacciona a cambios en el estado de autenticación de Firebase
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        await _loadUserProfile(firebaseUser.uid);
        _startForceLogoutListener(firebaseUser.uid);
      } on AuthException catch (e) {
        _errorMessage = e.message;
        _forceLogoutSubscription?.cancel();
      } catch (e) {
        debugPrint('Error al cargar perfil: $e');
        _forceLogoutSubscription?.cancel();
      }
    } else {
      _currentUser = null;
      _forceLogoutSubscription?.cancel();
    }
    notifyListeners();
  }

  /// Carga el perfil del usuario desde Firestore
  Future<void> _loadUserProfile(String uid) async {
    final user = await _firestoreService.getUser(uid);
    if (user != null && user.isDisabled) {
      await _authService.logout();
      _currentUser = null;
      throw const AuthException(
        message: 'Cuenta deshabilitada. Contacta al administrador',
        code: 'user-disabled',
      );
    }

    // Update lastSeen timestamp in Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });

    _currentUser = user;
  }

  Future<void> updateUsername(String newUsername) async {
    if (_currentUser == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
            'username': newUsername,
            'usernameLowercase': newUsername.toLowerCase(),
          });

      final newUser = _currentUser!.copyWith(username: newUsername);
      await _firestoreService.updateLeaderboard(newUser.uid, newUser);

      _currentUser = newUser;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ══════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════

  /// Inicia sesión con email y contraseña
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return _executeAuth(() async {
      final user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      await _loadUserProfile(user.uid);
      _startForceLogoutListener(user.uid);
    });
  }

  /// Inicia sesión con Google
  Future<bool> loginWithGoogle() async {
    return _executeAuth(() async {
      final user = await _authService.loginWithGoogle();
      await _ensureUserProfile(user);
      _startForceLogoutListener(user.uid);
    });
  }

  // ══════════════════════════════════════
  // REGISTRO
  // ══════════════════════════════════════

  /// Registra un nuevo usuario con email y contraseña
  Future<bool> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    return _executeAuth(() async {
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );

      // Crear perfil en Firestore
      final userModel = UserModel(
        uid: user.uid,
        username: username.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUser(userModel);
      await _firestoreService.updateLeaderboard(user.uid, userModel);
      _currentUser = userModel;
    });
  }

  // ══════════════════════════════════════
  // GESTIÓN DE CONTRASEÑA
  // ══════════════════════════════════════

  /// Cambia la contraseña del usuario actual
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _executeAuth(() async {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }

  /// Envía email de recuperación de contraseña
  Future<bool> sendPasswordReset(String email) async {
    return _executeAuth(() async {
      await _authService.sendPasswordResetEmail(email);
    });
  }

  // ══════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════

  /// Cierra la sesión actual
  Future<void> logout() async {
    _setLoading(true);
    try {
      _forceLogoutSubscription?.cancel();
      await _authService.logout();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════
  // HELPERS INTERNOS
  // ══════════════════════════════════════

  /// Ejecuta una operación de auth con manejo de loading/error
  Future<bool> _executeAuth(Future<void> Function() operation) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await operation();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Asegura que exista un perfil en Firestore para login social.
  /// Si el usuario es nuevo (no tiene perfil), lo crea automáticamente.
  Future<void> _ensureUserProfile(User firebaseUser) async {
    final user = await _firestoreService.getUser(firebaseUser.uid);
    if (user != null && user.isDisabled) {
      await _authService.logout();
      _currentUser = null;
      throw const AuthException(
        message: 'Cuenta deshabilitada. Contacta al administrador',
        code: 'user-disabled',
      );
    }
    _currentUser = user;

    if (_currentUser == null) {
      // Usuario nuevo por login social: crear perfil
      final newUser = UserModel(
        uid: firebaseUser.uid,
        username: firebaseUser.displayName ?? 'Jugador',
        email: firebaseUser.email ?? '',
        avatarUrl: firebaseUser.photoURL ?? '',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUser(newUser);
      await _firestoreService.updateLeaderboard(firebaseUser.uid, newUser);
      _currentUser = newUser;
    }

    // Update lastSeen timestamp in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .update({'lastSeen': FieldValue.serverTimestamp()});
  }

  void _startForceLogoutListener(String uid) {
    _forceLogoutSubscription?.cancel();
    _forceLogoutSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;
          final data = snapshot.data();
          if (data?['forceLogout'] == true) {
            // 1. Resetear el campo inmediatamente
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'forceLogout': false});
            // 2. Cerrar sesión
            await FirebaseAuth.instance.signOut();
            // 3. Notificar a los listeners
            notifyListeners();
          }
        });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _forceLogoutSubscription?.cancel();
    super.dispose();
  }
}
