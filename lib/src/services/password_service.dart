import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para gestión de contraseñas
class PasswordService {
  static final PasswordService _instance = PasswordService._internal();
  factory PasswordService() => _instance;
  PasswordService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Contraseña por defecto para nuevos usuarios
  static const String DEFAULT_PASSWORD = 'planea123';

  /// Cambia la contraseña del usuario autenticado
  /// Requiere que el usuario esté autenticado
  Future<({bool success, String message})> cambiarPassword({
    required String passwordAntigua,
    required String passwordNueva,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return (success: false, message: 'No hay usuario autenticado');
      }

      // Re-autenticar con la contraseña antigua
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordAntigua,
      );

      await user.reauthenticateWithCredential(credential);

      // Cambiar a la nueva contraseña
      await user.updatePassword(passwordNueva);

      return (
        success: true,
        message: '✅ Contraseña cambiada exitosamente'
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al cambiar la contraseña';
      
      if (e.code == 'wrong-password') {
        mensaje = 'La contraseña actual es incorrecta';
      } else if (e.code == 'weak-password') {
        mensaje = 'La nueva contraseña es muy débil';
      } else if (e.code == 'requires-recent-login') {
        mensaje = 'Por favor, inicia sesión nuevamente';
      }

      return (success: false, message: mensaje);
    } catch (e) {
      return (success: false, message: 'Error inesperado: $e');
    }
  }

  /// Restablece la contraseña enviando un correo
  Future<({bool success, String message})> enviarRestablecimientoContrasena(
    String email,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return (
        success: true,
        message: '✅ Se envió un correo para restablecer la contraseña'
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al enviar el correo';
      
      if (e.code == 'user-not-found') {
        mensaje = 'No existe usuario con este correo';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no es válido';
      }

      return (success: false, message: mensaje);
    } catch (e) {
      return (success: false, message: 'Error inesperado: $e');
    }
  }

  /// Valida que la contraseña cumpla con los requisitos
  static ({bool isValid, String message}) validarContrasena(
    String password,
  ) {
    // Requisitos mínimos
    if (password.length < 6) {
      return (
        isValid: false,
        message: 'La contraseña debe tener al menos 6 caracteres'
      );
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return (
        isValid: false,
        message: 'La contraseña debe contener al menos un número'
      );
    }

    return (isValid: true, message: 'Contraseña válida');
  }

  /// Genera una contraseña temporal
  static String generarPasswordTemporal() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'Planea${random.substring(random.length - 4)}';
  }
}
