import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/authentication_service.dart';
import '../services/storage_service.dart';

/// Modal responsivo para editar perfil del usuario
/// Todos los usuarios pueden acceder: alumnos, admin, etc.
class UserProfileModal extends StatefulWidget {
  const UserProfileModal({Key? key}) : super(key: key);

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  String? _urlFotoPerfil;
  String? _tipoUsuario;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final authService = context.read<AuthenticationService>();
      final uid = authService.currentUser?.uid;

      _nombreController =
          TextEditingController(text: authService.currentUser?.displayName ?? '');
      _emailController =
          TextEditingController(text: authService.currentUser?.email ?? '');

      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _urlFotoPerfil = data['fotoPerfil'] as String?;
          _tipoUsuario = data['tipoUsuario'] as String?;
        }

        // Intentar obtener la foto de perfil desde Storage
        final storageService = context.read<StorageService>();
        final url = await storageService.getDownloadUrl('perfil/$uid/foto.jpg');
        if (url != null) {
          _urlFotoPerfil = url;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
    }
  }

  Future<void> _guardarCambios() async {
    if (_nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final authService = context.read<AuthenticationService>();
      final uid = authService.currentUser?.uid;

      if (uid == null) throw Exception('Usuario no autenticado');

      // Actualizar nombre en Firebase Auth
      await authService.currentUser?.updateDisplayName(_nombreController.text);

      // Actualizar datos en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({
        'nombre': _nombreController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 32),
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Foto de perfil
                Container(
                  width: isMobile ? 100 : 120,
                  height: isMobile ? 100 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: Colors.green.shade600,
                      width: 3,
                    ),
                    image: _urlFotoPerfil != null
                        ? DecorationImage(
                            image: NetworkImage(_urlFotoPerfil!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _urlFotoPerfil == null
                      ? Icon(
                          Icons.person,
                          size: isMobile ? 50 : 60,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),

                const SizedBox(height: 20),

                // Tipo de usuario
                if (_tipoUsuario != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _tipoUsuario == 'admin'
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tipoUsuario == 'admin' ? '👨‍💼 Administrador' : '👤 Alumno',
                      style: TextStyle(
                        color: _tipoUsuario == 'admin'
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Campos de edición
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    hintText: 'No se puede cambiar',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Guardar cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
