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

                  // Sección en dos columnas para web, una para mobile
                  if (isWeb)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildSeccionDesempenio(isMobile, reportesEstudiantes),
                        ),
                        SizedBox(width: isMobile ? 12 : 20),
                        Expanded(
                          flex: 1,
                          child: _buildSeccionCategorias(isMobile, reportesEstudiantes),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeccionDesempenio(isMobile, reportesEstudiantes),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildSeccionCategorias(isMobile, reportesEstudiantes),
                      ],
                    ),
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

  /// Sección de Desempeño de Estudiantes
  Widget _buildSeccionDesempenio(bool isMobile, Map<String, StudentReportModel> reportesEstudiantes) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desempeño de Estudiantes',
              style: TextStyle(
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            
            // Filtro - más compacto
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...[
                    'Todos',
                    'Excelente',
                    'Bueno',
                    'Regular',
                    'Necesita Mejorar',
                  ].map((nivel) {
                    final isSelected = _filtroDesempenio == nivel;
                    return Padding(
                      padding: EdgeInsets.only(right: isMobile ? 4 : 8),
                      child: FilterChip(
                        label: Text(
                          nivel,
                          style: TextStyle(fontSize: isMobile ? 10 : 12),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _filtroDesempenio = nivel);
                        },
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 3 : 5,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Tabla de estudiantes
            _buildTablaEstudiantesCompacta(reportesEstudiantes),
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
                              Text(
                                categoria.icono,
                                style: TextStyle(fontSize: isMobile ? 16 : 20),
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
  /// Tabla compacta de estudiantes
  Widget _buildTablaEstudiantesCompacta(Map<String, StudentReportModel> reportesEstudiantes) {
    final reportesFiltrados = reportesEstudiantes.values.where((r) {
      if (_filtroDesempenio == 'Todos') return true;
      return r.obtenerNivelDesempenio() == _filtroDesempenio;
    }).toList();

    if (reportesFiltrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: const [
              Icon(Icons.info, color: Colors.grey, size: 32),
              SizedBox(height: 12),
              Text(
                'No hay estudiantes en este nivel',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // En pantallas pequeñas, mostrar lista en lugar de tabla
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        children: reportesFiltrados
            .map((reporte) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
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
                                      reporte.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      reporte.userEmail,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  reporte.obtenerNivelDesempenio(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: _getColorForNivel(
                                  reporte.obtenerNivelDesempenio(),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Promedio: ${reporte.promedioGeneral.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'Tests: ${reporte.totalTestsRealizados}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    }

    // Para pantallas más grandes, mostrar tabla
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        dataRowHeight: 48,
        headingRowHeight: 48,
        columns: const [
          DataColumn(label: Text('Estudiante', overflow: TextOverflow.ellipsis)),
          DataColumn(label: Text('Promedio', overflow: TextOverflow.ellipsis)),
          DataColumn(label: Text('Nivel', overflow: TextOverflow.ellipsis)),
          DataColumn(label: Text('Tests', overflow: TextOverflow.ellipsis)),
        ],
        rows: reportesFiltrados.map((reporte) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  reporte.userName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  '${reporte.promedioGeneral.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Chip(
                  label: Text(
                    reporte.obtenerNivelDesempenio(),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getColorForNivel(
                    reporte.obtenerNivelDesempenio(),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              DataCell(
                Text(
                  reporte.totalTestsRealizados.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        }).toList(),
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

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Muestra un diálogo para seleccionar el grado y generar reporte
  void _mostrarDialogoGradoReporte() {
    final grados = ['Primaria', 'Secundaria', 'Preparatoria'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona Grado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Para qué grado deseas generar el reporte?'),
            const SizedBox(height: 16),
            ...grados.map((grado) => ListTile(
              title: Text(grado),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenararReportesScreen(gradoNombre: grado),
                  ),
                );
              },
            )).toList(),
          ],
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

