import 'package:flutter/material.dart';
import '../utils/grado_utils.dart';
import 'visualizador_reportes_screen.dart';

/// Pantalla para generar reportes en PDF o Excel
/// Solo accesible por Maestro y Admin
class GenararReportesScreen extends StatefulWidget {
  final String gradoNombre;

  const GenararReportesScreen({
    Key? key,
    required this.gradoNombre,
  }) : super(key: key);

  @override
  State<GenararReportesScreen> createState() => _GenararReportesScreenState();
}

class _GenararReportesScreenState extends State<GenararReportesScreen> {
  late String _tipoReporte; // 'general', 'categoria', 'estudiante', 'todos'

  @override
  void initState() {
    super.initState();
    _tipoReporte = 'general';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Generar Reportes'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assessment,
                              size: 40,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generar Reportes',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Grado: ${GradoUtils.getNombreGrado(widget.gradoNombre)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Selección de tipo de reporte
                    Text(
                      'Tipo de Reporte',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(
                      value: 'general',
                      label: '📊 General',
                      description: 'Resumen consolidado del grado',
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(
                      value: 'categoria',
                      label: '📈 Por Categoría',
                      description: 'Desempeño de estudiantes por cada categoría',
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(
                      value: 'estudiante',
                      label: '👥 Por Estudiante',
                      description: 'Desempeño general de cada estudiante',
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(
                      value: 'todos',
                      label: '🌍 Todos los Grados',
                      description: 'Consolidado de todos los grados',
                    ),
                    const SizedBox(height: 40),

                    // Botón de generación
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generarReporte,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Ver Reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Información
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'En el siguiente paso podrás descargar el reporte en PDF o Excel',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String label,
    required String description,
  }) {
    return InkWell(
      onTap: () => setState(() => _tipoReporte = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _tipoReporte == value ? Colors.blue : Colors.grey.shade300,
            width: _tipoReporte == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _tipoReporte == value ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _tipoReporte,
              onChanged: (val) => setState(() => _tipoReporte = val ?? value),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
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

  Future<void> _generarReporte() async {
    try {
      // Navegar al visualizador de reportes
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisualizadorReportesScreen(
              tipoReporte: _tipoReporte,
              gradoNombre: _tipoReporte == 'todos' ? null : widget.gradoNombre,
              nombreInstitucion: 'PLANEA',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error generando reporte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
