import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_estudiantes_screen.dart';
import 'admin_reactivos_screen.dart';
import 'admin_categorias_screen.dart';
import 'admin_reportes_screen.dart';
import '../user_profile_modal.dart';
import '../../services/admin_service.dart';
import '../../services/authentication_service.dart';

/// Dashboard Principal para Admin
/// Pantalla de inicio con opciones para gestionar:
/// - Estudiantes
/// - Reactivos (preguntas)
/// - Categorías
/// - Reportes
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late AdminService _adminService;
  
  // Opciones del dashboard
  final List<DashboardOption> _options = [
    DashboardOption(
      titulo: 'Estudiantes',
      descripcion: 'Gestionar padrón de estudiantes',
      icono: Icons.people,
      color: Colors.blue,
      ruta: '/admin/estudiantes',
    ),
    DashboardOption(
      titulo: 'Reactivos',
      descripcion: 'Crear y editar preguntas del examen',
      icono: Icons.quiz,
      color: Colors.orange,
      ruta: '/admin/reactivos',
    ),
    DashboardOption(
      titulo: 'Categorías',
      descripcion: 'Gestionar categorías de matemáticas',
      icono: Icons.category,
      color: Colors.purple,
      ruta: '/admin/categorias',
    ),
    DashboardOption(
      titulo: 'Reportes',
      descripcion: 'Ver desempeño de estudiantes',
      icono: Icons.bar_chart,
      color: Colors.green,
      ruta: '/admin/reportes',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isWeb = screenWidth >= 1200;

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
              'Preparación PLANEA - Matemáticas',
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
              } else if (value == 'logout') {
                _showLogoutConfirmation(context);
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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.account_circle,
                size: isMobile ? 24 : 28,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 12 : 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado del sistema - más compacto
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: isMobile ? 16 : 20,
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(
                      child: Text(
                        '✓ Sistema Operativo - Todas las funciones disponibles',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 20),

              // Grid de opciones - Más compacto
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWeb ? 4 : (isTablet ? 3 : 2),
                  crossAxisSpacing: isMobile ? 8 : 12,
                  mainAxisSpacing: isMobile ? 8 : 12,
                  childAspectRatio: isMobile ? 0.95 : (isTablet ? 1.05 : 1.1),
                ),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  return _buildOptionCardModerno(option, isMobile);
                },
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Estadísticas rápidas
              FutureBuilder<Map<String, dynamic>>(
                future: _adminService.obtenerEstadisticasGenerales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final stats = snapshot.data ?? {
                    'totalEstudiantes': 0,
                    'totalReactivos': 0,
                    'totalCategorias': 6,
                    'totalTests': 0,
                  };

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estadísticas',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWeb ? 4 : (isTablet ? 2 : 2),
                        crossAxisSpacing: isMobile ? 8 : 10,
                        mainAxisSpacing: isMobile ? 8 : 10,
                        childAspectRatio: isMobile ? 1.35 : (isTablet ? 1.2 : 1.1),
                        children: [
                          _buildStatCardModerno(
                            'Estudiantes',
                            stats['totalEstudiantes'].toString(),
                            Colors.blue,
                            Icons.people,
                            isMobile,
                          ),
                          _buildStatCardModerno(
                            'Reactivos',
                            stats['totalReactivos'].toString(),
                            Colors.orange,
                            Icons.quiz,
                            isMobile,
                          ),
                          _buildStatCardModerno(
                            'Categorías',
                            stats['totalCategorias'].toString(),
                            Colors.purple,
                            Icons.category,
                            isMobile,
                          ),
                          _buildStatCardModerno(
                            'Tests',
                            stats['totalTests'].toString(),
                            Colors.green,
                            Icons.assignment,
                            isMobile,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta moderna para opciones del dashboard
  Widget _buildOptionCardModerno(DashboardOption option, bool isMobile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navegarA(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                option.color.withOpacity(0.1),
                option.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: option.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option.icono,
                  size: isMobile ? 24 : 32,
                  color: option.color,
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  option.titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  option.descripcion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 10,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta moderna para estadísticas
  Widget _buildStatCardModerno(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isMobile,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 16 : 20,
                color: color,
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 8 : 9,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarA(DashboardOption option) {
    Widget? pantalla;
    
    switch (option.titulo) {
      case 'Estudiantes':
        pantalla = const AdminEstudiantesScreen();
        break;
      case 'Reactivos':
        pantalla = const AdminReactivosScreen();
        break;
      case 'Categorías':
        pantalla = const AdminCategoriasScreen();
        break;
      case 'Reportes':
        pantalla = const AdminReportesScreen();
        break;
    }
    
    if (pantalla != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => pantalla!),
      );
    }
  }

  /// Muestra confirmación antes de cerrar sesión
  void _showLogoutConfirmation(BuildContext context) {
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
              final authService =
                  context.read<AuthenticationService>();
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
}

/// Modelo para cada opción del dashboard
class DashboardOption {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final String ruta;

  DashboardOption({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.ruta,
  });
}
