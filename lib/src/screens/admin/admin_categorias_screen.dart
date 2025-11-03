import 'package:flutter/material.dart';
import '../../models/category_model_v2.dart';
import '../../services/admin_service.dart';

/// Pantalla para gestionar categorías de reactivos
class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  List<CategoryModelV2> _categorias = [];
  late AdminService _adminService;
  Map<String, int> _reactivosPorCategoria = {};
  Map<String, Map<String, dynamic>> _estadisticasPorCategoria = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar categorías desde Firestore
      final categoriasSnapshot = await _adminService.obtenerCategorias();
      
      // Si no hay categorías en Firestore, usar las default
      if (categoriasSnapshot.isEmpty) {
        _categorias = CategoryModelV2.categoriasDefault();
      } else {
        _categorias = categoriasSnapshot;
      }

      // Cargar estadísticas de reactivos
      final stats = await _adminService.obtenerReactivosPorCategoria();
      
      // OPTIMIZACIÓN: Cargar datos una sola vez y reutilizarlos
      final reportes = await _adminService.obtenerTodosLosReportes();
      final reactivos = await _adminService.obtenerReactivos();
      
      // Calcular estadísticas para todas las categorías
      for (var categoria in _categorias) {
        _estadisticasPorCategoria[categoria.id] = _calcularEstadisticasCategoria(
          categoria.id,
          reportes,
          reactivos,
        );
      }

      setState(() {
        _reactivosPorCategoria = stats;
        _cargando = false;
      });
    } catch (e) {
      print('Error cargando datos de categorías: $e');
      // Si hay error, usar categorías default
      setState(() {
        _categorias = CategoryModelV2.categoriasDefault();
        _cargando = false;
      });
    }
  }

  Map<String, dynamic> _calcularEstadisticasCategoria(
    String categoriaId,
    List reportes,
    List reactivos,
  ) {
    try {
      // Calcular estadísticas de esta categoría desde los reportes
      int totalAciertos = 0;
      int totalIntentos = 0;
      int estudiantesConTests = 0;

      for (var reporte in reportes) {
        if (reporte.desempenoPorCategoria.containsKey(categoriaId)) {
          final perf = reporte.desempenoPorCategoria[categoriaId]!;
          totalAciertos += (perf.aciertos as num).toInt();
          totalIntentos += (perf.intentos as num).toInt();
          // Contar cuántos estudiantes han realizado tests en esta categoría
          if (perf.intentos > 0) {
            estudiantesConTests++;
          }
        }
      }

      // Calcular porcentaje de acierto promedio
      final aciertoPromedio = totalIntentos > 0
          ? (totalAciertos / totalIntentos * 100)
          : 0.0;

      // Obtener dificultad promedio de los reactivos de esta categoría
      final reactivosCategoria = reactivos.where((r) => r.categoryId == categoriaId && r.activa).toList();
      
      final dificultadPromedio = reactivosCategoria.isNotEmpty
          ? reactivosCategoria.map((r) => r.dificultad).reduce((a, b) => a + b) / reactivosCategoria.length
          : 0.0;

      return {
        'testsRealizados': estudiantesConTests,
        'totalIntentos': totalIntentos,
        'aciertoPromedio': aciertoPromedio,
        'dificultadPromedio': dificultadPromedio,
      };
    } catch (e) {
      print('Error calculando estadísticas de categoría: $e');
      return {
        'testsRealizados': 0,
        'totalIntentos': 0,
        'aciertoPromedio': 0.0,
        'dificultadPromedio': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Categorías',
              style: TextStyle(fontSize: isMobile ? 16 : 18),
            ),
            Text(
              'PLANEA - Matemáticas',
              style: TextStyle(
                fontSize: isMobile ? 9 : 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bienvenida
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📚 Categorías PLANEA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${_categorias.length} categorías disponibles',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sección de categorías
                  Text(
                    'Temas de Evaluación',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Grid/Lista de categorías
                  _buildCategoriesGrid(),
                  const SizedBox(height: 32),

                  // Información
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Las categorías están predefinidas y cada una contiene reactivos específicos.',
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
    );
  }

  /// Construye la lista de categorías en formato vertical
  Widget _buildCategoriesGrid() {
    return Column(
      children: _categorias.map((categoria) {
        final numReactivos = _reactivosPorCategoria[categoria.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCategoryCard(categoria, numReactivos),
        );
      }).toList(),
    );
  }

  /// Construye una tarjeta de categoría (lista horizontal)
  Widget _buildCategoryCard(CategoryModelV2 categoria, int numReactivos) {
    // Obtener icono y color según la categoría
    final iconData = _getCategoryIcon(categoria.nombre);
    final iconBgColor = _getCategoryIconBackground(categoria.nombre);
    final iconColor = _getCategoryIconColor(categoria.nombre);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDetallesCategoria(categoria, numReactivos),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono en contenedor
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Contenido expandible
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      categoria.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Descripción
                    Text(
                      categoria.descripcion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Badge de reactivos + flecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: numReactivos > 0
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$numReactivos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: numReactivos > 0
                            ? Colors.orange.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.purple,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  /// Obtener color de fondo del icono según la categoría
  Color _getCategoryIconBackground(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'estadística':
      case 'estadistica':
        return Colors.orange.shade100;
      case 'geometría':
      case 'geometria':
        return Colors.purple.shade100;
      case 'álgebra':
      case 'algebra':
        return Colors.blue.shade100;
      case 'trigonometría':
      case 'trigonometria':
        return Colors.pink.shade100;
      case 'cálculo':
      case 'calculo':
        return Colors.green.shade100;
      case 'lógica matemática':
      case 'logica matematica':
      case 'lógica':
      case 'logica':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100;
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

  void _mostrarDetallesCategoria(CategoryModelV2 categoria, int numReactivos) {
    // Obtener estadísticas de esta categoría
    final stats = _estadisticasPorCategoria[categoria.id] ?? {
      'testsRealizados': 0,
      'totalIntentos': 0,
      'aciertoPromedio': 0.0,
      'dificultadPromedio': 0.0,
    };

    final estudiantesConTests = stats['testsRealizados'] as int;
    final totalIntentos = stats['totalIntentos'] as int;
    final aciertoPromedio = stats['aciertoPromedio'] as double;
    final dificultadPromedio = stats['dificultadPromedio'] as double;

    // Convertir dificultad a texto
    String dificultadTexto;
    if (dificultadPromedio >= 7) {
      dificultadTexto = 'Difícil';
    } else if (dificultadPromedio >= 4) {
      dificultadTexto = 'Media';
    } else if (dificultadPromedio > 0) {
      dificultadTexto = 'Fácil';
    } else {
      dificultadTexto = 'N/A';
    }

    // Obtener icono y colores de la categoría
    final iconData = _getCategoryIcon(categoria.nombre);
    final iconBgColor = _getCategoryIconBackground(categoria.nombre);
    final iconColor = _getCategoryIconColor(categoria.nombre);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(categoria.nombre),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(categoria.descripcion),
              const SizedBox(height: 16),
              const Text(
                'ID:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                categoria.id,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estadísticas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Reactivos:', numReactivos.toString()),
                    _buildStatRow('Estudiantes:', '$estudiantesConTests ${estudiantesConTests == 1 ? "ha practicado" : "han practicado"}'),
                    _buildStatRow('Total intentos:', totalIntentos.toString()),
                    _buildStatRow('Acierto promedio:', '${aciertoPromedio.toStringAsFixed(1)}%'),
                    _buildStatRow('Dificultad promedio:', dificultadTexto),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Los porcentajes se calculan sobre todos los intentos realizados',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
