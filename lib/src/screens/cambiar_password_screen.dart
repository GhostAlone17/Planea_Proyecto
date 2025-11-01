import 'package:flutter/material.dart';
import '../services/password_service.dart';
import '../config/app_constants.dart';

/// Pantalla para cambiar la contraseña del usuario
/// Compatible con Admin, Maestro y Alumno
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
    final nuevaValida = _esContrasenaValida(_passwordNuevaController.text);
    final confirmada = _passwordNuevaController.text == _passwordConfirmarController.text &&
        _passwordNuevaController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Cambiar Contraseña'),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppConstants.colorPrimario.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con ícono
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppConstants.colorPrimario.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: AppConstants.colorPrimario,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título y descripción
                    Center(
                      child: Text(
                        'Actualiza tu Contraseña',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Elige una contraseña fuerte para proteger tu cuenta',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tarjeta de contraseña actual
                    _buildPasswordField(
                      label: 'Contraseña Actual',
                      hint: 'Ingresa tu contraseña actual',
                      controller: _passwordActualController,
                      isObscure: !_mostrarPasswordActual,
                      onVisibilityToggle: () =>
                          setState(() => _mostrarPasswordActual = !_mostrarPasswordActual),
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta de contraseña nueva
                    _buildPasswordField(
                      label: 'Contraseña Nueva',
                      hint: 'Crea una contraseña fuerte',
                      controller: _passwordNuevaController,
                      isObscure: !_mostrarPasswordNueva,
                      onVisibilityToggle: () =>
                          setState(() => _mostrarPasswordNueva = !_mostrarPasswordNueva),
                      onChanged: (_) => setState(() {}),
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 16),

                    // Validación de contraseña
                    if (_passwordNuevaController.text.isNotEmpty)
                      _buildPasswordValidationCard(_passwordNuevaController.text),

                    const SizedBox(height: 20),

                    // Tarjeta de confirmación
                    _buildPasswordField(
                      label: 'Confirmar Contraseña',
                      hint: 'Repite tu nueva contraseña',
                      controller: _passwordConfirmarController,
                      isObscure: !_mostrarPasswordConfirmar,
                      onVisibilityToggle: () =>
                          setState(() => _mostrarPasswordConfirmar = !_mostrarPasswordConfirmar),
                      icon: Icons.lock_outline,
                    ),

                    // Indicador de coincidencia
                    if (_passwordConfirmarController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              confirmada ? Icons.check_circle : Icons.info,
                              size: 18,
                              color: confirmada ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              confirmada ? '✓ Las contraseñas coinciden' : '⚠️ Las contraseñas no coinciden',
                              style: TextStyle(
                                fontSize: 13,
                                color: confirmada ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _cargando ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _cargando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(_cargando ? 'Cambiando...' : 'Cambiar'),
                            onPressed: (nuevaValida && confirmada && !_cargando)
                                ? _cambiarPassword
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.colorPrimario,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Consejo de seguridad
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '💡 Usa una contraseña única y no la compartas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onVisibilityToggle,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: onVisibilityToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.colorPrimario,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordValidationCard(String password) {
    final longitudOk = password.length >= 8;
    final mayusculaOk = password.contains(RegExp(r'[A-Z]'));
    final numeroOk = password.contains(RegExp(r'[0-9]'));
    final todosOk = longitudOk && mayusculaOk && numeroOk;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: todosOk ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: todosOk ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                todosOk ? Icons.check_circle : Icons.security,
                size: 16,
                color: todosOk ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                todosOk ? '✓ Contraseña fuerte' : '⚠️ Requisitos de seguridad',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: todosOk ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildValidationItem(
            icon: longitudOk ? Icons.check_circle : Icons.radio_button_unchecked,
            text: 'Al menos 8 caracteres',
            isValid: longitudOk,
          ),
          const SizedBox(height: 6),
          _buildValidationItem(
            icon: mayusculaOk ? Icons.check_circle : Icons.radio_button_unchecked,
            text: 'Contiene mayúscula (A-Z)',
            isValid: mayusculaOk,
          ),
          const SizedBox(height: 6),
          _buildValidationItem(
            icon: numeroOk ? Icons.check_circle : Icons.radio_button_unchecked,
            text: 'Contiene número (0-9)',
            isValid: numeroOk,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationItem({
    required IconData icon,
    required String text,
    required bool isValid,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isValid ? Colors.green : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isValid ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  bool _esContrasenaValida(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  void _cambiarPassword() async {
    // Validaciones finales
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

    if (!_esContrasenaValida(_passwordNuevaController.text)) {
      _mostrarError('La contraseña no cumple los requisitos de seguridad');
      return;
    }

    setState(() => _cargando = true);

    final resultado = await _passwordService.cambiarPassword(
      passwordAntigua: _passwordActualController.text,
      passwordNueva: _passwordNuevaController.text,
    );

    setState(() => _cargando = false);

    if (mounted) {
      if (resultado.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✓ Contraseña actualizada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(resultado.message)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
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
