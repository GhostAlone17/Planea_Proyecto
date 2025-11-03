import 'package:flutter/material.dart';
import '../../models/student_report_model.dart';
import '../../models/category_model_v2.dart';
import '../generar_reportes_screen.dart';
import '../../services/admin_service.dart';

/// Pantalla para ver reportes y estadísticas de estudiantes
class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  final List<CategoryModelV2> _categorias = CategoryModelV2.categoriasDefault();
  final AdminService _adminService = AdminService();
  
  // 🔄 DINÁMICO: Cargar reportes desde Firestore en lugar de hardcoded
  late Future<Map<String, StudentReportModel>> _futuroReportes;
  String _filtroDesempenio = 'Todos';
  
  // ✨ PAGINACIÓN
  int _paginaActual = 0;
  final int _estudiantesPorPagina = 5;

  @override
  void initState() {
    super.initState();
    _futuroReportes = _cargarReportes();
  }

  /// Carga todos los reportes de estudiantes desde Firestore
  Future<Map<String, StudentReportModel>> _cargarReportes() async {
    try {
      final reportes = await _adminService.obtenerTodosLosReportes();
      final mapa = <String, StudentReportModel>{};
      for (var reporte in reportes) {
        mapa[reporte.userId] = reporte;
      }
      print('✅ Reportes cargados: ${mapa.length} estudiantes');
      return mapa;
    } catch (e) {
      print('❌ Error cargando reportes: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isWeb = screenWidth >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportes y Estadísticas',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Generar Reporte',
            onPressed: () => _mostrarDialogoGradoReporte(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, StudentReportModel>>(
        future: _futuroReportes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final reportesEstudiantes = snapshot.data ?? {};

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 12 : 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header mejorado - más compacto
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: isMobile ? 20 : 28,
                        color: Colors.orange,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reportes y Estadísticas',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : (isTablet ? 20 : 24),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Análisis del desempeño PLANEA',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 20),

                  // Tarjetas de estadísticas generales (Responsive)
                  _buildEstadisticasGenerales(isWeb, isMobile, reportesEstudiantes),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Sección de Categorías (principal)
                  _buildSeccionCategorias(isMobile, reportesEstudiantes),
                  SizedBox(height: isMobile ? 16 : 24),
                  
                  // Sección de Desempeño de Estudiantes (separada, con paginación)
                  _buildSeccionDesempenioMejorada(isMobile, isTablet, reportesEstudiantes),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEstadisticasGenerales(bool isWeb, bool isMobile, Map<String, StudentReportModel> reportesEstudiantes) {
    final totalEstudiantes = reportesEstudiantes.length;
    final promedioGeneral = reportesEstudiantes.isEmpty
        ? 0.0
        : reportesEstudiantes.values
                .map((r) => r.promedioGeneral)
                .reduce((a, b) => a + b) /
            reportesEstudiantes.length;

    // Responsive grid: 4 cols web, 2 cols mobile
    int crossAxisCount = isMobile ? 2 : (isWeb ? 4 : 2);
    double childAspectRatio = isMobile ? 1.4 : 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: TextStyle(
            fontSize: isMobile ? 13 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: isMobile ? 8 : 12,
          mainAxisSpacing: isMobile ? 8 : 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              title: 'Estudiantes',
              value: totalEstudiantes.toString(),
              icon: Icons.people,
              color: Colors.blue,
              isMobile: isMobile,
            ),
            _buildStatCard(
              title: 'Promedio',
              value: '${promedioGeneral.toStringAsFixed(1)}%',
              icon: Icons.trending_up,
              color: Colors.green,
              isMobile: isMobile,
            ),
            _buildStatCard(
              title: 'Tests',
              value: reportesEstudiantes.values
                  .fold(0, (sum, r) => sum + r.totalTestsRealizados)
                  .toString(),
              icon: Icons.assignment,
              color: Colors.orange,
              isMobile: isMobile,
            ),
            _buildStatCard(
              title: 'Categorías',
              value: _categorias.length.toString(),
              icon: Icons.category,
              color: Colors.purple,
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  /// Sección MEJORADA de Desempeño de Estudiantes con paginación
  Widget _buildSeccionDesempenioMejorada(bool isMobile, bool isTablet, Map<String, StudentReportModel> reportesEstudiantes) {
    // Filtrar estudiantes
    final reportesFiltrados = reportesEstudiantes.values.where((r) {
      if (_filtroDesempenio == 'Todos') return true;
      return r.obtenerNivelDesempenio() == _filtroDesempenio;
    }).toList();

    // Ordenar por promedio (descendente)
    reportesFiltrados.sort((a, b) => b.promedioGeneral.compareTo(a.promedioGeneral));

    // Paginación
    final totalEstudiantes = reportesFiltrados.length;
    final totalPaginas = (totalEstudiantes / _estudiantesPorPagina).ceil();
    
    // Asegurar que la página actual está en rango válido
    if (_paginaActual >= totalPaginas && totalPaginas > 0) {
      _paginaActual = totalPaginas - 1;
    }
    if (_paginaActual < 0) _paginaActual = 0;

    final inicio = _paginaActual * _estudiantesPorPagina;
    final fin = (inicio + _estudiantesPorPagina).clamp(0, totalEstudiantes);
    final estudiantesPagina = reportesFiltrados.sublist(
      inicio,
      fin,
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ícono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.people_alt,
                    color: Colors.blue.shade700,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desempeño de Estudiantes',
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalEstudiantes estudiante${totalEstudiantes != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Filtros
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Todos',
                'Excelente',
                'Bueno',
                'Regular',
                'Necesita Mejorar',
              ].map((nivel) {
                final isSelected = _filtroDesempenio == nivel;
                return FilterChip(
                  label: Text(
                    nivel,
                    style: TextStyle(fontSize: isMobile ? 11 : 12),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtroDesempenio = nivel;
                      _paginaActual = 0; // Resetear a primera página al cambiar filtro
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                );
              }).toList(),
            ),
            
            if (estudiantesPagina.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay estudiantes en este nivel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 16),
              
              // Lista de estudiantes
              ...estudiantesPagina.asMap().entries.map((entry) {
                final index = entry.key;
                final reporte = entry.value;
                final posicionGlobal = inicio + index + 1;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        '$posicionGlobal',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reporte.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 13 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorForNivel(reporte.obtenerNivelDesempenio()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getColorForNivel(reporte.obtenerNivelDesempenio()).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            reporte.obtenerNivelDesempenio(),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, size: isMobile ? 12 : 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reporte.userEmail,
                              style: TextStyle(fontSize: isMobile ? 11 : 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.percent, size: isMobile ? 14 : 16, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '${reporte.promedioGeneral.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined, size: isMobile ? 12 : 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${reporte.totalTestsRealizados} tests',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              // Controles de paginación
              if (totalPaginas > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Página ${_paginaActual + 1} de $totalPaginas',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _paginaActual > 0
                              ? () => setState(() => _paginaActual--)
                              : null,
                          tooltip: 'Página anterior',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _paginaActual < totalPaginas - 1
                              ? () => setState(() => _paginaActual++)
                              : null,
                          tooltip: 'Página siguiente',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Sección de Desempeño por Categoría
  Widget _buildSeccionCategorias(bool isMobile, Map<String, StudentReportModel> reportesEstudiantes) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desempeño por Categoría',
              style: TextStyle(
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            ...(_categorias.map((categoria) {
              // Calcular estadísticas de esta categoría
              int totalAciertos = 0;
              int totalReactivos = 0;

              for (var reporte in reportesEstudiantes.values) {
                if (reporte.desempenoPorCategoria.containsKey(categoria.id)) {
                  final perf = reporte.desempenoPorCategoria[categoria.id]!;
                  totalAciertos += perf.aciertos;
                  totalReactivos += perf.intentos;
                }
              }

              final porcentaje = totalReactivos > 0
                  ? (totalAciertos / totalReactivos * 100)
                  : 0.0;

              return Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(categoria.nombre),
                                color: _getCategoryIconColor(categoria.nombre),
                                size: isMobile ? 18 : 22,
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              Expanded(
                                child: Text(
                                  categoria.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isMobile ? 11 : 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${porcentaje.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: isMobile ? 11 : 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalReactivos > 0 ? porcentaje / 100 : 0,
                        minHeight: isMobile ? 5 : 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          _getColorForPercentage(porcentaje),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 3 : 4),
                    Text(
                      '$totalAciertos de $totalReactivos correctos',
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              icon,
              size: isMobile ? 20 : 28,
              color: color,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 14 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: isMobile ? 9 : 11,
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

  /// Obtener icono de Material según la categoría
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'estadística':
      case 'estadistica':
        return Icons.bar_chart_rounded;
      case 'geometría':
      case 'geometria':
        return Icons.category_rounded;
      case 'álgebra':
      case 'algebra':
        return Icons.functions_rounded;
      case 'trigonometría':
      case 'trigonometria':
        return Icons.architecture_rounded;
      case 'cálculo':
      case 'calculo':
        return Icons.trending_up_rounded;
      case 'lógica matemática':
      case 'logica matematica':
      case 'lógica':
      case 'logica':
        return Icons.psychology_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  /// Obtener color del icono según la categoría
  Color _getCategoryIconColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'estadística':
      case 'estadistica':
        return Colors.orange.shade700;
      case 'geometría':
      case 'geometria':
        return Colors.purple.shade700;
      case 'álgebra':
      case 'algebra':
        return Colors.blue.shade700;
      case 'trigonometría':
      case 'trigonometria':
        return Colors.pink.shade700;
      case 'cálculo':
      case 'calculo':
        return Colors.green.shade700;
      case 'lógica matemática':
      case 'logica matematica':
      case 'lógica':
      case 'logica':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Muestra un diálogo para seleccionar el grado y generar reporte
  void _mostrarDialogoGradoReporte() {
    // ✨ Grados disponibles con sus años específicos
    final gradosDisponibles = [
      {
        'nivel': 'Primaria',
        'grados': ['4° Primaria', '6° Primaria'],
        'icono': Icons.child_care,
        'color': Colors.blue.shade700,
      },
      {
        'nivel': 'Secundaria',
        'grados': ['3° Secundaria'],
        'icono': Icons.school_outlined,
        'color': Colors.purple.shade700,
      },
      {
        'nivel': 'Preparatoria',
        'grados': ['3° Preparatoria'],
        'icono': Icons.auto_stories,
        'color': Colors.orange.shade700,
      },
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assessment, color: Colors.blue),
            SizedBox(width: 12),
            Text('Generar Reporte'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Para qué nivel deseas generar el reporte?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Grados disponibles en el sistema',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ...gradosDisponibles.map((nivel) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      nivel['icono'] as IconData,
                      color: nivel['color'] as Color,
                      size: 28,
                    ),
                    title: Text(
                      nivel['nivel'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      (nivel['grados'] as List<String>).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenararReportesScreen(
                            gradoNombre: nivel['nivel'] as String,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

