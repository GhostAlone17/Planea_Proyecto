import 'package:flutter/material.dart';
import '../services/password_service.dart';

/// Pantalla para cambiar la contraseña del usuario
class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({Key? key}) : super(key: key);

  @override
  State<CambiarPasswordScreen> createState() =>
      _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _passwordService = PasswordService();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  bool _mostrarPasswordActual = false;
  bool _mostrarPasswordNueva = false;
  bool _mostrarPasswordConfirmar = false;
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: const Text(
                    '📌 Tu contraseña debe tener al menos 6 caracteres e incluir números.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 24),

                // Contraseña Actual
                const Text(
                  'Contraseña Actual',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordActualController,
                  obscureText: !_mostrarPasswordActual,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPasswordActual
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _mostrarPasswordActual = !_mostrarPasswordActual),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 18),

                // Contraseña Nueva
                const Text(
                  'Contraseña Nueva',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordNuevaController,
                  obscureText: !_mostrarPasswordNueva,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPasswordNueva
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _mostrarPasswordNueva = !_mostrarPasswordNueva),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 8),

                // Validación de contraseña
                if (_passwordNuevaController.text.isNotEmpty)
                  _buildPasswordValidation(_passwordNuevaController.text),

                const SizedBox(height: 18),

                // Confirmar Contraseña
                const Text(
                  'Confirmar Contraseña',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordConfirmarController,
                  obscureText: !_mostrarPasswordConfirmar,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Confirma tu nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPasswordConfirmar
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                          () => _mostrarPasswordConfirmar = !_mostrarPasswordConfirmar),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _cargando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_cargando ? 'Cambiando...' : 'Cambiar'),
                      onPressed: _cargando ? null : _cambiarPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
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

  Widget _buildPasswordValidation(String password) {
    final longitudOk = password.length >= 6;
    final numeroOk = password.contains(RegExp(r'[0-9]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              longitudOk ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: longitudOk ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'Al menos 6 caracteres',
              style: TextStyle(
                fontSize: 12,
                color: longitudOk ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              numeroOk ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: numeroOk ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'Contiene al menos un número',
              style: TextStyle(
                fontSize: 12,
                color: numeroOk ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _cambiarPassword() async {
    // Validaciones
    if (_passwordActualController.text.isEmpty) {
      _mostrarError('Por favor ingresa tu contraseña actual');
      return;
    }

    if (_passwordNuevaController.text.isEmpty) {
      _mostrarError('Por favor ingresa tu nueva contraseña');
      return;
    }

    if (_passwordConfirmarController.text.isEmpty) {
      _mostrarError('Por favor confirma tu nueva contraseña');
      return;
    }

    if (_passwordNuevaController.text != _passwordConfirmarController.text) {
      _mostrarError('Las contraseñas nuevas no coinciden');
      return;
    }

    if (_passwordActualController.text == _passwordNuevaController.text) {
      _mostrarError('La nueva contraseña debe ser diferente a la actual');
      return;
    }

    final validation =
        PasswordService.validarContrasena(_passwordNuevaController.text);
    if (!validation.isValid) {
      _mostrarError(validation.message);
      return;
    }

    setState(() => _cargando = true);

    final resultado = await _passwordService.cambiarPassword(
      passwordAntigua: _passwordActualController.text,
      passwordNueva: _passwordNuevaController.text,
    );

    setState(() => _cargando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.message),
          backgroundColor:
              resultado.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      if (resultado.success) {
        Navigator.pop(context);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $mensaje'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }
}
