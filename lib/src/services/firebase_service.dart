import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Servicio centralizado para inicializar Firebase
/// Maneja la configuración de Firebase para Web, iOS y Android
/// 
/// Nota: firebase_options.dart contiene las credenciales de tu proyecto
/// Si necesitas cambiarlas, actualiza ese archivo
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  bool _isInitialized = false;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  /// Getter para saber si Firebase está inicializado
  bool get isInitialized => _isInitialized;

  /// Inicializa Firebase
  /// Debe llamarse en main() antes de ejecutar la app
  /// 
  /// Ejemplo en main.dart:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await FirebaseService().initialize();
  ///   runApp(const PlantelApp());
  /// }
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Firebase ya está inicializado');
      return;
    }

    try {
      debugPrint('🔥 Inicializando Firebase...');
      
      // Importar firebase_options.dart con las credenciales del proyecto
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _isInitialized = true;
      debugPrint('✅ Firebase inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase: $e');
      debugPrint('💡 Verifica que firebase_options.dart tiene las credenciales correctas');
      rethrow;
    }
  }
}
