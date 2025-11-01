import 'package:flutter/material.dart';
import '../../models/reactive_model.dart';
import '../../models/category_model_v2.dart';
import '../../services/admin_service.dart';
import 'filtros_avanzados_reactivos.dart';

/// Pantalla para gestionar reactivos (preguntas del examen)
class AdminReactivosScreen extends StatefulWidget {
  const AdminReactivosScreen({Key? key}) : super(key: key);

  @override
  State<AdminReactivosScreen> createState() => _AdminReactivosScreenState();
}

class _AdminReactivosScreenState extends State<AdminReactivosScreen> {
  final _searchController = TextEditingController();
  String _filtroCategoria = 'Todas';
  late AdminService _adminService;
  final List<CategoryModelV2> _categorias = CategoryModelV2.categoriasDefault();
  
  // Filtros avanzados
  int _dificultadMin = 1;
  int _dificultadMax = 3;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _searchController.addListener(_filtrarReactivos);
  }

  void _filtrarReactivos() {
    setState(() {});
  }

  void _abrirFiltrosAvanzados() {
    showDialog(
      context: context,
      builder: (context) => FiltrosAvanzadosReactivos(
        filtrosActuales: {
          'categoria': _filtroCategoria,
          'dificultadMin': _dificultadMin,
          'dificultadMax': _dificultadMax,
          'soloActivos': true,
        },
        onAplicar: (filtros) {
          setState(() {
            _filtroCategoria = filtros['categoria'];
            _dificultadMin = filtros['dificultadMin'];
            _dificultadMax = filtros['dificultadMax'];
          });
        },
      ),
    );
  }

  String _obtenerNombreCategoria(String id) {
    try {
      return _categorias.firstWhere((c) => c.id == id).nombre;
    } catch (e) {
      return 'Desconocida';
    }
  }

  String _obtenerNivelDificultad(int nivel) {
    switch (nivel) {
      case 1:
        return 'Fácil';
      case 2:
        return 'Medio';
      case 3:
        return 'Difícil';
      default:
        return 'Desconocido';
    }
  }

  void _mostrarFormularioNuevo() {
    showDialog(
      context: context,
      builder: (context) => FormularioReactivo(
        categorias: _categorias,
        adminService: _adminService,
      ),
    );
  }

  void _editarReactivo(ReactiveModel reactivo) {
    showDialog(
      context: context,
      builder: (context) => FormularioReactivo(
        categorias: _categorias,
        reactivoExistente: reactivo,
        adminService: _adminService,
      ),
    );
  }

  void _eliminarReactivo(ReactiveModel reactivo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reactivo'),
        content: const Text('¿Estás seguro que deseas eliminar este reactivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _adminService.eliminarReactivo(reactivo.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? '✅ Reactivo eliminado' 
                        : '❌ Error al eliminar',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
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
        title: const Text('Gestión de Reactivos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevo,
        tooltip: 'Nuevo Reactivo',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          children: [
            // Barra de búsqueda y botón de filtros - Responsive
            if (isMobile)
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar reactivos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.tune),
                      label: const Text('Filtros Avanzados'),
                      onPressed: _abrirFiltrosAvanzados,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar reactivos...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Filtros'),
                    onPressed: _abrirFiltrosAvanzados,
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Filtro por categoría
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📚 Categorías',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...[
                      'Todas',
                      ..._categorias.map((c) => c.nombre),
                    ].map((cat) {
                      final isSelected = _filtroCategoria == cat;
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _filtroCategoria = cat);
                          _filtrarReactivos();
                        },
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Botón Limpiar Filtros
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: 'Restablecer todos los filtros',
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    onPressed: () {
                      setState(() {
                        _filtroCategoria = 'Todas';
                        _dificultadMin = 1;
                        _dificultadMax = 3;
                        _searchController.clear();
                      });
                      _filtrarReactivos();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lista de reactivos
            Expanded(
              child: StreamBuilder<List<ReactiveModel>>(
                stream: _adminService.streamReactivos(
                  categoryId: _filtroCategoria == 'Todas' 
                    ? null 
                    : _categorias.firstWhere((c) => c.nombre == _filtroCategoria, orElse: () => _categorias[0]).id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final reactivos = snapshot.data ?? [];
                  final query = _searchController.text.toLowerCase();
                  
                  // Aplicar todos los filtros
                  final filtrados = reactivos
                      .where((r) {
                        // Filtro de búsqueda
                        final coincideTexto = r.pregunta.toLowerCase().contains(query) ||
                                              (r.explicacion?.toLowerCase().contains(query) ?? false);
                        
                        // Filtro de dificultad
                        final coincideDificultad = r.dificultad >= _dificultadMin && 
                                                   r.dificultad <= _dificultadMax;
                        
                        return coincideTexto && coincideDificultad;
                      })
                      .toList();

                  if (filtrados.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.quiz, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay reactivos registrados'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final reactivo = filtrados[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      reactivo.pregunta,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editarReactivo(reactivo);
                                      } else if (value == 'delete') {
                                        _eliminarReactivo(reactivo);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: [
                                  Chip(
                                    label: Text(
                                      _obtenerNombreCategoria(
                                          reactivo.categoryId),
                                    ),
                                    backgroundColor: Colors.blue.shade100,
                                  ),
                                  Chip(
                                    label: Text(
                                      'Dificultad: ${_obtenerNivelDificultad(reactivo.dificultad)}',
                                    ),
                                    backgroundColor: Colors.orange.shade100,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Opciones:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...reactivo.opciones.asMap().entries.map((e) {
                                final i = e.key;
                                final opcion = e.value;
                                final esCorrecta =
                                    i == reactivo.respuestaCorrecta;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      if (esCorrecta)
                                        const Icon(Icons.check_circle,
                                            size: 18, color: Colors.green)
                                      else
                                        const Icon(
                                            Icons.radio_button_unchecked,
                                            size: 18,
                                            color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${String.fromCharCode(65 + i)}) $opcion',
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
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

/// Diálogo para crear/editar reactivo
class FormularioReactivo extends StatefulWidget {
  final List<CategoryModelV2> categorias;
  final ReactiveModel? reactivoExistente;
  final AdminService adminService;

  const FormularioReactivo({
    Key? key,
    required this.categorias,
    this.reactivoExistente,
    required this.adminService,
  }) : super(key: key);

  @override
  State<FormularioReactivo> createState() => _FormularioReactivoState();
}

class _FormularioReactivoState extends State<FormularioReactivo> {
  final _preguntaController = TextEditingController();
  late List<TextEditingController> _opcionesControllers;
  final _explicacionController = TextEditingController();

  int _respuestaCorrecta = 0;
  int _dificultad = 1;
  late String _categoriaId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _categoriaId = widget.categorias.isNotEmpty ? widget.categorias[0].id : '';
    
    if (widget.reactivoExistente != null) {
      // Cargar datos del reactivo existente
      final reactivo = widget.reactivoExistente!;
      _preguntaController.text = reactivo.pregunta;
      _categoriaId = reactivo.categoryId;
      _respuestaCorrecta = reactivo.respuestaCorrecta;
      _dificultad = reactivo.dificultad;
      _explicacionController.text = reactivo.explicacion ?? '';
      _opcionesControllers = reactivo.opciones
          .map((opcion) => TextEditingController(text: opcion))
          .toList();
    } else {
      // Inicializar con 4 opciones por defecto
      _opcionesControllers = List.generate(4, (_) => TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isEditing = widget.reactivoExistente != null;

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Reactivo' : 'Nuevo Reactivo',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _preguntaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Pregunta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Categoría
                DropdownButtonFormField(
                  value: _categoriaId,
                  items: widget.categorias
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _categoriaId = value ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Dificultad
                DropdownButtonFormField(
                  value: _dificultad,
                  items: [1, 2, 3]
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d == 1
                                  ? 'Fácil'
                                  : d == 2
                                      ? 'Medio'
                                      : 'Difícil',
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _dificultad = value ?? 1),
                  decoration: const InputDecoration(
                    labelText: 'Dificultad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Sección de opciones dinámicas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Opciones:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_opcionesControllers.length < 6)
                      Tooltip(
                        message: 'Agregar opción (máximo 6)',
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _opcionesControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: Colors.green.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de opciones dinámicas
                ..._opcionesControllers.asMap().entries.map((e) {
                  final index = e.key;
                  final controller = e.value;
                  final puedeEliminar = _opcionesControllers.length > 2;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _respuestaCorrecta == index
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: _respuestaCorrecta == index ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _respuestaCorrecta == index
                            ? Colors.green.shade50
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Radio button
                          Tooltip(
                            message: 'Marcar como respuesta correcta',
                            child: Radio(
                              value: index,
                              groupValue: _respuestaCorrecta,
                              onChanged: (value) {
                                setState(
                                    () => _respuestaCorrecta = value ?? 0);
                              },
                            ),
                          ),
                          // Letra (A, B, C, etc.)
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${String.fromCharCode(65 + index)})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Campo de texto
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'Opción ${String.fromCharCode(65 + index)}',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ),
                          // Botón eliminar (solo si puede)
                          if (puedeEliminar)
                            Tooltip(
                              message: 'Eliminar opción',
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller.dispose();
                                    _opcionesControllers.removeAt(index);
                                    // Ajustar respuesta correcta si es necesario
                                    if (_respuestaCorrecta >= _opcionesControllers.length) {
                                      _respuestaCorrecta =
                                          _opcionesControllers.length - 1;
                                    }
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            )
                          else
                            const SizedBox(width: 32),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),
                TextField(
                  controller: _explicacionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Explicación',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardarReactivo,
                      child: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Actualizar' : 'Guardar'),
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

  Future<void> _guardarReactivo() async {
    // Validar campos
    if (_preguntaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una pregunta')),
      );
      return;
    }

    // Validar que todas las opciones tengan texto
    if (_opcionesControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todas las opciones')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final opciones = _opcionesControllers.map((c) => c.text).toList();
      final isEditing = widget.reactivoExistente != null;

      bool success;
      if (isEditing) {
        // Actualizar reactivo existente
        success = await widget.adminService.actualizarReactivo(
          id: widget.reactivoExistente!.id,
          pregunta: _preguntaController.text,
          opciones: opciones,
          respuestaCorrecta: _respuestaCorrecta,
          dificultad: _dificultad,
          explicacion: _explicacionController.text.isEmpty 
              ? null 
              : _explicacionController.text,
        );
      } else {
        // Crear nuevo reactivo
        success = await widget.adminService.crearReactivo(
          categoryId: _categoriaId,
          pregunta: _preguntaController.text,
          opciones: opciones,
          respuestaCorrecta: _respuestaCorrecta,
          dificultad: _dificultad,
          explicacion: _explicacionController.text.isEmpty 
              ? null 
              : _explicacionController.text,
          creadoPor: 'admin',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? (isEditing 
                    ? '✅ Reactivo actualizado' 
                    : '✅ Reactivo creado exitosamente')
                : '❌ Error al guardar',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    _preguntaController.dispose();
    for (var controller in _opcionesControllers) {
      controller.dispose();
    }
    _explicacionController.dispose();
    super.dispose();
  }
}
