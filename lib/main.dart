import 'package:flutter/material.dart';
import 'src/config/app_theme.dart';
import 'src/config/app_constants.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/categories_screen.dart';
import 'src/services/auth_service.dart';

/// Punto de entrada principal de la aplicación
/// Inicializa la app del Plantel
void main() {
  runApp(const PlantelApp());
}

/// Widget raíz de la aplicación
/// Configura el tema y la navegación inicial
class PlantelApp extends StatefulWidget {
  const PlantelApp({super.key});

  @override
  State<PlantelApp> createState() => _PlantelAppState();
}

class _PlantelAppState extends State<PlantelApp> {
  final AuthService _authService = AuthService();

  void _handleLogin() {
    setState(() {});
  }

  void _handleLogout() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ============ CONFIGURACIÓN GENERAL ============
      
      /// Título de la aplicación
      title: AppConstants.appName,
      
      /// Desactiva el banner de debug
      debugShowCheckedModeBanner: false,
      
      /// Tema de la aplicación
      theme: AppTheme.lightTheme,
      
      // ============ PANTALLA INICIAL ============
      
    /// Página inicial de la aplicación
    home: _authService.currentUser == null
      ? LoginScreen(onLogin: _handleLogin)
      : CategoriesScreen(onLogout: _handleLogout),
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
              AuthService().logout();
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
