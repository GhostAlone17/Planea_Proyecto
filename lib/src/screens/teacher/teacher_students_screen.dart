import 'package:flutter/material.dart';
import '../../services/teacher_service.dart';
import '../../models/user_model.dart';
import '../../models/student_report_model.dart';

/// Pantalla para ver el desempeño de los estudiantes asignados al maestro
class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  late TeacherService _teacherService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _teacherService = TeacherService();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estudiantes'),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar estudiante...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Lista de estudiantes
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _searchQuery.isEmpty
                  ? _teacherService.obtenerMisEstudiantes()
                  : _teacherService.buscarMisEstudiantes(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final estudiantes = snapshot.data ?? [];

                if (estudiantes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No tienes estudiantes asignados'
                              : 'No se encontraron resultados',
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
                  itemCount: estudiantes.length,
                  itemBuilder: (context, index) {
                    final estudiante = estudiantes[index];
                    return _buildStudentCard(estudiante);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta de estudiante
  Widget _buildStudentCard(UserModel estudiante) {
    return FutureBuilder<StudentReportModel?>(
      future: _teacherService.obtenerReporteEstudiante(estudiante.id),
      builder: (context, snapshot) {
        final reporte = snapshot.data;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              _showStudentDetails(estudiante, reporte);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              estudiante.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (reporte != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorForPercentage(reporte.promedioGeneral),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${reporte.promedioGeneral.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (reporte != null) ...[
                    const SizedBox(height: 12),
                    // Estadísticas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          '${reporte.totalAciertos}',
                          'Aciertos',
                          Colors.green,
                        ),
                        _buildStatItem(
                          '${reporte.totalIntentos}',
                          'Intentos',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          '${reporte.totalTestsRealizados}',
                          'Tests',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Nivel de desempeño
                    Text(
                      'Nivel: ${reporte.obtenerNivelDesempenio()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else
                    const SizedBox(height: 12),
                  if (reporte == null)
                    Text(
                      'Sin reportes aún',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construye un item de estadística
  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
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

  /// Mostrar detalles del estudiante
  void _showStudentDetails(UserModel estudiante, StudentReportModel? reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estudiante.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', estudiante.email),
              const SizedBox(height: 12),
              _buildDetailRow('Grado', estudiante.gradoNombre ?? 'N/A'),
              const SizedBox(height: 12),
              if (reporte != null) ...[
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
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Desempeño por Categoría:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...reporte.desempenoPorCategoria.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
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
                            color:
                                _getColorForPercentage(entry.value.porcentaje),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                const Text(
                  'Este estudiante aún no tiene reportes.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Obtiene el color según el porcentaje
  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }
}
