import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_constants.dart';
import '../../models/student_report_model.dart';
import '../../services/authentication_service.dart';
import '../../services/admin_service.dart';
import '../../models/category_model.dart';
import '../../services/quiz_service.dart';
import '../quiz_screen.dart';

/// Pantalla principal del estudiante
/// Muestra categorías disponibles, progreso general y acceso a tests
class StudentDashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const StudentDashboardScreen({super.key, this.onLogout});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _quizService = QuizService();
  final _adminService = AdminService();

  late Future<List<CategoryModel>> _futureCategories;
  StudentReportModel? _reporteEstudiante;
  String _studentName = 'Estudiante';

  @override
  void initState() {
    super.initState();
    _futureCategories = _quizService.getCategories();
    _cargarReporte();
    _cargarNombreEstudiante();
  }

  Future<void> _cargarNombreEstudiante() async {
    final authService = context.read<AuthenticationService>();
    final userId = authService.currentUser?.uid;
    final displayName = authService.currentUser?.displayName;

    // Si tiene displayName en Auth, usarlo
    if (displayName != null && displayName.isNotEmpty) {
      setState(() => _studentName = displayName);
      return;
    }

    // Si no, buscar en Firestore
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .get();

        if (mounted && userDoc.exists) {
          final nombre = userDoc.data()?['nombre'] as String?;
          if (nombre != null && nombre.isNotEmpty) {
            setState(() => _studentName = nombre);
          }
        }
      } catch (e) {
        print('Error cargando nombre: $e');
      }
    }
  }

  Future<void> _cargarReporte() async {
    final userId = context.read<AuthenticationService>().currentUser?.uid;
    if (userId != null) {
      final reporte = await _adminService.obtenerReporteEstudiante(userId);
      if (mounted) {
        setState(() => _reporteEstudiante = reporte);
      }
    }
  }

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
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthenticationService>().logout();
              widget.onLogout?.call();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLANEA - Matemáticas'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo personalizado - FULL WIDTH
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.colorPrimario, AppConstants.colorPrimario.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $_studentName!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prepárate para el examen PLANEA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Resumen de progreso general
            if (_reporteEstudiante != null) ...[
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu Progreso General',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressCard(
                            title: 'Promedio',
                            value: '${_reporteEstudiante!.promedioGeneral.toStringAsFixed(1)}%',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressCard(
                            title: 'Tests',
                            value: _reporteEstudiante!.totalTestsRealizados.toString(),
                            icon: Icons.assignment,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressCard(
                            title: 'Aciertos',
                            value: _reporteEstudiante!.totalAciertos.toString(),
                            icon: Icons.check_circle,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Chip(
                      label: Text(_reporteEstudiante!.obtenerNivelDesempenio()),
                      backgroundColor: _getColorForNivel(_reporteEstudiante!.obtenerNivelDesempenio()),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            // Categorías disponibles
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
                vertical: AppConstants.paddingMedium,
              ),
              child: Text(
                'Categorías Disponibles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Lista de categorías
            FutureBuilder<List<CategoryModel>>(
              future: _futureCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingLarge),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Center(
                      child: Text(
                        'No hay categorías disponibles',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                final categories = snapshot.data!;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryPerformance = _reporteEstudiante?.desempenoPorCategoria[category.id];

                    return _buildCategoryCard(
                      context,
                      category,
                      categoryPerformance,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel category,
    CategoryPerformance? performance,
  ) {
    final percentage = performance?.porcentaje ?? 0.0;
    final level = performance?.obtenerNivelCategoria() ?? 'Sin intentos';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () async {
          // Iniciar quiz
          try {
            final progress = await _quizService.startQuiz(category.id);
            if (!mounted) return;

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  category: category,
                  initialProgress: progress,
                ),
              ),
            );

            // Recargar reporte después de terminar
            _cargarReporte();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.descripcion ?? 'Práctica de ${category.nombre}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getColorForPercentage(percentage).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorForPercentage(percentage),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    _getColorForPercentage(percentage),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    level,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getColorForPercentage(percentage),
                    ),
                  ),
                  if (performance != null)
                    Text(
                      '${performance.aciertos}/${performance.intentos}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final progress = await _quizService.startQuiz(category.id);
                      if (!mounted) return;

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            category: category,
                            initialProgress: progress,
                          ),
                        ),
                      );

                      _cargarReporte();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForNivel(String nivel) {
    switch (nivel) {
      case 'Excelente':
        return Colors.green.shade100;
      case 'Bueno':
        return Colors.blue.shade100;
      case 'Regular':
        return Colors.yellow.shade100;
      case 'Necesita Mejorar':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
