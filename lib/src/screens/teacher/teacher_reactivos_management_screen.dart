import 'package:flutter/material.dart';
import '../../services/teacher_service.dart';
import '../../models/reactive_model.dart';

/// Pantalla para que el maestro gestione sus reactivos/preguntas
/// - Ver solo sus reactivos creados
/// - Buscar reactivos
/// - Ver detalles
/// - Deshabilitar/Habilitar (sin eliminar)
class TeacherReactivosManagementScreen extends StatefulWidget {
  const TeacherReactivosManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherReactivosManagementScreen> createState() =>
      _TeacherReactivosManagementScreenState();
}

class _TeacherReactivosManagementScreenState
    extends State<TeacherReactivosManagementScreen> {
  final _searchController = TextEditingController();
  late TeacherService _teacherService;
  String _filtroDificultad = 'todos'; // facil, medio, dificil, todos

  @override
  void initState() {
    super.initState();
    _teacherService = TeacherService();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getDificultadColor(int dificultad) {
    if (dificultad <= 2) {
      return Colors.green;
    } else if (dificultad == 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getDificultadLabel(int dificultad) {
    if (dificultad <= 2) {
      return 'Fácil';
    } else if (dificultad == 3) {
      return 'Medio';
    } else {
      return 'Difícil';
    }
  }

  Future<void> _deshabilitarReactivo(ReactiveModel reactivo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deshabilitar Reactivo'),
        content: const Text(
            '¿Deseas deshabilitar esta pregunta? Podrá ser habilitada nuevamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deshabilitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _teacherService.deshabilitarReactivo(reactivo.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Reactivo deshabilitado'
              : '❌ Error deshabilitando reactivo'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _habilitarReactivo(ReactiveModel reactivo) async {
    final success = await _teacherService.habilitarReactivo(reactivo.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Reactivo habilitado'
              : '❌ Error habilitando reactivo'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {});
    }
  }

  void _mostrarDetalles(ReactiveModel reactivo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Reactivo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Pregunta', reactivo.pregunta),
              const SizedBox(height: 16),
              const Text(
                'Opciones:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...List.generate(reactivo.opciones.length, (index) {
                final isCorrect = index == reactivo.respuestaCorrecta;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.grey,
                        width: isCorrect ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: isCorrect
                          ? Colors.green.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + index)}.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reactivo.opciones[index])),
                        if (isCorrect)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Dificultad',
                _getDificultadLabel(reactivo.dificultad),
              ),
              if (reactivo.explicacion != null && reactivo.explicacion!.isNotEmpty)
                _buildDetailRow('Explicación', reactivo.explicacion!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reactivos'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear reactivo - Próximamente')),
          );
        },
        tooltip: 'Crear Reactivo',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar preguntas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Filtro de dificultad
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Dificultad'),
                  onSelected: (_) => _mostrarFiltroDificultad(),
                ),
                Chip(
                  label: Text(_getEtiquetaDificultad(_filtroDificultad)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de reactivos
            Expanded(
              child: FutureBuilder<List<ReactiveModel>>(
                future: _teacherService.obtenerMisReactivos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  List<ReactiveModel> reactivos = snapshot.data ?? [];

                  // Filtrar por búsqueda
                  final query = _searchController.text.toLowerCase();
                  if (query.isNotEmpty) {
                    reactivos = reactivos
                        .where((r) =>
                            r.pregunta.toLowerCase().contains(query))
                        .toList();
                  }

                  // Filtrar por dificultad
                  if (_filtroDificultad == 'facil') {
                    reactivos =
                        reactivos.where((r) => r.dificultad <= 2).toList();
                  } else if (_filtroDificultad == 'medio') {
                    reactivos =
                        reactivos.where((r) => r.dificultad == 3).toList();
                  } else if (_filtroDificultad == 'dificil') {
                    reactivos =
                        reactivos.where((r) => r.dificultad > 3).toList();
                  }

                  if (reactivos.isEmpty) {
                    return Center(
                      child: Text(
                        query.isNotEmpty
                            ? 'No se encontraron resultados'
                            : 'No tienes reactivos creados',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: reactivos.length,
                    itemBuilder: (context, index) {
                      final reactivo = reactivos[index];
                      final isActive = reactivo.activa;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getDificultadColor(reactivo.dificultad),
                            child: Text(
                              '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            reactivo.pregunta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getDificultadColor(reactivo.dificultad),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getDificultadLabel(reactivo.dificultad),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${reactivo.opciones.length} opciones',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isActive)
                                    const Text(
                                      '❌ Deshabilitado',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'ver') {
                                _mostrarDetalles(reactivo);
                              } else if (value == 'editar') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Editar - Próximamente'),
                                  ),
                                );
                              } else if (value == 'deshabilitar') {
                                _deshabilitarReactivo(reactivo);
                              } else if (value == 'habilitar') {
                                _habilitarReactivo(reactivo);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'ver',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18),
                                    SizedBox(width: 12),
                                    Text('Ver Detalles'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 12),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              if (isActive)
                                const PopupMenuItem<String>(
                                  value: 'deshabilitar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text('Deshabilitar',
                                          style:
                                              TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                )
                              else
                                const PopupMenuItem<String>(
                                  value: 'habilitar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 18, color: Colors.green),
                                      SizedBox(width: 12),
                                      Text('Habilitar',
                                          style: TextStyle(
                                              color: Colors.green)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroDificultad() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filtrar por Dificultad'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroDificultad = 'facil');
              Navigator.pop(context);
            },
            child: const Text('🟢 Fácil'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroDificultad = 'medio');
              Navigator.pop(context);
            },
            child: const Text('🟠 Medio'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroDificultad = 'dificil');
              Navigator.pop(context);
            },
            child: const Text('🔴 Difícil'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroDificultad = 'todos');
              Navigator.pop(context);
            },
            child: const Text('📋 Todos'),
          ),
        ],
      ),
    );
  }

  String _getEtiquetaDificultad(String valor) {
    switch (valor) {
      case 'facil':
        return '🟢 Fácil';
      case 'medio':
        return '🟠 Medio';
      case 'dificil':
        return '🔴 Difícil';
      case 'todos':
        return '📋 Todos';
      default:
        return 'Dificultad';
    }
  }
}
