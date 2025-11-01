import 'package:flutter/material.dart';
import '../../models/category_model_v2.dart';

/// Diálogo de filtros avanzados para reactivos
class FiltrosAvanzadosReactivos extends StatefulWidget {
  final Function(Map<String, dynamic>) onAplicar;
  final Map<String, dynamic> filtrosActuales;

  const FiltrosAvanzadosReactivos({
    Key? key,
    required this.onAplicar,
    required this.filtrosActuales,
  }) : super(key: key);

  @override
  State<FiltrosAvanzadosReactivos> createState() =>
      _FiltrosAvanzadosReactivosState();
}

class _FiltrosAvanzadosReactivosState extends State<FiltrosAvanzadosReactivos> {
  late String _categoriaSeleccionada;
  late int _dificultadMinima;
  late int _dificultadMaxima;
  late bool _mostrarSoloActivos;
  final List<CategoryModelV2> _categorias = CategoryModelV2.categoriasDefault();

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.filtrosActuales['categoria'] ?? 'Todas';
    _dificultadMinima = widget.filtrosActuales['dificultadMin'] ?? 1;
    _dificultadMaxima = widget.filtrosActuales['dificultadMax'] ?? 3;
    _mostrarSoloActivos = widget.filtrosActuales['soloActivos'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros Avanzados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Categoría
                const Text(
                  'Categoría:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  items: [
                    const DropdownMenuItem(
                      value: 'Todas',
                      child: Text('Todas las categorías'),
                    ),
                    ..._categorias.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text('${cat.icono} ${cat.nombre}'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _categoriaSeleccionada = value ?? 'Todas');
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Dificultad
                const Text(
                  'Rango de Dificultad:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mínima:'),
                          const SizedBox(height: 8),
                          Slider(
                            value: _dificultadMinima.toDouble(),
                            min: 1,
                            max: 3,
                            divisions: 2,
                            label: _getNivelDificultad(_dificultadMinima),
                            onChanged: (value) {
                              setState(() {
                                _dificultadMinima = value.toInt();
                                if (_dificultadMinima > _dificultadMaxima) {
                                  _dificultadMaxima = _dificultadMinima;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Máxima:'),
                          const SizedBox(height: 8),
                          Slider(
                            value: _dificultadMaxima.toDouble(),
                            min: 1,
                            max: 3,
                            divisions: 2,
                            label: _getNivelDificultad(_dificultadMaxima),
                            onChanged: (value) {
                              setState(() {
                                _dificultadMaxima = value.toInt();
                                if (_dificultadMaxima < _dificultadMinima) {
                                  _dificultadMinima = _dificultadMaxima;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(_getNivelDificultad(_dificultadMinima)),
                      const Icon(Icons.arrow_forward),
                      Text(_getNivelDificultad(_dificultadMaxima)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Solo reactivos activos
                CheckboxListTile(
                  value: _mostrarSoloActivos,
                  onChanged: (value) {
                    setState(() => _mostrarSoloActivos = value ?? true);
                  },
                  title: const Text('Solo reactivos activos'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Resetear filtros
                        setState(() {
                          _categoriaSeleccionada = 'Todas';
                          _dificultadMinima = 1;
                          _dificultadMaxima = 3;
                          _mostrarSoloActivos = true;
                        });
                      },
                      child: const Text('Limpiar'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        widget.onAplicar({
                          'categoria': _categoriaSeleccionada,
                          'dificultadMin': _dificultadMinima,
                          'dificultadMax': _dificultadMaxima,
                          'soloActivos': _mostrarSoloActivos,
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNivelDificultad(int nivel) {
    // Usando constantes PLANEA para mayor claridad
    switch (nivel) {
      case 1:
        return '🟢 Fácil';
      case 2:
        return '🟡 Medio';
      case 3:
        return '🔴 Difícil';
      default:
        return 'Desconocido';
    }
  }

  // Función para futuro uso: mostrar descripción de dificultad
  // String _getDescripcionDificultad(int nivel) {
  //   switch (nivel) {
  //     case 1: return 'Conceptos básicos y ejercicios simples';
  //     case 2: return 'Requiere comprensión y análisis';
  //     case 3: return 'Requiere razonamiento avanzado';
  //     default: return '';
  //   }
  // }
}
