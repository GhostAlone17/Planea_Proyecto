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
  /// ✨ MEJORA: Permite registrarse como alumno o maestro
  /// - Alumnos: aprobado = true (acceso inmediato)
  /// - Maestros: aprobado = false (requiere validación admin)
  /// 
  /// Automáticamente crea su documento en Firestore
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String tipoUsuario, // 'alumno' o 'maestro'
    String? gradoNombre, // Grado para alumnos: 'Primaria', 'Secundaria', 'Preparatoria'
    String? gradoId, // ✨ NUEVO: Año específico (opcional, se genera automático si no se proporciona)
    bool mantenerSesion = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Guardar sesión actual si se debe mantener
      final adminUser = mantenerSesion ? _currentUser : null;
      final adminEmail = adminUser?.email;

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Actualizar nombre de usuario
      await userCredential.user?.updateDisplayName(displayName);

      // Crear documento en Firestore automáticamente
      if (userCredential.user != null) {
        // ✨ NUEVA LÓGICA: Maestros requieren aprobación
        final estaAprobado = tipoUsuario == 'alumno' ? true : false;
        
        // ✅ ARREGLO: Usar gradoId proporcionado o generar por defecto
        String? finalGradoId = gradoId; // Usar el proporcionado si existe
        
        // Si no se proporcionó gradoId, generar por defecto basado en gradoNombre
        if (tipoUsuario == 'alumno' && gradoNombre != null && finalGradoId == null) {
          // Mapeo por defecto: usar el grado más alto de cada nivel
          switch (gradoNombre.toLowerCase()) {
            case 'primaria':
              finalGradoId = '6P'; // Grado por defecto: 6° de Primaria
              break;
            case 'secundaria':
              finalGradoId = '3S'; // Grado por defecto: 3° de Secundaria
              break;
            case 'preparatoria':
              finalGradoId = '12EMS'; // Grado por defecto: 3° de Preparatoria (12EMS)
              break;
          }
        }
        
        print('✅ Autoregistro: gradoNombre="$gradoNombre" → gradoId="$finalGradoId"');
        
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': email.trim(),
          'nombre': displayName,
          'tipoUsuario': tipoUsuario, // ✨ NUEVO
          'activo': true,
          'aprobado': estaAprobado, // ✨ NUEVO: Maestros = false
          'fechaRegistro': FieldValue.serverTimestamp(),
          'fechaSolicitud': tipoUsuario == 'maestro' ? FieldValue.serverTimestamp() : null,
          'gradoNombre': tipoUsuario == 'alumno' ? gradoNombre : null, // ✨ NUEVO
          'gradoId': tipoUsuario == 'alumno' ? finalGradoId : null, // ✅ ARREGLO: Usar finalGradoId
        });
      }

      // Si es admin registrando, mantener su sesión
      if (mantenerSesion && adminEmail != null) {
        print('✅ Usuario $displayName creado. Sesión de admin mantenida.');
      } else {
        // Auto-login solo si es alumno (maestros no pueden entrar hasta ser aprobados)
        if (tipoUsuario == 'alumno') {
          _currentUser = userCredential.user;
          print('✅ Usuario $displayName creado e identificado.');
        } else {
          // Maestro registrado, pero no autenticado
          await _firebaseAuth.signOut();
          _currentUser = null;
          print('✅ Solicitud de maestro enviada para aprobación.');
        }
      }
      
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
  /// ✨ MEJORA: Verifica que maestros estén aprobados antes de permitir login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // NUEVO: Verificar que el usuario esté activo en Firestore
      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final isActivo = userDoc.data()?['activo'] ?? true;
          final tipoUsuario = userDoc.data()?['tipoUsuario'] as String?;
          final estaAprobado = userDoc.data()?['aprobado'] ?? true;
          final nombre = userDoc.data()?['nombre'] as String?;
          
          // ✨ NUEVA VALIDACIÓN: Maestros deben estar aprobados
          if (tipoUsuario == 'maestro' && !estaAprobado) {
            await _firebaseAuth.signOut();
            _errorMessage = 'Tu registro como maestro está pendiente de aprobación. Por favor, espera a que un administrador valide tu solicitud.';
            _currentUser = null;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          // Actualizar displayName si existe en Firestore
          if (nombre != null && nombre.isNotEmpty) {
            await userCredential.user?.updateDisplayName(nombre);
          }
          
          if (!isActivo) {
            // Usuario deshabilitado, cerrar sesión inmediatamente
            await _firebaseAuth.signOut();
            _errorMessage = 'Tu cuenta ha sido deshabilitada. Contacta al administrador.';
            _currentUser = null;
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
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
