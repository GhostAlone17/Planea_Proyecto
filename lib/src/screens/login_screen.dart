import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/authentication_service.dart';
import '../utils/dialog_helper.dart';
import '../utils/validators.dart';

/// Pantalla de login y registro mejorada
class LoginScreen extends StatefulWidget {
  final VoidCallback? onLogin;
  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _nombre = '';
  bool _isLogin = true;
  bool _showPassword = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (!mounted) return;

    final authService = context.read<AuthenticationService>();

    bool success = false;
    if (_isLogin) {
      success = await authService.login(
        email: _email,
        password: _password,
      );
    } else {
      success = await authService.register(
        email: _email,
        password: _password,
        displayName: _nombre,
      );
    }

    if (!mounted) return;

    if (success) {
      if (mounted) {
        DialogHelper.showSuccess(context, '¡Bienvenido!');
      }
      widget.onLogin?.call();
    } else {
      if (mounted) {
        DialogHelper.showError(
            context, authService.errorMessage ?? 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Consumer<AuthenticationService>(
                builder: (context, authService, _) {
                  return Container(
                    constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header con logo y título
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: isMobile ? 40 : 50,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'PLANEA',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Preparación PLANEA - Matemáticas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Título dinámico
                            Text(
                              _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? 'Accede a tu cuenta para continuar'
                                  : 'Crea una nueva cuenta para comenzar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Campo nombre (solo en registro)
                            if (!_isLogin)
                              Column(
                                children: [
                                  _buildModernTextField(
                                    label: 'Nombre completo',
                                    hint: 'Tu nombre',
                                    icon: Icons.person,
                                    validator: (v) =>
                                        Validators.required(v, 'Nombre'),
                                    onSaved: (v) => _nombre = v ?? '',
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            // Campo email
                            _buildModernTextField(
                              label: 'Correo electrónico',
                              hint: 'ejemplo@correo.com',
                              icon: Icons.email,
                              validator: Validators.email,
                              onSaved: (v) => _email = v ?? '',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Campo contraseña con ojo
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                hintText: 'Tu contraseña segura',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: isMobile ? 12 : 13,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _showPassword = !_showPassword);
                                  },
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              obscureText: !_showPassword,
                              validator: (v) => Validators.password(v),
                              onSaved: (v) => _password = v ?? '',
                            ),
                            const SizedBox(height: 24),

                            // Botón de envío
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: authService.isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.green.shade700,
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        _isLogin ? 'Entrar' : 'Registrarse',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            // Link para cambiar entre login/registro
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? '¿No tienes cuenta? '
                                      : '¿Ya tienes cuenta? ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: isMobile ? 12 : 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isLogin = !_isLogin),
                                  child: Text(
                                    _isLogin ? 'Regístrate' : 'Inicia sesión',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 12 : 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget helper para campos de texto modernos
  Widget _buildModernTextField({
    required String label,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
      onSaved: onSaved,
      keyboardType: keyboardType,
    );
  }
}
