import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../config/app_constants.dart';

/// Pantalla mejorada de búsqueda y validación de estudiantes
class AdminEstudiantesBusquedaAvanzada extends StatefulWidget {
  const AdminEstudiantesBusquedaAvanzada({Key? key}) : super(key: key);

  @override
  State<AdminEstudiantesBusquedaAvanzada> createState() =>
      _AdminEstudiantesBusquedaAvanzadaState();
}

class _AdminEstudiantesBusquedaAvanzadaState
    extends State<AdminEstudiantesBusquedaAvanzada> {
  final _searchController = TextEditingController();
  late AdminService _adminService;

  String _filtroGrado = 'Todos';
  String _ordenarPor = 'nombre'; // nombre, fecha, estado
  bool _mostrarSoloActivos = true;

  final List<String> _grados = ['Todos', '3', '4', '5', '6'];

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
  }

  List<UserModel> _aplicarFiltros(List<UserModel> estudiantes) {
    var filtrados = estudiantes;

    // Filtro de búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtrados = filtrados
          .where((e) =>
              e.nombre.toLowerCase().contains(query) ||
              e.email.toLowerCase().contains(query))
          .toList();
    }

    // Filtro de grado
    if (_filtroGrado != 'Todos') {
      filtrados = filtrados.where((e) => e.gradoId == _filtroGrado).toList();
    }

    // Filtro de estado
    if (_mostrarSoloActivos) {
      filtrados = filtrados.where((e) => e.activo).toList();
    }

    // Ordenamiento
    switch (_ordenarPor) {
      case 'nombre':
        filtrados.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case 'fecha':
        filtrados.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
        break;
      case 'estado':
        filtrados.sort((a, b) => b.activo ? 1 : -1);
        break;
    }

    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Busqueda Avanzada de Estudiantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Filtros - Responsive (Wrap para flujo automático)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Filtro de grado
                FilterChip(
                  label: const Text('📚 Grado'),
                  onSelected: (_) {
                    _mostrarFiltroGrado();
                  },
                ),

                // Mostrar grado seleccionado
                if (_filtroGrado != 'Todos')
                  Chip(
                    label: Text('Grado: $_filtroGrado'),
                    onDeleted: () => setState(() => _filtroGrado = 'Todos'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),

                // Filtro de ordenamiento
                FilterChip(
                  label: const Text('↕️ Ordenar'),
                  onSelected: (_) {
                    _mostrarFiltroOrdenamiento();
                  },
                ),

                // Mostrar ordenamiento seleccionado
                Chip(
                  label: Text(_getEtiquetaOrdenamiento(_ordenarPor)),
                ),

                // Filtro de estado
                FilterChip(
                  label: const Text('✅ Solo Activos'),
                  selected: _mostrarSoloActivos,
                  onSelected: (value) {
                    setState(() => _mostrarSoloActivos = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de estudiantes
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _adminService.streamEstudiantes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final estudiantes = _aplicarFiltros(snapshot.data ?? []);

                  if (estudiantes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.people, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay estudiantes que coincidan con los filtros'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: estudiantes.length,
                    itemBuilder: (context, index) {
                      final estudiante = estudiantes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(estudiante.nombre[0].toUpperCase()),
                          ),
                          title: Text(estudiante.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(estudiante.email),
                              Text(
                                'Grado: ${estudiante.gradoId ?? 'N/A'} | '
                                'Registrado: ${_formatoFecha(estudiante.fechaRegistro)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(estudiante.activo ? 'Activo' : 'Inactivo'),
                            backgroundColor: estudiante.activo
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                          ),
                          onTap: () {
                            _mostrarDetallesEstudiante(estudiante);
                          },
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

  void _mostrarFiltroGrado() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar Grado'),
        children: _grados.map((grado) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroGrado = grado);
              Navigator.pop(context);
            },
            child: Text(grado),
          );
        }).toList(),
      ),
    );
  }

  void _mostrarFiltroOrdenamiento() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ordenar por'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _ordenarPor = 'nombre');
              Navigator.pop(context);
            },
            child: const Text('Nombre (A-Z)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _ordenarPor = 'fecha');
              Navigator.pop(context);
            },
            child: const Text('Mas reciente primero'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _ordenarPor = 'estado');
              Navigator.pop(context);
            },
            child: const Text('Estado'),
          ),
        ],
      ),
    );
  }

  String _getEtiquetaOrdenamiento(String valor) {
    switch (valor) {
      case 'nombre':
        return 'Por: Nombre';
      case 'fecha':
        return 'Por: Fecha';
      case 'estado':
        return 'Por: Estado';
      default:
        return 'Ordenar';
    }
  }

  String _formatoFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _mostrarDetallesEstudiante(UserModel estudiante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estudiante.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalle('Email:', estudiante.email),
              _buildDetalle('Grado:', estudiante.gradoId ?? 'N/A'),
              _buildDetalle('Tipo:', AppConstants.traducirTipoUsuario(estudiante.tipoUsuario)),
              _buildDetalle('Estado:', estudiante.activo ? 'Activo' : 'Inactivo'),
              _buildDetalle(
                'Registrado:',
                _formatoFecha(estudiante.fechaRegistro),
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

  Widget _buildDetalle(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(valor),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
