import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'authentication_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

/// Proveedores centralizados de servicios
/// Todos los servicios de la app se registran aquí
/// 
/// Uso en main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await FirebaseService().initialize();
///   runApp(
///     ServiceProviders.wrap(
///       const PlantelApp(),
///     ),
///   );
/// }
/// ```
class ServiceProviders {
  /// Lista de providers para Provider
  static final List<ChangeNotifierProvider<ChangeNotifier>> providers = [
    ChangeNotifierProvider<AuthenticationService>(
      create: (_) => AuthenticationService(),
    ),
    ChangeNotifierProvider<FirestoreService>(
      create: (_) => FirestoreService(),
    ),
  ];

  /// Método para agregar todos los providers a la app
  /// Incluye Provider<StorageService>() de forma manual
  static MultiProvider wrap(Widget child) {
    return MultiProvider(
      providers: [
        ...providers,
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
      ],
      child: child,
    );
  }
}
