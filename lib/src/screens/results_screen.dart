import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../models/category_model.dart';

/// Pantalla de resultados del test
/// Muestra:
/// - Calificación en porcentaje
/// - Nivel de logro
/// - Desempeño por categoría
class ResultsScreen extends StatefulWidget {
  final CategoryModel category;
  final int total;
  final int correct;
  const ResultsScreen({
    super.key,
    required this.category,
    required this.total,
    required this.correct,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {

  @override
  Widget build(BuildContext context) {
    final porcentaje = (widget.correct / widget.total * 100).toStringAsFixed(1);
    final porcentajeNum = double.parse(porcentaje);
    final nivel = _getNivel(porcentajeNum);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección de calificación
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColorForNivel(nivel),
                    _getColorForNivel(nivel).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  Text(
                    'Test: ${widget.category.nombre}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  // Calificación grande
                  Text(
                    '$porcentaje%',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  // Nivel de logro
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      nivel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  // Detalles de aciertos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDetailCard(
                        'Correctas',
                        widget.correct.toString(),
                        Colors.white,
                      ),
                      _buildDetailCard(
                        'Incorrectas',
                        (widget.total - widget.correct).toString(),
                        Colors.white,
                      ),
                      _buildDetailCard(
                        'Total',
                        widget.total.toString(),
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sección de desempeño general
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Análisis de Desempeño',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnalysisRow(
                            'Aciertos',
                            widget.correct,
                            widget.total,
                            Colors.green,
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          _buildAnalysisRow(
                            'Errores',
                            widget.total - widget.correct,
                            widget.total,
                            Colors.red,
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: porcentajeNum / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                _getColorForPercentage(porcentajeNum),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Recomendaciones
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getIconForNivel(nivel),
                            color: _getColorForNivel(nivel),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: Text(
                              _getRecommendation(nivel),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home),
                    label: const Text('Volver a Categorías'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDetailCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, int value, int total, Color color) {
    final percentage = (value / total * 100).toStringAsFixed(0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('$value/$total ($percentage%)'),
          ],
        ),
      ],
    );
  }

  String _getNivel(double porcentaje) {
    if (porcentaje >= 80) return 'Excelente';
    if (porcentaje >= 60) return 'Bueno';
    if (porcentaje >= 40) return 'Regular';
    return 'Necesita Mejorar';
  }

  Color _getColorForNivel(String nivel) {
    switch (nivel) {
      case 'Excelente':
        return Colors.green;
      case 'Bueno':
        return Colors.blue;
      case 'Regular':
        return Colors.orange;
      case 'Necesita Mejorar':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForNivel(String nivel) {
    switch (nivel) {
      case 'Excelente':
        return Icons.celebration;
      case 'Bueno':
        return Icons.thumb_up;
      case 'Regular':
        return Icons.info;
      case 'Necesita Mejorar':
        return Icons.trending_down;
      default:
        return Icons.help;
    }
  }

  String _getRecommendation(String nivel) {
    switch (nivel) {
      case 'Excelente':
        return '¡Felicidades! Demostraste excelente dominio de los conceptos.';
      case 'Bueno':
        return 'Buen desempeño. Refuerza los temas en los que dudaste.';
      case 'Regular':
        return 'Es necesario mejorar. Revisa los temas y vuelve a intentarlo.';
      case 'Necesita Mejorar':
        return 'Requiere refuerzo. Estudia más sobre este tema e intenta de nuevo.';
      default:
        return 'Sigue practicando y mejorando.';
    }
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
