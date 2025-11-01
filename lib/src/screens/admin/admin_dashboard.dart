import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_estudiantes_screen.dart';
import 'admin_reactivos_screen.dart';
import 'admin_categorias_screen.dart';
import 'admin_reportes_screen.dart';
import 'admin_maestros_validation_screen.dart';
import '../user_profile_modal.dart';
import '../cambiar_password_screen.dart';
import '../../services/authentication_service.dart';
import '../../utils/firestore_seed.dart';

/// Dashboard Principal para Admin
/// Pantalla de inicio con opciones para gestionar:
/// - Estudiantes
/// - Reactivos (preguntas)
/// - Categorías
/// - Reportes
/// - Validación de maestros
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = context.read<AuthenticationService>();
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Administrativo',
              style: TextStyle(fontSize: isMobile ? 16 : 18),
            ),
            Text(
              'PLANEA - Matemáticas',
              style: TextStyle(
                fontSize: isMobile ? 9 : 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                showDialog(
                  context: context,
                  builder: (_) => const UserProfileModal(),
                );
              } else if (value == 'cambiar_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CambiarPasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'cambiar_password',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Cambiar contraseña'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.account_circle),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👋 ¡Bienvenido Admin!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona estudiantes, maestros y exámenes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Opciones del dashboard
            Text(
              'Gestión del Sistema',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Card: Estudiantes
            _buildAdminCard(
              icon: Icons.people,
              title: '👥 Usuarios',
              description: 'Gestionar padrón de estudiantes y calificaciones',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminEstudiantesScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Card: Reactivos
            _buildAdminCard(
              icon: Icons.quiz,
              title: '❓ Reactivos',
              description: 'Crear y editar preguntas del examen',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReactivosScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Card: Categorías
            _buildAdminCard(
              icon: Icons.category,
              title: '📂 Categorías',
              description: 'Gestionar temas: Álgebra, Geometría, etc.',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCategoriasScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Card: Reportes
            _buildAdminCard(
              icon: Icons.bar_chart,
              title: '📊 Reportes',
              description: 'Ver desempeño y estadísticas de estudiantes',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportesScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Card: Validar Maestros
            _buildAdminCard(
              icon: Icons.verified_user,
              title: '✨ Validar Maestros',
              description: 'Aprobar solicitudes de nuevos maestros',
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminMaestrosValidationScreen()),
              ),
            ),
            const SizedBox(height: 32),

            // 🌱 Card: Seed Data (Inicializar Base de Datos)
            _buildAdminCard(
              icon: Icons.storage,
              title: '🌱 Inicializar BD',
              description: 'Crear categorías y reactivos de prueba',
              color: Colors.green,
              onTap: () => _mostrarDialogoSeedData(),
            ),
            const SizedBox(height: 32),

            // Información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Todos los cambios se guardan automáticamente en Firestore.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra diálogo para ejecutar seed data
  void _mostrarDialogoSeedData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌱 Inicializar Base de Datos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esto creará:'),
            SizedBox(height: 8),
            Text('✅ 5 Categorías (Álgebra, Geometría, etc.)'),
            Text('✅ 16 Reactivos (preguntas de prueba)'),
            SizedBox(height: 16),
            Text('¿Deseas continuar?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _ejecutarSeedData();
            },
            icon: const Icon(Icons.check),
            label: const Text('Crear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Ejecuta el seed data y muestra progreso
  Future<void> _ejecutarSeedData() async {
    if (!mounted) return;

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Text('Inicializando base de datos...'),
          ],
        ),
      ),
    );

    try {
      // Ejecutar seed
      await FirestoreSeedData.seedAll();

      if (!mounted) return;

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Mostrar éxito
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Éxito'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Base de datos inicializada correctamente.'),
              SizedBox(height: 12),
              Text('✅ Categorías creadas'),
              Text('✅ Reactivos creados'),
              SizedBox(height: 12),
              Text('Ahora puedes crear tests para los estudiantes.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      print('✅ Seed data completado exitosamente');
    } catch (e) {
      if (!mounted) return;

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Mostrar error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Error'),
          content: Text('Error inicializando BD: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      print('❌ Error en seed data: $e');
    }
  }

  /// Construye una tarjeta de opción para el dashboard
  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
