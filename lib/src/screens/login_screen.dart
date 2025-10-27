import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/auth_service.dart';
import '../utils/dialog_helper.dart';
import '../utils/validators.dart';

/// Pantalla de login y registro
class LoginScreen extends StatefulWidget {
  final VoidCallback? onLogin;
  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _email = '';
  String _password = '';
  String _nombre = '';
  bool _isLogin = true;
  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    bool success = false;
    if (_isLogin) {
      success = await _authService.login(_email, _password);
    } else {
      success = await _authService.register(_nombre, _email, _password);
    }
    setState(() => _loading = false);
    if (success) {
      DialogHelper.showSuccess(context, '¡Bienvenido!');
      widget.onLogin?.call();
    } else {
      DialogHelper.showError(context, 'Credenciales incorrectas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLogin)
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => Validators.required(v, 'Nombre'),
                        onSaved: (v) => _nombre = v ?? '',
                      ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      validator: Validators.email,
                      onSaved: (v) => _email = v ?? '',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      validator: (v) => Validators.password(v),
                      onSaved: (v) => _password = v ?? '',
                      obscureText: true,
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _submit,
                            child: Text(_isLogin ? 'Entrar' : 'Registrarse'),
                          ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión'),
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
}
