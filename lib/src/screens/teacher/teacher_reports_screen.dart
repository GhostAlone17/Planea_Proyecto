import 'package:flutter/material.dart';
import '../../services/teacher_service.dart';
import '../../models/student_report_model.dart';

/// Pantalla para ver los reportes de los estudiantes del maestro
class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  late TeacherService _teacherService;
  String _sortBy = 'nombre'; // 'nombre', 'promedio', 'tests'

  @override
  void initState() {
    super.initState();
    _teacherService = TeacherService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Estudiantes'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Opciones de ordenamiento
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Ordenar por: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                      DropdownMenuItem(value: 'promedio', child: Text('Promedio')),
                      DropdownMenuItem(value: 'tests', child: Text('Tests')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Lista de reportes
          Expanded(
            child: FutureBuilder<List<StudentReportModel>>(
              future: _teacherService.obtenerReportesMisEstudiantes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var reportes = snapshot.data ?? [];

                // Ordenar según la opción seleccionada
                switch (_sortBy) {
                  case 'promedio':
                    reportes.sort(
                      (a, b) => b.promedioGeneral.compareTo(a.promedioGeneral),
                    );
                    break;
                  case 'tests':
                    reportes.sort(
                      (a, b) =>
                          b.totalTestsRealizados.compareTo(a.totalTestsRealizados),
                    );
                    break;
                  default:
                    reportes.sort((a, b) => a.userName.compareTo(b.userName));
                }

                if (reportes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay reportes disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reportes.length,
                  itemBuilder: (context, index) {
                    final reporte = reportes[index];
                    return _buildReportCard(reporte, index + 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta de reporte
  Widget _buildReportCard(StudentReportModel reporte, int posicion) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          _showReportDetails(reporte);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Posición y nombre
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reporte.userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nivel de desempeño
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(reporte.obtenerNivelDesempenio()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reporte.obtenerNivelDesempenio(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barra de progreso
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width:
                        (MediaQuery.of(context).size.width - 64) *
                        (reporte.promedioGeneral / 100),
                    decoration: BoxDecoration(
                      color: _getColorForPercentage(reporte.promedioGeneral),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Estadísticas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildReportStat(
                    '${reporte.promedioGeneral.toStringAsFixed(1)}%',
                    'Promedio',
                  ),
                  _buildReportStat(
                    '${reporte.totalAciertos}/${reporte.totalIntentos}',
                    'Aciertos',
                  ),
                  _buildReportStat(
                    '${reporte.totalTestsRealizados}',
                    'Tests',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un stat del reporte
  Widget _buildReportStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Mostrar detalles del reporte
  void _showReportDetails(StudentReportModel reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reporte.userName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', reporte.userEmail),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Promedio General',
                '${reporte.promedioGeneral.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Aciertos',
                '${reporte.totalAciertos}/${reporte.totalIntentos}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Tests Realizados',
                '${reporte.totalTestsRealizados}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Nivel de Desempeño',
                reporte.obtenerNivelDesempenio(),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Último Test',
                _formatDate(reporte.fechaUltimoTest),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Desempeño por Categoría:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (reporte.desempenoPorCategoria.isEmpty)
                const Text(
                  'Sin datos por categoría',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                )
              else
                ...reporte.desempenoPorCategoria.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.value.categoryNombre,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${entry.value.porcentaje.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getColorForPercentage(
                                  entry.value.porcentaje,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value.porcentaje / 100,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForPercentage(entry.value.porcentaje),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.value.aciertos}/${entry.value.intentos} aciertos',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Construye una fila de detalle
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Obtiene el color según el nivel
  Color _getLevelColor(String level) {
    switch (level) {
      case 'Excelente':
        return Colors.green;
      case 'Bueno':
        return Colors.blue;
      case 'Regular':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  /// Obtiene el color según el porcentaje
  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Formatea una fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
