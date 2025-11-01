import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import '../services/reports_service.dart';
import '../utils/grado_utils.dart';

/// Pantalla visualizadora de reportes generados
/// Permite previsualizaración, descarga y compartición
class VisualizadorReportesScreen extends StatefulWidget {
  final String tipoReporte; // 'general', 'categoria', 'estudiante', 'todos'
  final String? gradoNombre; // null para 'todos'
  final String nombreInstitucion;

  const VisualizadorReportesScreen({
    Key? key,
    required this.tipoReporte,
    this.gradoNombre,
    this.nombreInstitucion = 'PLANEA',
  }) : super(key: key);

  @override
  State<VisualizadorReportesScreen> createState() => _VisualizadorReportesScreenState();
}

class _VisualizadorReportesScreenState extends State<VisualizadorReportesScreen> {
  final _reportsService = ReportsService();

  late Map<String, dynamic> _reporteData;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosReporte();
  }

  Future<void> _cargarDatosReporte() async {
    try {
      late Map<String, dynamic> datos;

      if (widget.tipoReporte == 'general' && widget.gradoNombre != null) {
        datos = await _reportsService.obtenerReporteGeneral(
          gradoNombre: widget.gradoNombre!,
        );
      } else if (widget.tipoReporte == 'categoria' && widget.gradoNombre != null) {
        datos = await _reportsService.obtenerDesempenoPorCategoria(
          gradoNombre: widget.gradoNombre!,
        );
      } else if (widget.tipoReporte == 'estudiante' && widget.gradoNombre != null) {
        final estudiantes = await _reportsService.obtenerEstudiantesPorGrado(
          gradoNombre: widget.gradoNombre!,
        );
        datos = {'estudiantes': estudiantes};
      } else if (widget.tipoReporte == 'todos') {
        datos = await _reportsService.obtenerReporteTodosGrados();
      }

      setState(() {
        _reporteData = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTituloReporte()),
        elevation: 0,
        actions: [
          if (!_cargando && _error == null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    onPressed: () => _descargarPDF(),
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.table_chart,
                    label: 'Excel',
                    onPressed: () => _descargarExcel(),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Compartir',
                    onPressed: () => _mostrarDialogoCompartir(),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildContenidoReporte(),
                  ),
                ),
    );
  }

  Widget _buildContenidoReporte() {
    if (widget.tipoReporte == 'general' && widget.gradoNombre != null) {
      return _buildReporteGeneral();
    } else if (widget.tipoReporte == 'categoria' && widget.gradoNombre != null) {
      return _buildReporteCategoria();
    } else if (widget.tipoReporte == 'estudiante' && widget.gradoNombre != null) {
      return _buildReporteEstudiante();
    } else if (widget.tipoReporte == 'todos') {
      return _buildReporteTodos();
    }
    return const SizedBox();
  }

  Widget _buildReporteGeneral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 24),
        _buildTitulo('Resumen General'),
        const SizedBox(height: 12),
        _buildMetricaListItem(
          icon: Icons.people,
          label: 'Total de Estudiantes',
          valor: _reporteData['totalEstudiantes'].toString(),
          color: Colors.blue,
        ),
        _buildMetricaListItem(
          icon: Icons.assessment,
          label: 'Tests Realizados',
          valor: _reporteData['totalTests'].toString(),
          color: Colors.orange,
        ),
        _buildMetricaListItem(
          icon: Icons.check_circle,
          label: 'Total Aciertos',
          valor: _reporteData['totalAciertos'].toString(),
          color: Colors.green,
        ),
        _buildMetricaListItem(
          icon: Icons.help,
          label: 'Total Intentos',
          valor: _reporteData['totalIntentos'].toString(),
          color: Colors.purple,
        ),
        _buildMetricaListItem(
          icon: Icons.trending_up,
          label: 'Promedio General',
          valor: '${(_reporteData['promedioGeneral'] as double).toStringAsFixed(2)}%',
          color: Colors.red,
          isPromedio: true,
        ),
      ],
    );
  }

  Widget _buildReporteCategoria() {
    final categorias = _reporteData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 24),
        _buildTitulo('Desempeño por Categoría'),
        const SizedBox(height: 12),
        ...categorias.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          return _buildCategoriaCard(
            nombre: entry.key,
            aciertos: data['totalAciertos'] as int,
            intentos: data['totalIntentos'] as int,
            porcentaje: data['porcentajeGeneral'] as double,
            estudiantes: data['totalEstudiantes'] as int,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReporteEstudiante() {
    final estudiantes = (_reporteData['estudiantes'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 24),
        _buildTitulo('Desempeño de Estudiantes'),
        const SizedBox(height: 12),
        if (estudiantes.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No hay estudiantes registrados'),
            ),
          )
        else
          ...estudiantes.map((est) {
            return _buildEstudianteCard(
              nombre: est['nombre'] ?? 'Desconocido',
              email: est['email'] ?? '',
              testsRealizados: est['totalTests'] ?? 0,
              aciertos: est['totalAciertos'] ?? 0,
              totalPreguntas: est['totalPreguntas'] ?? 0,
              promedio: est['promedio'] ?? 0.0,
            );
          }).toList(),
      ],
    );
  }

  Widget _buildReporteTodos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 24),
        _buildTitulo('Resumen Global'),
        const SizedBox(height: 12),
        _buildMetricaListItem(
          icon: Icons.people,
          label: 'Total de Estudiantes',
          valor: _reporteData['totalEstudiantes'].toString(),
          color: Colors.blue,
        ),
        _buildMetricaListItem(
          icon: Icons.assessment,
          label: 'Tests Realizados',
          valor: _reporteData['totalTests'].toString(),
          color: Colors.orange,
        ),
        _buildMetricaListItem(
          icon: Icons.trending_up,
          label: 'Promedio Global',
          valor: '${(_reporteData['promedioGeneral'] as double).toStringAsFixed(2)}%',
          color: Colors.red,
          isPromedio: true,
        ),
        const SizedBox(height: 24),
        _buildTitulo('Por Grado'),
        const SizedBox(height: 12),
        ...(_reporteData['reportesPorGrado'] as Map<String, Map<String, dynamic>>)
            .entries
            .map((entry) {
          final data = entry.value;
          return _buildGradoCard(
            grado: entry.key,
            estudiantes: data['totalEstudiantes'] as int,
            tests: data['totalTests'] as int,
            promedio: data['promedioGeneral'] as double,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMetricaListItem({
    required IconData icon,
    required String label,
    required String valor,
    required Color color,
    bool isPromedio = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPromedio ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPromedio ? color : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.assessment, color: Colors.blue.shade600, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTituloReporte(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.gradoNombre != null)
                        Text(
                          'Grado: ${GradoUtils.getNombreGrado(widget.gradoNombre)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      Text(
                        'Generado: ${DateTime.now().toLocal().toString().split('.')[0]}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaCard({
    required String nombre,
    required int aciertos,
    required int intentos,
    required double porcentaje,
    required int estudiantes,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getColorPorcentaje(porcentaje),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${porcentaje.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricaItem('Aciertos', aciertos.toString()),
                _buildMetricaItem('Intentos', intentos.toString()),
                _buildMetricaItem('Estudiantes', estudiantes.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstudianteCard({
    required String nombre,
    required String email,
    required int testsRealizados,
    required int aciertos,
    required int totalPreguntas,
    required double promedio,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.purple.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricaItem('Tests', testsRealizados.toString()),
                _buildMetricaItem('Aciertos', aciertos.toString()),
                _buildMetricaItem('Total Preguntas', totalPreguntas.toString()),
                _buildMetricaItem('Promedio', '${promedio.toStringAsFixed(2)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradoCard({
    required String grado,
    required int estudiantes,
    required int tests,
    required double promedio,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  GradoUtils.getEmojiGrado(grado),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grado,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$estudiantes estudiantes • $tests tests',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getColorPorcentaje(promedio),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${promedio.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaItem(String label, String valor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTitulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTituloReporte() {
    if (widget.tipoReporte == 'general') {
      return '📊 Reporte General';
    } else if (widget.tipoReporte == 'categoria') {
      return '📈 Reporte por Categoría';
    } else if (widget.tipoReporte == 'estudiante') {
      return '👥 Reporte por Estudiante';
    } else if (widget.tipoReporte == 'todos') {
      return '🌍 Reporte Consolidado';
    }
    return 'Reporte';
  }

  Color _getColorPorcentaje(double porcentaje) {
    if (porcentaje >= 80) return Colors.green;
    if (porcentaje >= 60) return Colors.amber.shade700;
    return Colors.red;
  }

  Future<void> _descargarPDF() async {
    try {
      _mostrarDialogoDescargando();

      late Uint8List bytes;

      if (widget.tipoReporte == 'general' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarPdfReporteGeneral(
          gradoNombre: widget.gradoNombre!,
          nombreInstitucion: widget.nombreInstitucion,
        );
      } else if (widget.tipoReporte == 'categoria' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarPdfPorCategoria(
          gradoNombre: widget.gradoNombre!,
          nombreInstitucion: widget.nombreInstitucion,
        );
      } else if (widget.tipoReporte == 'estudiante' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarPdfPorEstudiante(
          gradoNombre: widget.gradoNombre!,
          nombreInstitucion: widget.nombreInstitucion,
        );
      } else if (widget.tipoReporte == 'todos') {
        bytes = await _reportsService.generarPdfTodosGrados(
          nombreInstitucion: widget.nombreInstitucion,
        );
      }

      Navigator.pop(context); // Cerrar diálogo de descarga

      final timestamp = DateTime.now().toString().split('.')[0].replaceAll(':', '-');
      final nombreArchivo = 'Reporte_${widget.tipoReporte}_$timestamp.pdf';

      _reportsService.descargarArchivo(bytes: bytes, nombreArchivo: nombreArchivo);

      _mostrarSnackbar('✓ PDF descargado: $nombreArchivo', Colors.green);
    } catch (e) {
      Navigator.pop(context); // Cerrar diálogo de descarga
      _mostrarSnackbar('Error al descargar PDF: $e', Colors.red);
    }
  }

  Future<void> _descargarExcel() async {
    try {
      _mostrarDialogoDescargando();

      // Obtener datos del usuario actual
      final user = FirebaseAuth.instance.currentUser;
      String? usuarioNombre;
      String? usuarioRol;

      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
          if (doc.exists) {
            usuarioNombre = doc.data()?['nombre'] ?? user.displayName ?? 'Usuario';
            usuarioRol = doc.data()?['rol'] ?? 'Administrador';
          }
        } catch (e) {
          usuarioNombre = user.displayName ?? user.email;
          usuarioRol = 'Administrador';
        }
      }

      late Uint8List bytes;

      if (widget.tipoReporte == 'general' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarExcelReporteGeneral(
          gradoNombre: widget.gradoNombre!,
          usuarioNombre: usuarioNombre,
          usuarioRol: usuarioRol,
        );
      } else if (widget.tipoReporte == 'categoria' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarExcelPorCategoria(
          gradoNombre: widget.gradoNombre!,
          usuarioNombre: usuarioNombre,
          usuarioRol: usuarioRol,
        );
      } else if (widget.tipoReporte == 'estudiante' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarExcelPorEstudiante(
          gradoNombre: widget.gradoNombre!,
          usuarioNombre: usuarioNombre,
          usuarioRol: usuarioRol,
        );
      } else if (widget.tipoReporte == 'todos') {
        bytes = await _reportsService.generarExcelTodosGrados(
          usuarioNombre: usuarioNombre,
          usuarioRol: usuarioRol,
        );
      }

      Navigator.pop(context); // Cerrar diálogo de descarga

      final timestamp = DateTime.now().toString().split('.')[0].replaceAll(':', '-');
      final nombreArchivo = 'Reporte_${widget.tipoReporte}_$timestamp.xlsx';

      _reportsService.descargarArchivo(bytes: bytes, nombreArchivo: nombreArchivo);

      _mostrarSnackbar('✓ Excel descargado: $nombreArchivo', Colors.green);
    } catch (e) {
      Navigator.pop(context); // Cerrar diálogo de descarga
      _mostrarSnackbar('Error al descargar Excel: $e', Colors.red);
    }
  }

  void _mostrarDialogoCompartir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona cómo deseas compartir el reporte:'),
            const SizedBox(height: 24),
            _buildBotonCompartir(
              icon: Icons.picture_as_pdf,
              label: 'Compartir como PDF',
              onPressed: () {
                Navigator.pop(context);
                _compartirPDF();
              },
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildBotonCompartir(
              icon: Icons.table_chart,
              label: 'Compartir como Excel',
              onPressed: () {
                Navigator.pop(context);
                _compartirExcel();
              },
              color: Colors.green,
            ),
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

  Widget _buildBotonCompartir({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _compartirPDF() async {
    try {
      _mostrarDialogoDescargando();

      late Uint8List bytes;

      if (widget.tipoReporte == 'general' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarPdfReporteGeneral(
          gradoNombre: widget.gradoNombre!,
          nombreInstitucion: widget.nombreInstitucion,
        );
      } else if (widget.tipoReporte == 'categoria' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarPdfPorCategoria(
          gradoNombre: widget.gradoNombre!,
          nombreInstitucion: widget.nombreInstitucion,
        );
      } else if (widget.tipoReporte == 'estudiante' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarPdfPorEstudiante(
          gradoNombre: widget.gradoNombre!,
          nombreInstitucion: widget.nombreInstitucion,
        );
      } else if (widget.tipoReporte == 'todos') {
        bytes = await _reportsService.generarPdfTodosGrados(
          nombreInstitucion: widget.nombreInstitucion,
        );
      }

      Navigator.pop(context); // Cerrar diálogo de descarga

      // Crear un blob y simulación de compartir
      final blob = html.Blob([bytes]);

      // Crear elemento con data URL para compartir
      final dataUrl = await _convertBlobToDataUrl(blob);

      html.window.open(dataUrl, '_blank');

      _mostrarSnackbar('✓ Abriendo PDF en nueva ventana...', Colors.blue);
    } catch (e) {
      Navigator.pop(context);
      _mostrarSnackbar('Error al compartir PDF: $e', Colors.red);
    }
  }

  Future<void> _compartirExcel() async {
    try {
      _mostrarDialogoDescargando();

      late Uint8List bytes;

      if (widget.tipoReporte == 'general' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarExcelReporteGeneral(
          gradoNombre: widget.gradoNombre!,
        );
      } else if (widget.tipoReporte == 'categoria' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarExcelPorCategoria(
          gradoNombre: widget.gradoNombre!,
        );
      } else if (widget.tipoReporte == 'estudiante' && widget.gradoNombre != null) {
        bytes = await _reportsService.generarExcelPorEstudiante(
          gradoNombre: widget.gradoNombre!,
        );
      } else if (widget.tipoReporte == 'todos') {
        bytes = await _reportsService.generarExcelTodosGrados();
      }

      Navigator.pop(context);

      final blob = html.Blob([bytes]);
      html.Url.createObjectUrlFromBlob(blob);

      _mostrarSnackbar('✓ Excel disponible para compartir', Colors.green);
    } catch (e) {
      Navigator.pop(context);
      _mostrarSnackbar('Error al compartir Excel: $e', Colors.red);
    }
  }

  Future<String> _convertBlobToDataUrl(html.Blob blob) async {
    return 'data:application/pdf;base64,${_uint8ListToBase64(await _blobToUint8List(blob))}';
  }

  Future<Uint8List> _blobToUint8List(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    return Uint8List.fromList(List<int>.from(reader.result as List));
  }

  String _uint8ListToBase64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    int b;
    StringBuffer sb = StringBuffer();

    for (int i = 0; i < bytes.length; i += 3) {
      b = (bytes[i] & 0xFC) >> 2;
      sb.write(chars[b]);
      b = (bytes[i] & 0x03) << 4;
      if (i + 1 < bytes.length) {
        b |= (bytes[i + 1] & 0xF0) >> 4;
        sb.write(chars[b]);
        b = (bytes[i + 1] & 0x0F) << 2;
        if (i + 2 < bytes.length) {
          b |= (bytes[i + 2] & 0xC0) >> 6;
          sb.write(chars[b]);
          b = bytes[i + 2] & 0x3F;
          sb.write(chars[b]);
        } else {
          sb.write(chars[b]);
          sb.write('=');
        }
      } else {
        sb.write(chars[b]);
        sb.write('==');
      }
    }

    return sb.toString();
  }

  void _mostrarDialogoDescargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Text('Generando reporte...'),
          ],
        ),
      ),
    );
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
