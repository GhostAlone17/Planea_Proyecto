import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio de autenticación con Firebase
/// Maneja login, registro, cierre de sesión y gestión de usuarios
/// 
/// Uso:
/// ```dart
/// final authService = context.read<AuthenticationService>();
/// await authService.login(email: 'user@example.com', password: 'password');
/// ```
class AuthenticationService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  /// Getters
  firebase_auth.User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthenticationService() {
    _initializeAuth();
  }

  /// Inicializa el servicio escuchando cambios de autenticación
  void _initializeAuth() {
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) {
      _currentUser = user;
      _errorMessage = null;
      notifyListeners();
    });
  }

  /// Registra un nuevo usuario con email y contraseña
  /// Automáticamente crea su documento en Firestore con tipoUsuario: 'alumno'
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Actualizar nombre de usuario
      await userCredential.user?.updateDisplayName(displayName);

      // ✨ NUEVO: Crear documento en Firestore automáticamente
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': email.trim(),
          'nombre': displayName,
          'tipoUsuario': 'alumno', // Por defecto es alumno
          'activo': true,
          'fechaRegistro': FieldValue.serverTimestamp(),
          'gradoId': '', // Se puede actualizar después
        });
      }

      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error desconocido: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inicia sesión con email y contraseña
  /// Verifica que el usuario esté activo en Firestore
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔵 [AUTH] login() iniciado con email: $email');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      debugPrint('🔵 [AUTH] isLoading = true, notificando listeners');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ [AUTH] Firebase Auth exitoso');

      // NUEVO: Verificar que el usuario esté activo en Firestore
      if (userCredential.user != null) {
        debugPrint('🔵 [AUTH] Verificando si usuario está activo en Firestore...');
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final isActivo = userDoc.data()?['activo'] ?? true;
          debugPrint('🔵 [AUTH] Usuario activo: $isActivo');
          
          if (!isActivo) {
            debugPrint('🔴 [AUTH] Usuario deshabilitado');
            // Usuario deshabilitado, cerrar sesión inmediatamente
            await _firebaseAuth.signOut();
            _errorMessage = 'Tu cuenta ha sido deshabilitada. Contacta al administrador.';
            _currentUser = null;
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          debugPrint('⚠️ [AUTH] Documento de usuario no existe en Firestore');
        }
      }

      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ [AUTH] login() completado exitosamente');

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('🔴 [AUTH] FirebaseAuthException: ${e.code}');
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      debugPrint('🔴 [AUTH] Error: $_errorMessage');
      return false;
    } catch (e) {
      debugPrint('🔴 [AUTH] Error desconocido en login: $e');
      _errorMessage = 'Error desconocido: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseAuth.signOut();

      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envía un email de recuperación de contraseña
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());

      _isLoading = false;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error desconocido: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Convierte códigos de error de Firebase a mensajes amigables
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'El email ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: $code';
    }
  }
}
