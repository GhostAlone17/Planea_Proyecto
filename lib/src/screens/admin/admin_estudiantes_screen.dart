import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../config/app_constants.dart';

/// Pantalla para gestionar estudiantes (padrón)
/// Permite:
/// - Crear nuevos estudiantes (solo admin)
/// - Ver lista de estudiantes
/// - Editar estudiantes (solo admin)
/// - Eliminar estudiantes (solo admin)
/// - Deshabilitar/Habilitar estudiantes (admin y maestro)
/// 
/// SI ES MAESTRO:
/// - Solo ve alumnos (no maestros)
/// - No puede editar ni eliminar
/// - Solo puede deshabilitar/habilitar
class AdminEstudiantesScreen extends StatefulWidget {
  const AdminEstudiantesScreen({Key? key}) : super(key: key);

  @override
  State<AdminEstudiantesScreen> createState() => _AdminEstudiantesScreenState();
}

class _AdminEstudiantesScreenState extends State<AdminEstudiantesScreen> {
  final _searchController = TextEditingController();
  late AdminService _adminService;
  bool _isMaestro = false;
  
  // Variables de filtro
  String _filtroGrado = 'Todos';
  String _ordenarPor = 'nombre'; // nombre, fecha, estado
  String _filtroEstado = 'todos'; // activos, deshabilitados, todos - CAMBIO: inicia en 'todos'
  String _tipoUsuario = 'estudiantes'; // estudiantes, maestros, todos (maestro solo ve estudiantes)
  
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
    _detectarTipoUsuario();
    _searchController.addListener(_filtrarEstudiantes);
  }

  /// Detectar si el usuario actual es maestro
  Future<void> _detectarTipoUsuario() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final tipoUsuario = data['tipoUsuario'] as String?;
        
        setState(() {
          _isMaestro = tipoUsuario == 'maestro';
          // Si es maestro, forzar filtro a solo estudiantes
          if (_isMaestro) {
            _tipoUsuario = 'estudiantes';
          }
        });
      }
    } catch (e) {
      print('Error detectando tipo de usuario: $e');
    }
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
      _tipoUsuario = 'todos';
      _searchController.clear();
    });
  }

  /// Aplica todos los filtros a la lista de estudiantes
  List<UserModel> _aplicarFiltros(List<UserModel> usuarios) {
    var filtrados = usuarios;

    // Filtro de tipo de usuario (estudiantes/maestros)
    if (_tipoUsuario == 'estudiantes') {
      filtrados = filtrados.where((u) => u.tipoUsuario == 'alumno').toList();
    } else if (_tipoUsuario == 'maestros') {
      filtrados = filtrados.where((u) => u.tipoUsuario == 'maestro').toList();
    }

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
  String _traducirGrado(String? gradoId, {String? gradoNombre}) {
    // Si tiene gradoNombre, usarlo y mejorar el formato
    if (gradoNombre != null && gradoNombre.isNotEmpty && gradoNombre != 'N/A') {
      // Si es "Secundaria", mostrar "3° de Secundaria" ya que es el único grado que manejamos
      if (gradoNombre.toLowerCase() == 'secundaria') {
        return '3° de Secundaria';
      }
      return gradoNombre;
    }
    
    // Si no hay gradoId, retornar N/A
    if (gradoId == null || gradoId.isEmpty) return 'N/A';
    
    // Buscar el gradoId en los grados disponibles
    final grados = AppConstants.obtenerTodosGrados();
    for (var grado in grados) {
      if (grado['valor'] == gradoId) {
        final label = grado['label'] ?? gradoId;
        // Aplicar la misma lógica para gradoId
        if (label.toLowerCase() == 'secundaria') {
          return '3° de Secundaria';
        }
        return label;
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
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: const [
                Icon(Icons.menu_book_rounded, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text('Primaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ],
            ),
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
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: const [
                Icon(Icons.school, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text('Secundaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ],
            ),
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
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: const [
                Icon(Icons.school_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text('Preparatoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ],
            ),
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

  void _mostrarFiltroTipoUsuario() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filtrar por Tipo de Usuario'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _tipoUsuario = 'todos');
              Navigator.pop(context);
            },
            child: const Text('Todos', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _tipoUsuario = 'estudiantes');
              Navigator.pop(context);
            },
            child: Row(
              children: const [
                Icon(Icons.groups_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text('Estudiantes'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _tipoUsuario = 'maestros');
              Navigator.pop(context);
            },
            child: Row(
              children: const [
                Icon(Icons.person_outline, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text('Maestros'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEtiquetaTipoUsuario(String valor) {
    switch (valor) {
      case 'estudiantes':
        return 'Tipo: Estudiantes';
      case 'maestros':
        return 'Tipo: Maestros';
      case 'todos':
        return 'Tipo: Todos';
      default:
        return 'Tipo';
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
        title: Text(_isMaestro 
          ? 'Gestión de Alumnos' 
          : 'Gestión de Usuarios (Estudiantes y Maestros)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: _isMaestro ? null : FloatingActionButton(
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
                // Primera fila: Filtros principales
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Filtro de tipo de usuario (solo admin)
                    if (!_isMaestro) ...[
                      FilterChip(
                        label: const Text('Tipo'),
                        onSelected: (_) => _mostrarFiltroTipoUsuario(),
                      ),

                      // Mostrar tipo seleccionado
                      if (_tipoUsuario != 'todos')
                        Chip(
                          label: Text(_getEtiquetaTipoUsuario(_tipoUsuario)),
                          onDeleted: () => setState(() => _tipoUsuario = 'todos'),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        ),
                    ],

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
                  ],
                ),
                const SizedBox(height: 12),
                // Segunda fila: Botón Limpiar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: 'Restablecer todos los filtros',
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Limpiar'),
                        onPressed: _limpiarFiltros,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de usuarios (estudiantes y maestros)
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _adminService.streamUsuarios(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final usuarios = snapshot.data ?? [];
                  final filtrados = _aplicarFiltros(usuarios);

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
                      final usr = filtrados[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(usr.nombre[0].toUpperCase()),
                          ),
                          title: Text(
                            usr.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(usr.email, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Mostrar grado solo si es estudiante
                                  if (usr.tipoUsuario == 'alumno')
                                    Expanded(
                                      child: Text(
                                        'Grado: ${_traducirGrado(usr.gradoId, gradoNombre: usr.gradoNombre)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Rol: ',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          Icon(
                                            usr.tipoUsuario == 'maestro' ? Icons.person_outline : Icons.admin_panel_settings_outlined,
                                            size: 14,
                                            color: Colors.grey[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            usr.tipoUsuario == 'maestro' ? 'Maestro' : 'Admin',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Badge de estado en su propia fila
                              Row(
                                children: [
                                  // Mostrar estado de aprobación si es maestro
                                  if (usr.tipoUsuario == 'maestro')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (usr.aprobado ?? false)
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (usr.aprobado ?? false)
                                              ? Colors.green.shade300
                                              : Colors.orange.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            (usr.aprobado ?? false) ? Icons.check_circle : Icons.pending,
                                            size: 14,
                                            color: (usr.aprobado ?? false)
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (usr.aprobado ?? false) ? 'Aprobado' : 'Pendiente',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: (usr.aprobado ?? false)
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: usr.activo
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: usr.activo
                                              ? Colors.green.shade300
                                              : Colors.red.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            usr.activo ? Icons.check_circle : Icons.cancel,
                                            size: 14,
                                            color: usr.activo
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            usr.activo ? 'Activo' : 'Inactivo',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: usr.activo
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _mostrarFormularioEdicion(usr);
                              } else if (value == 'toggle') {
                                final accion = usr.activo ? 'Deshabilitar Usuario' : 'Habilitar Usuario';
                                final mensaje = usr.activo
                                    ? '¿Estás seguro de que deseas deshabilitar a ${usr.nombre}?'
                                    : '¿Estás seguro de que deseas habilitar a ${usr.nombre}?';
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
                                            usr.id,
                                            !usr.activo,
                                          );

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? (usr.activo
                                                          ? '❌ ${usr.nombre} deshabilitado'
                                                          : '✅ ${usr.nombre} habilitado')
                                                      : '⚠️ Error al actualizar estado',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: usr.activo ? Colors.orange : Colors.green,
                                        ),
                                        child: Text(usr.activo ? 'Deshabilitar' : 'Habilitar'),
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
                                      '¿Estás seguro de que deseas eliminar a ${usr.nombre}? Esta acción no se puede deshacer.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final success = await _adminService.eliminarEstudiante(usr.id);

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(
                                                      success ? Icons.delete_outline : Icons.warning_amber_outlined,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      success
                                                          ? '${usr.nombre} eliminado'
                                                          : 'Error al eliminar',
                                                    ),
                                                  ],
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
                              // Editar (solo admin)
                              if (!_isMaestro)
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
                              // Deshabilitar/Habilitar (admin y maestro)
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      usr.activo ? Icons.block : Icons.check_circle,
                                      size: 18,
                                      color: usr.activo ? Colors.orange : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(usr.activo ? 'Deshabilitar' : 'Habilitar'),
                                  ],
                                ),
                              ),
                              // Eliminar (solo admin)
                              if (!_isMaestro)
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
  String? _gradoId = '4P'; // CAMBIO: Ahora nullable para maestros
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
      _gradoId = est.gradoId; // CAMBIO: Permitir null para maestros
      
      // Detectar roles desde tipoUsuario
      if (est.tipoUsuario == 'admin') {
        _rolesSeleccionados = {'admin'};
      } else if (est.tipoUsuario == 'maestro') {
        _rolesSeleccionados = {'profesor'};
      } else {
        _rolesSeleccionados = est.roles.isNotEmpty ? Set.from(est.roles) : {'estudiante'};
      }
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
                        Builder(
                          builder: (context) {
                            // Asegurar que el valor actual esté en la lista disponible
                            final valoresDisponibles = todosGrados.map((g) => g['valor'] as String).toList();
                            String valorActual = _gradoId ?? '4P';
                            
                            // Si el valor actual no está en la lista, usar el primero disponible
                            if (!valoresDisponibles.contains(valorActual)) {
                              valorActual = valoresDisponibles.isNotEmpty ? valoresDisponibles.first : '4P';
                              // Actualizar el estado solo si cambió
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_gradoId != valorActual) {
                                  setState(() => _gradoId = valorActual);
                                }
                              });
                            }
                            
                            return DropdownButtonFormField<String>(
                              value: valorActual,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                              items: todosGrados.map((grado) {
                                // Determinar ícono según el grado
                                IconData icono = Icons.school;
                                Color colorIcono = Colors.blue;
                                
                                final valor = grado['valor'] as String;
                                if (valor.contains('P')) {
                                  icono = Icons.child_care;
                                  colorIcono = Colors.blue.shade600;
                                } else if (valor.contains('S')) {
                                  icono = Icons.school_outlined;
                                  colorIcono = Colors.purple.shade600;
                                } else if (valor.contains('EMS') || valor.contains('Prep')) {
                                  icono = Icons.auto_stories;
                                  colorIcono = Colors.orange.shade600;
                                }
                                
                                return DropdownMenuItem(
                                  value: grado['valor'],
                                  child: Row(
                                    children: [
                                      Icon(icono, size: 18, color: colorIcono),
                                      const SizedBox(width: 8),
                                      Text(grado['label'] as String),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _gradoId = value ?? valorActual),
                              decoration: InputDecoration(
                                hintText: 'Selecciona el grado',
                                prefixIcon: const Icon(Icons.school_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            );
                          },
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline, size: 14, color: Colors.blue),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'El usuario podrá iniciar sesión con su correo y contraseña: planea123. Podrá cambiarla después.',
                              style: TextStyle(fontSize: 11, color: Colors.blue),
                            ),
                          ),
                        ],
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
                      // Actualizar estudiante/maestro existente
                      // Solo actualizar gradoId si es estudiante (tiene grado)
                      if (_rolesSeleccionados.contains('estudiante')) {
                        success = await _adminService.actualizarEstudiante(
                          id: widget.estudiante!.id,
                          nombre: _nombreController.text,
                          gradoId: _gradoId ?? '4P',
                        );
                      } else {
                        // Para maestros/admin, solo actualizar nombre (sin gradoId)
                        success = await _adminService.actualizarEstudiante(
                          id: widget.estudiante!.id,
                          nombre: _nombreController.text,
                          gradoId: widget.estudiante!.gradoId ?? '4P', // Mantener el grado original
                        );
                      }
                      mensaje = success
                          ? '✅ Usuario actualizado exitosamente'
                          : '❌ Error al actualizar';
                    } else {
                      // Crear nuevo usuario
                      // Solo enviar gradoId si es estudiante
                      final gradoFinal = _rolesSeleccionados.contains('estudiante') 
                          ? (_gradoId ?? '4P')
                          : '4P'; // Valor por defecto para no-estudiantes (no se usa)
                      
                      success = await _adminService.crearEstudiante(
                        nombre: _nombreController.text,
                        email: _emailController.text,
                        gradoId: gradoFinal,
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
