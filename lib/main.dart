import 'package:flutter/material.dart';
import 'src/config/app_theme.dart';
import 'src/config/app_constants.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/categories_screen.dart';
import 'src/screens/admin/admin_dashboard.dart';
import 'src/services/firebase_service.dart';
import 'src/services/service_providers.dart';
import 'package:provider/provider.dart';
import 'src/services/authentication_service.dart';
import 'src/services/firestore_service.dart';

/// Punto de entrada principal de la aplicación
/// Inicializa Firebase y la estructura de la app
void main() async {
  // Asegurar que Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('❌ Error inicializando Firebase: $e');
    debugPrint('💡 Asegúrate de ejecutar: flutterfire configure --project=planea-proyecto');
  }

  runApp(const PlantelApp());
}

/// Widget raíz de la aplicación
/// Configura el tema, providers y la navegación inicial
class PlantelApp extends StatelessWidget {
  const PlantelApp({super.key});

  /// Verifica si el usuario actual es un administrador
  Future<bool> _verificarSiEsAdmin(AuthenticationService authService) async {
    try {
      final userId = authService.currentUser?.uid;
      if (userId == null) return false;

      final firestoreService = FirestoreService();
      final userData = await firestoreService.getDocument(
        collection: 'usuarios',
        docId: userId,
      );

      if (userData != null) {
        return userData['tipoUsuario'] == 'admin' ||
            userData['tipoUsuario'] == 'docente';
      }

      return false;
    } catch (e) {
      debugPrint('Error verificando si es admin: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceProviders.wrap(
      MaterialApp(
        // ============ CONFIGURACIÓN GENERAL ============

        /// Título de la aplicación
        title: AppConstants.appName,

        /// Desactiva el banner de debug
        debugShowCheckedModeBanner: false,

        /// Tema de la aplicación
        theme: AppTheme.lightTheme,

        // ============ PANTALLA INICIAL ============

        /// Página inicial de la aplicación
        home: Consumer<AuthenticationService>(
          builder: (context, authService, _) {
            if (authService.isLoading) {
              return Scaffold(
                appBar: AppBar(title: const Text(AppConstants.appName)),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (authService.isAuthenticated) {
              // Verificar si es admin
              return FutureBuilder<bool>(
                future: _verificarSiEsAdmin(authService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      appBar: AppBar(
                          title: const Text(AppConstants.appName)),
                      body: const Center(
                          child: CircularProgressIndicator()),
                    );
                  }

                  final esAdmin = snapshot.data ?? false;

                  return esAdmin
                      ? AdminDashboard()
                      : CategoriesScreen(
                          onLogout: () {
                            authService.logout();
                          },
                        );
                },
              );
            }

            return LoginScreen(
              onLogin: () {
                // El estado se actualiza automáticamente
              },
            );
          },
        ),
      ),
    );
  }
}

/// Pantalla temporal de inicio
/// Esta será reemplazada en etapas posteriores por el sistema de login
class HomeTemporalScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  const HomeTemporalScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============ BARRA DE APLICACIÓN ============
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<AuthenticationService>().logout();
              onLogout?.call();
            },
          ),
        ],
      ),
      
      // ============ CUERPO DE LA PANTALLA ============
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de la aplicación
              Icon(
                Icons.school,
                size: 100,
                color: AppConstants.colorPrimario,
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Título de bienvenida
              Text(
                '¡Bienvenido!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Descripción
              Text(
                'App del Plantel - Sistema de comunicación\npara alumnos, padres de familia y docentes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.colorTextoSecundario,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge * 2),
              
              // Información de la etapa actual
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppConstants.colorAcento,
                        size: 40,
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        'ETAPA 1 COMPLETADA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppConstants.colorPrimario,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        'Estructura base y modelos creados',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        'Versión ${AppConstants.appVersion}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
