import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminMaestrosValidationScreen extends StatefulWidget {
  const AdminMaestrosValidationScreen({Key? key}) : super(key: key);

  @override
  State<AdminMaestrosValidationScreen> createState() =>
      _AdminMaestrosValidationScreenState();
}

class _AdminMaestrosValidationScreenState
    extends State<AdminMaestrosValidationScreen> {
  List<UserModel> _maestrosPendientes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarMaestrosPendientes();
  }

  Future<void> _cargarMaestrosPendientes() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminService = context.read<AdminService>();
      final maestros = await adminService.obtenerMaestrosPendientes();

      if (mounted) {
        setState(() {
          _maestrosPendientes = maestros;
          _isLoading = false;
          print('✅ Maestros pendientes cargados: ${maestros.length}');
        });
      }
    } catch (e) {
      print('❌ Error cargando maestros: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar maestros: $e';
        });
      }
    }
  }

  Future<void> _aprobarMaestro(String maestroId, String nombre) async {
    final adminService = context.read<AdminService>();

    // Mostrar confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Maestro'),
        content: Text(
          '¿Aprobar a $nombre para que pueda iniciar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(backgroundColor: Colors.green.shade100),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final resultado = await adminService.aprobarMaestro(maestroId);

      if (resultado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $nombre aprobado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          await _cargarMaestrosPendientes();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al aprobar maestro'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rechazarMaestro(String maestroId, String nombre) async {
    final adminService = context.read<AdminService>();

    // Mostrar confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Maestro'),
        content: Text(
          '¿Rechazar solicitud de $nombre? No podrá iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(backgroundColor: Colors.red.shade100),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final resultado = await adminService.rechazarMaestro(maestroId);

      if (resultado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Solicitud de $nombre rechazada'),
              backgroundColor: Colors.orange,
            ),
          );

          await _cargarMaestrosPendientes();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al rechazar maestro'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Maestros'),
        elevation: 0,
        backgroundColor: Colors.orange.shade600,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando maestros pendientes...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Error desconocido',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarMaestrosPendientes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _maestrosPendientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 64,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay maestros pendientes',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Todos los maestros han sido revisados',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarMaestrosPendientes,
                  child: ListView.builder(
                    itemCount: _maestrosPendientes.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final maestro = _maestrosPendientes[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del maestro
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_outline,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          maestro.nombre,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          maestro.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Información de solicitud
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Solicitud enviada el ${_formatearFecha(maestro.fechaRegistro)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _aprobarMaestro(
                                        maestro.id,
                                        maestro.nombre,
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Aprobar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _rechazarMaestro(
                                        maestro.id,
                                        maestro.nombre,
                                      ),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Rechazar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _cargarMaestrosPendientes,
        backgroundColor: Colors.orange.shade600,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final diferencia = hoy.difference(fecha).inDays;

    if (diferencia == 0) {
      return 'Hoy a las ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diferencia == 1) {
      return 'Ayer';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
