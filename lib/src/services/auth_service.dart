import '../models/user_model.dart';

/// Servicio simulado de autenticación
/// En etapas futuras se conectará con Firebase o API
class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Usuario actualmente autenticado (simulado)
  UserModel? _currentUser;

  /// Retorna el usuario autenticado
  UserModel? get currentUser => _currentUser;

  /// Simula el login con email y contraseña
  /// Retorna true si el login es exitoso
  Future<bool> login(String email, String password) async {
    // Simulación: acepta cualquier email y contraseña "123456"
    await Future.delayed(const Duration(seconds: 1));
    if (password == '123456') {
      _currentUser = UserModel(
        id: '1',
        nombre: 'Usuario Demo',
        email: email,
        tipoUsuario: 'alumno',
        fechaRegistro: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  /// Simula el registro de usuario
  Future<bool> register(String nombre, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password.length >= 6) {
      _currentUser = UserModel(
        id: '2',
        nombre: nombre,
        email: email,
        tipoUsuario: 'alumno',
        fechaRegistro: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  /// Cierra la sesión del usuario
  void logout() {
    _currentUser = null;
  }
}
