import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../config/app_constants.dart';

/// Pantalla para gestionar estudiantes (padrón)
/// Permite:
/// - Crear nuevos estudiantes
/// - Ver lista de estudiantes
/// - Editar estudiantes
/// - Eliminar estudiantes
class AdminEstudiantesScreen extends StatefulWidget {
  const AdminEstudiantesScreen({Key? key}) : super(key: key);

  @override
  State<AdminEstudiantesScreen> createState() => _AdminEstudiantesScreenState();
}

class _AdminEstudiantesScreenState extends State<AdminEstudiantesScreen> {
  final _searchController = TextEditingController();
  late AdminService _adminService;
  
  // Variables de filtro
  String _filtroGrado = 'Todos';
  String _ordenarPor = 'nombre'; // nombre, fecha, estado
  String _filtroEstado = 'todos'; // activos, deshabilitados, todos - CAMBIO: inicia en 'todos'
  
  final Map<String, List<Map<String, String>>> _gradosPorNivel = {
    'Primaria': [
      {'valor': '3P', 'label': '3° Primaria'},
      {'valor': '4P', 'label': '4° Primaria'},
      {'valor': '6P', 'label': '6° Primaria'},
    ],
    'Secundaria': [
      {'valor': '3S', 'label': '3° Secundaria'},
    ],
    'Preparatoria': [
      {'valor': '12EMS', 'label': '3° Preparatoria'},
    ],
  };
  
  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _searchController.addListener(_filtrarEstudiantes);
  }

  void _filtrarEstudiantes() {
    setState(() {});
  }

  /// Limpia todos los filtros a sus valores por defecto
  void _limpiarFiltros() {
    setState(() {
      _filtroGrado = 'Todos';
      _ordenarPor = 'nombre';
      _filtroEstado = 'todos';
      _searchController.clear();
    });
  }

  /// Aplica todos los filtros a la lista de estudiantes
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
    if (_filtroEstado == 'activos') {
      filtrados = filtrados.where((e) => e.activo).toList();
    } else if (_filtroEstado == 'deshabilitados') {
      filtrados = filtrados.where((e) => !e.activo).toList();
    }
    // Si es 'todos', no filtramos por estado

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

  /// Traduce el código de grado a su nombre completo
  String _traducirGrado(String? gradoId) {
    if (gradoId == null) return 'N/A';
    
    final grados = AppConstants.obtenerTodosGrados();
    for (var grado in grados) {
      if (grado['valor'] == gradoId) {
        return grado['label'] ?? gradoId;
      }
    }
    return gradoId;
  }

  void _mostrarFiltroGrado() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar Grado'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroGrado = 'Todos');
              Navigator.pop(context);
            },
            child: const Text('Todos', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          // Primaria
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text('📚 Primaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          ..._gradosPorNivel['Primaria']!.map((grado) {
            return SimpleDialogOption(
              onPressed: () {
                setState(() => _filtroGrado = grado['valor']!);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(grado['label']!),
              ),
            );
          }).toList(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          // Secundaria
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text('🎓 Secundaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          ..._gradosPorNivel['Secundaria']!.map((grado) {
            return SimpleDialogOption(
              onPressed: () {
                setState(() => _filtroGrado = grado['valor']!);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(grado['label']!),
              ),
            );
          }).toList(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          // Preparatoria
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text('👨‍🎓 Preparatoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          ..._gradosPorNivel['Preparatoria']!.map((grado) {
            return SimpleDialogOption(
              onPressed: () {
                setState(() => _filtroGrado = grado['valor']!);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(grado['label']!),
              ),
            );
          }).toList(),
        ],
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

  /// Traduce el código de grado a su etiqueta legible
  String _getEtiquetaGrado(String valor) {
    for (var nivel in _gradosPorNivel.values) {
      for (var grado in nivel) {
        if (grado['valor'] == valor) {
          return grado['label'] ?? valor;
        }
      }
    }
    return valor;
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
            child: const Text('Activos'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroEstado = 'deshabilitados');
              Navigator.pop(context);
            },
            child: const Text('Deshabilitados'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _filtroEstado = 'todos');
              Navigator.pop(context);
            },
            child: const Text('Todos'),
          ),
        ],
      ),
    );
  }

  String _getEtiquetaEstado(String valor) {
    switch (valor) {
      case 'activos':
        return 'Estado: Activos';
      case 'deshabilitados':
        return 'Estado: Deshabilitados';
      case 'todos':
        return 'Estado: Todos';
      default:
        return 'Estado';
    }
  }

  void _mostrarFormularioNuevo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: FormularioEstudiante(
            onSaved: () => setState(() {}),
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioEdicion(UserModel estudiante) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: FormularioEstudiante(
            estudiante: estudiante,
            onSaved: () => setState(() {}),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevo,
        tooltip: 'Nuevo Estudiante',
        child: const Icon(Icons.add),
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

            // Filtros visibles
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Filtro de grado
                    FilterChip(
                      label: const Text('Grado'),
                      onSelected: (_) => _mostrarFiltroGrado(),
                    ),

                    // Mostrar grado seleccionado
                    if (_filtroGrado != 'Todos')
                      Chip(
                        label: Text('Grado: ${_getEtiquetaGrado(_filtroGrado)}'),
                        onDeleted: () => setState(() => _filtroGrado = 'Todos'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),

                    // Filtro de ordenamiento
                    FilterChip(
                      label: const Text('Ordenar'),
                      onSelected: (_) => _mostrarFiltroOrdenamiento(),
                    ),

                    // Mostrar ordenamiento seleccionado
                    Chip(
                      label: Text(_getEtiquetaOrdenamiento(_ordenarPor)),
                    ),

                    // Filtro de estado
                    FilterChip(
                      label: const Text('Estado'),
                      onSelected: (_) => _mostrarFiltroEstado(),
                    ),

                    // Mostrar estado seleccionado
                    Chip(
                      label: Text(_getEtiquetaEstado(_filtroEstado)),
                    ),

                    // Botón de limpiar filtros
                    if (_filtroGrado != 'Todos' || 
                        _ordenarPor != 'nombre' || 
                        _filtroEstado != 'todos' || 
                        _searchController.text.isNotEmpty)
                      ActionChip(
                        label: const Text('Limpiar filtros'),
                        avatar: const Icon(Icons.clear, size: 18),
                        onPressed: _limpiarFiltros,
                        backgroundColor: Colors.orange.shade100,
                      ),
                  ],
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
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final estudiantes = snapshot.data ?? [];
                  final filtrados = _aplicarFiltros(estudiantes);

                  if (filtrados.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.people, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay usuarios que coincidan'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final est = filtrados[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(est.nombre[0].toUpperCase()),
                          ),
                          title: Text(
                            est.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(est.email, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Grado: ${_traducirGrado(est.gradoId)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Chip(
                                    label: Text(
                                      est.activo ? 'Activo' : 'Inactivo',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: est.activo
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Editar Usuario'),
                                    content: Text('¿Deseas editar a ${est.nombre}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _mostrarFormularioEdicion(est);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                        ),
                                        child: const Text('Editar'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (value == 'toggle') {
                                final accion = est.activo ? 'Deshabilitar Usuario' : 'Habilitar Usuario';
                                final mensaje = est.activo
                                    ? '¿Estás seguro de que deseas deshabilitar a ${est.nombre}?'
                                    : '¿Estás seguro de que deseas habilitar a ${est.nombre}?';
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(accion),
                                    content: Text(mensaje),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final success = await _adminService.cambiarEstadoEstudiante(
                                            est.id,
                                            !est.activo,
                                          );

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? (est.activo
                                                          ? '❌ ${est.nombre} deshabilitado'
                                                          : '✅ ${est.nombre} habilitado')
                                                      : '⚠️ Error al actualizar estado',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: est.activo ? Colors.orange : Colors.green,
                                        ),
                                        child: Text(est.activo ? 'Deshabilitar' : 'Habilitar'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar Usuario'),
                                    content: Text(
                                      '¿Estás seguro de que deseas eliminar a ${est.nombre}? Esta acción no se puede deshacer.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final success = await _adminService.eliminarEstudiante(est.id);

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? '🗑️ ${est.nombre} eliminado'
                                                      : '⚠️ Error al eliminar',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      est.activo ? Icons.block : Icons.check_circle,
                                      size: 18,
                                      color: est.activo ? Colors.orange : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(est.activo ? 'Deshabilitar' : 'Habilitar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                            child: const Icon(Icons.more_vert, size: 20),
                          ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Diálogo para crear/editar estudiante
class FormularioEstudiante extends StatefulWidget {
  final UserModel? estudiante;
  final VoidCallback? onSaved;

  const FormularioEstudiante({
    Key? key,
    this.estudiante,
    this.onSaved,
  }) : super(key: key);

  @override
  State<FormularioEstudiante> createState() => _FormularioEstudianteState();
}

class _FormularioEstudianteState extends State<FormularioEstudiante> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  String _gradoId = '4P';
  Set<String> _rolesSeleccionados = {'estudiante'}; // Múltiples roles
  late AdminService _adminService;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _isEditing = widget.estudiante != null;

    if (_isEditing) {
      final est = widget.estudiante!;
      _nombreController.text = est.nombre;
      _emailController.text = est.email;
      _gradoId = est.gradoId ?? '4P';
      _rolesSeleccionados = est.roles.isNotEmpty ? Set.from(est.roles) : {'estudiante'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final todosGrados = AppConstants.obtenerTodosGrados();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth - 32 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Editar Usuario' : 'Agregar Nuevo Usuario'),
            automaticallyImplyLeading: false,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  const Text(
                    'Nombre Completo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Ej: Juan García López',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Email
                  const Text(
                    'Correo Electrónico',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'usuario@ejemplo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Roles del Usuario
                  const Text(
                    'Rol del Usuario',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Rol: Estudiante
                      FilterChip(
                        selected: _rolesSeleccionados.contains('estudiante'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _rolesSeleccionados.clear();
                              _rolesSeleccionados.add('estudiante');
                            }
                          });
                        },
                        label: const Text('Estudiante'),
                        avatar: const Icon(Icons.school, size: 18),
                        tooltip: 'Acceso a pruebas y calificaciones',
                      ),
                      // Rol: Profesor
                      FilterChip(
                        selected: _rolesSeleccionados.contains('profesor'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _rolesSeleccionados.clear();
                              _rolesSeleccionados.add('profesor');
                            }
                          });
                        },
                        label: const Text('Profesor'),
                        avatar: const Icon(Icons.person, size: 18),
                        tooltip: 'Gestión de cursos y estudiantes',
                      ),
                      // Rol: Administrador
                      FilterChip(
                        selected: _rolesSeleccionados.contains('admin'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _rolesSeleccionados.clear();
                              _rolesSeleccionados.add('admin');
                            }
                          });
                        },
                        label: const Text('Administrador'),
                        avatar: const Icon(Icons.admin_panel_settings, size: 18),
                        tooltip: 'Acceso total al sistema',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Grado PLANEA - Solo si es Estudiante
                  Visibility(
                    visible: _rolesSeleccionados.contains('estudiante'),
                    maintainSize: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nivel y Grado PLANEA',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _gradoId,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          items: todosGrados.map((grado) {
                            return DropdownMenuItem(
                              value: grado['valor'],
                              child: Text('${grado['emoji']} ${grado['label']}'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _gradoId = value ?? '4P'),
                          decoration: InputDecoration(
                            hintText: 'Selecciona el grado',
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Info
                  Visibility(
                    visible: !_isEditing,
                    maintainSize: false,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: const Text(
                        '📌 El usuario podrá iniciar sesión con su correo y contraseña: planea123. Podrá cambiarla después.',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
                  onPressed: () async {
                    if (_nombreController.text.isEmpty || _emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ Por favor completa todos los campos')),
                      );
                      return;
                    }

                    if (_rolesSeleccionados.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ Selecciona al menos un rol')),
                      );
                      return;
                    }

                    bool success = false;
                    String mensaje = '';

                    if (_isEditing) {
                      // Actualizar estudiante existente
                      success = await _adminService.actualizarEstudiante(
                        id: widget.estudiante!.id,
                        nombre: _nombreController.text,
                        gradoId: _gradoId,
                      );
                      mensaje = success
                          ? '✅ Estudiante actualizado exitosamente'
                          : '❌ Error al actualizar';
                    } else {
                      // Crear nuevo estudiante
                      success = await _adminService.crearEstudiante(
                        nombre: _nombreController.text,
                        email: _emailController.text,
                        gradoId: _gradoId,
                        roles: _rolesSeleccionados.toList(),
                      );
                      mensaje = success
                          ? '✅ Usuario creado exitosamente con roles: ${_rolesSeleccionados.join(", ")}'
                          : '❌ Error al guardar';
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mensaje),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      widget.onSaved?.call();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
