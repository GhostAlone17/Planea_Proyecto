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

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (widget.correct / widget.total * 100).toStringAsFixed(1);
    final porcentajeNum = double.parse(porcentaje);
    final nivel = _getNivel(porcentajeNum);
    final incorrectas = widget.total - widget.correct;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Test'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección de calificación GRANDE con animación
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
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
                      padding: const EdgeInsets.all(AppConstants.paddingLarge * 2),
                      child: Column(
                        children: [
                          Text(
                            'Test: ${widget.category.nombre}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                          const SizedBox(height: AppConstants.paddingLarge),
                          
                          // Porcentaje GIGANTE
                          Text(
                            '$porcentaje%',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 72,
                                ),
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          
                          // Nivel de logro con badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingLarge,
                              vertical: AppConstants.paddingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIconForNivel(nivel),
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  nivel,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppConstants.paddingLarge * 1.5),
                          
                          // Tarjetas de estadísticas en fila
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
                                incorrectas.toString(),
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
                  ),
                );
              },
            ),

            // Sección de análisis detallado
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Análisis Detallado',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Análisis visual
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Aciertos
                          _buildAnalysisRow(
                            'Aciertos',
                            widget.correct,
                            widget.total,
                            Colors.green,
                          ),
                          const SizedBox(height: AppConstants.paddingMedium * 1.5),
                          
                          // Errores
                          _buildAnalysisRow(
                            'Errores',
                            incorrectas,
                            widget.total,
                            Colors.red,
                          ),
                          const SizedBox(height: AppConstants.paddingMedium * 1.5),
                          
                          // Barra de progreso general
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: porcentajeNum / 100,
                              minHeight: 10,
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

            // Recomendaciones personalizadas
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              child: Card(
                color: _getRecommendationColor(nivel),
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
                            size: 28,
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: Text(
                              'Recomendación',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRecommendation(nivel),
                        style: Theme.of(context).textTheme.bodyMedium,
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
                    icon: const Icon(Icons.home_rounded, size: 22),
                    label: const Text(
                      'Volver a Categorías',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    label: const Text(
                      'Intentar de Nuevo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  Color _getRecommendationColor(String nivel) {
    switch (nivel) {
      case 'Excelente':
        return Colors.green.shade50;
      case 'Bueno':
        return Colors.blue.shade50;
      case 'Regular':
        return Colors.orange.shade50;
      case 'Necesita Mejorar':
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }
}
