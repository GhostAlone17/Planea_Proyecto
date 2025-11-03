import 'package:flutter/material.dart';
import '../../services/teacher_service.dart';
import '../../models/user_model.dart';

/// Pantalla para que el maestro gestione sus estudiantes
/// - Ver solo sus estudiantes asignados
/// - Buscar estudiantes
/// - Deshabilitar/Habilitar (sin eliminar)
/// - Ver detalles del estudiante
class TeacherEstudiantesManagementScreen extends StatefulWidget {
  const TeacherEstudiantesManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherEstudiantesManagementScreen> createState() =>
      _TeacherEstudiantesManagementScreenState();
}

class _TeacherEstudiantesManagementScreenState
    extends State<TeacherEstudiantesManagementScreen> {
  final _searchController = TextEditingController();
  late TeacherService _teacherService;
  String _filtroEstado = 'todos'; // activos, deshabilitados, todos

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

  Future<void> _deshabilitarEstudiante(UserModel estudiante) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deshabilitar Estudiante'),
        content: Text(
            '¿Deseas deshabilitar a ${estudiante.nombre}? Podrá ser habilitado nuevamente.'),
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

    final success = await _teacherService.deshabilitarEstudiante(estudiante.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ ${estudiante.nombre} deshabilitado'
              : '❌ Error deshabilitando estudiante'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _habilitarEstudiante(UserModel estudiante) async {
    final success = await _teacherService.habilitarEstudiante(estudiante.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ ${estudiante.nombre} habilitado'
              : '❌ Error habilitando estudiante'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {});
    }
  }

  void _mostrarDetalles(UserModel estudiante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Estudiante'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nombre', estudiante.nombre),
              _buildDetailRow('Email', estudiante.email),
              _buildDetailRow('Grado', estudiante.gradoId ?? 'N/A'),
              _buildDetailRow(
                'Estado',
                estudiante.activo ? '✅ Activo' : '❌ Deshabilitado',
              ),
              _buildDetailRow(
                'Registrado',
                '${estudiante.fechaRegistro.day}/${estudiante.fechaRegistro.month}/${estudiante.fechaRegistro.year}',
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
        title: const Text('Gestionar Estudiantes'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Filtro de estado
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Estado'),
                  onSelected: (_) => _mostrarFiltroEstado(),
                ),
                Chip(
                  label: Text(_getEtiquetaEstado(_filtroEstado)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de estudiantes
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _teacherService.obtenerMisEstudiantes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  List<UserModel> estudiantes = snapshot.data ?? [];

                  // Filtrar por búsqueda
                  final query = _searchController.text.toLowerCase();
                  if (query.isNotEmpty) {
                    estudiantes = estudiantes
                        .where((e) =>
                            e.nombre.toLowerCase().contains(query) ||
                            e.email.toLowerCase().contains(query))
                        .toList();
                  }

                  // Filtrar por estado
                  if (_filtroEstado == 'activos') {
                    estudiantes = estudiantes.where((e) => e.activo).toList();
                  } else if (_filtroEstado == 'deshabilitados') {
                    estudiantes =
                        estudiantes.where((e) => !e.activo).toList();
                  }

                  if (estudiantes.isEmpty) {
                    return Center(
                      child: Text(
                        query.isNotEmpty
                            ? 'No se encontraron resultados'
                            : 'No tienes estudiantes asignados',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: estudiantes.length,
                    itemBuilder: (context, index) {
                      final estudiante = estudiantes[index];
                      final isActive = estudiante.activo;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isActive ? Colors.green : Colors.grey,
                            child: Text(
                              estudiante.nombre[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(estudiante.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                estudiante.email,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Grado: ${estudiante.gradoId ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'ver') {
                                _mostrarDetalles(estudiante);
                              } else if (value == 'deshabilitar') {
                                _deshabilitarEstudiante(estudiante);
                              } else if (value == 'habilitar') {
                                _habilitarEstudiante(estudiante);
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
                              if (isActive)
                                const PopupMenuItem<String>(
                                  value: 'deshabilitar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block, size: 18, color: Colors.red),
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

  void _mostrarFiltroEstado() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filtrar por Estado'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroEstado = 'activos');
              Navigator.pop(context);
            },
            child: const Text('✅ Activos'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroEstado = 'deshabilitados');
              Navigator.pop(context);
            },
            child: const Text('❌ Deshabilitados'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroEstado = 'todos');
              Navigator.pop(context);
            },
            child: const Text('📋 Todos'),
          ),
        ],
      ),
    );
  }

  String _getEtiquetaEstado(String valor) {
    switch (valor) {
      case 'activos':
        return '✅ Activos';
      case 'deshabilitados':
        return '❌ Deshabilitados';
      case 'todos':
        return '📋 Todos';
      default:
        return 'Estado';
    }
  }
}
