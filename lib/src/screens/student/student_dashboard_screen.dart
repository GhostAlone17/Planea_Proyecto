import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_constants.dart';
import '../../models/student_report_model.dart';
import '../../services/authentication_service.dart';
import '../../services/admin_service.dart';
import '../../models/category_model.dart';
import '../../services/quiz_service.dart';
import '../../utils/grado_utils.dart';
import '../quiz_screen.dart';
import '../cambiar_password_screen.dart';

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
  String _gradoEstudiante = 'Primaria'; // ✨ NUEVO: Grado del estudiante

  @override
  void initState() {
    super.initState();
    // Inicializar siempre con categorías por defecto
    _futureCategories = _quizService.getCategories();
    // Luego intentar cargar por grado
    _cargarGradoYCategorias();
    _cargarReporte();
    _cargarNombreEstudiante();
  }

  /// ✨ NUEVO: Carga el grado del estudiante y actualiza categorías si es posible
  Future<void> _cargarGradoYCategorias() async {
    try {
      final authService = context.read<AuthenticationService>();
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .get();

        if (userDoc.exists && mounted) {
          // Intentar primero con 'gradoNombre', luego con 'gradoId'
          String? gradoId = userDoc.data()?['gradoNombre'] as String?;
          if (gradoId == null || gradoId.isEmpty) {
            gradoId = userDoc.data()?['gradoId'] as String?;
          }

          if (gradoId != null && gradoId.isNotEmpty) {
            // Convertir a nombre legible
            final gradoNombre = GradoUtils.getNombreGrado(gradoId);
            print('✅ Grado cargado desde Firestore: $gradoId -> $gradoNombre');
            if (mounted) {
              setState(() => _gradoEstudiante = gradoNombre);
              // Cargar categorías filtradas por grado (usar el nombre legible)
              _futureCategories = _quizService.getCategoriesByGrade(gradoNombre);
            }
          } else {
            print('⚠️ No se encontró gradoNombre ni gradoId para el usuario');
          }
        } else {
          print('⚠️ Documento de usuario no existe');
        }
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error cargando grado: $e');
      }
      // Mantener el fallback: categorías generales
    }
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
    try {
      final userId = context.read<AuthenticationService>().currentUser?.uid;
      if (userId != null) {
        final reporte = await _adminService.obtenerReporteEstudiante(userId);
        if (mounted) {
          setState(() => _reporteEstudiante = reporte);
        }
      }
    } catch (e) {
      if (mounted) {
        print('⚠️ Error cargando reporte: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'PLANEA • Matemáticas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'cambiar_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CambiarPasswordScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Saludo personalizado - Compacto y elegante
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 20 : 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.colorPrimario, 
                    AppConstants.colorPrimario.withOpacity(0.85)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, $_studentName!',
                              style: TextStyle(
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_gradoEstudiante • Prepárate para PLANEA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Contenedor principal con ancho máximo
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen de progreso general - Más compacto
                    if (_reporteEstudiante != null) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 16,
                          isDesktop ? 24 : 16,
                          isDesktop ? 24 : 16,
                          isDesktop ? 12 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tu Progreso',
                              style: TextStyle(
                                fontSize: isDesktop ? 16 : 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getColorForNivel(_reporteEstudiante!.obtenerNivelDesempenio()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _reporteEstudiante!.obtenerNivelDesempenio(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildProgressCard(
                                title: 'Promedio',
                                value: '${_reporteEstudiante!.promedioGeneral.toStringAsFixed(0)}%',
                                icon: Icons.trending_up,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildProgressCard(
                                title: 'Tests',
                                value: _reporteEstudiante!.totalTestsRealizados.toString(),
                                icon: Icons.assignment,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Categorías disponibles
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Categorías Disponibles',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // Lista de categorías
                    FutureBuilder<List<CategoryModel>>(
                      future: _futureCategories,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: EdgeInsets.all(isDesktop ? 40 : 30),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(isDesktop ? 40 : 30),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay categorías disponibles',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Ordenar alfabéticamente
                        final categories = snapshot.data!..sort((a, b) => a.nombre.compareTo(b.nombre));

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final categoryPerformance = _reporteEstudiante?.desempenoPorCategoria[category.id];
                              return _buildCategoryListItem(
                                context,
                                category,
                                categoryPerformance,
                              );
                            },
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isDesktop ? 40 : 24),
                  ],
                ),
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Item de categoría estilo admin - Limpio y profesional
  Widget _buildCategoryListItem(
    BuildContext context,
    CategoryModel category,
    CategoryPerformance? performance,
  ) {
    final percentage = performance?.porcentaje ?? 0.0;
    final color = _getColorForPercentage(percentage);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    // Iconos según la categoría
    IconData categoryIcon;
    Color iconBgColor;
    
    switch (category.nombre.toLowerCase()) {
      case 'estadística':
      case 'estadistica':
        categoryIcon = Icons.bar_chart_rounded;
        iconBgColor = Colors.orange.shade100;
        break;
      case 'geometría':
      case 'geometria':
        categoryIcon = Icons.category_rounded;
        iconBgColor = Colors.purple.shade100;
        break;
      case 'álgebra':
      case 'algebra':
        categoryIcon = Icons.functions_rounded;
        iconBgColor = Colors.blue.shade100;
        break;
      default:
        categoryIcon = Icons.quiz_rounded;
        iconBgColor = Colors.teal.shade100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _iniciarQuiz(context, category),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 18 : 16),
            child: Row(
              children: [
                // Icono grande estilo admin
                Container(
                  width: isWideScreen ? 56 : 52,
                  height: isWideScreen ? 56 : 52,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: color,
                    size: isWideScreen ? 28 : 26,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información de la categoría
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre de categoría
                      Text(
                        category.nombre,
                        style: TextStyle(
                          fontSize: isWideScreen ? 16 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Descripción con progreso
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              percentage > 0
                                  ? 'Progreso: ${percentage.toStringAsFixed(0)}% completado'
                                  : 'Comienza a practicar esta categoría',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Flecha de acción estilo admin
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isWideScreen ? 18 : 16,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Método para iniciar quiz con loading indicator
  Future<void> _iniciarQuiz(BuildContext context, CategoryModel category) async {
    // Guardar referencia del context de manera segura
    if (!mounted) return;
    
    // Crear identificador para el diálogo
    bool dialogShown = false;
    
    try {
      // Mostrar loading dialog que bloquea interacción
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false, // No permite cerrar tocando fuera
        builder: (_) => WillPopScope(
          onWillPop: () async => false, // Evita cerrar con botón atrás
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF1B5E20)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iniciando ${category.nombre}...',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      dialogShown = true;

      final progress = await _quizService.startQuiz(category.id);
      if (!mounted) return;

      // Cerrar loading dialog si está abierto
      if (dialogShown && Navigator.canPop(context)) {
        Navigator.pop(context); // Pop el diálogo
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            category: category,
            initialProgress: progress,
          ),
        ),
      );

      // Recargar reporte solo si el widget aún está en el árbol
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500)); // Pequeño delay para evitar loops
        if (mounted) {
          _cargarReporte();
        }
      }
    } catch (e) {
      if (!mounted) return;

      // Cerrar loading dialog si está abierto
      if (dialogShown && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      // Mejorar mensaje de error según tipo
      String mensajeUsuario = '❌ Error iniciando el test';
      
      if (e.toString().contains('No hay preguntas disponibles')) {
        mensajeUsuario = '⚠️ No hay preguntas disponibles en este test. Por favor contacta al administrador.';
      } else if (e.toString().contains('Usuario no autenticado')) {
        mensajeUsuario = '❌ Sesión expirada. Por favor, inicia sesión nuevamente.';
      } else if (e.toString().contains('conexión')) {
        mensajeUsuario = '❌ Error de conexión. Verifica tu conexión a internet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeUsuario),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
