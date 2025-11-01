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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _email = '';
  String _password = '';
  String _nombre = '';
  bool _isLogin = true;
  bool _showPassword = false;
  String _tipoUsuario = 'alumno'; // ✨ NUEVO: Por defecto alumno
  String _gradoNombre = 'Primaria'; // ✨ NUEVO: Grado para alumnos
  bool _isHoveringLink = false; // ✨ NUEVO: Para efecto hover del enlace

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() => _isLogin = !_isLogin);
    _animationController.reset();
    _animationController.forward();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (!mounted) return;

    final authService = context.read<AuthenticationService>();

    bool success = false;
    String errorMessage = 'Error desconocido';

    if (_isLogin) {
      success = await authService.login(
        email: _email,
        password: _password,
      );
      
      if (!success) {
        // Analizar tipo de error
        if (authService.errorMessage?.contains('user-not-found') ?? false) {
          errorMessage = '❌ Usuario no encontrado. Verifica tu correo.';
        } else if (authService.errorMessage?.contains('wrong-password') ?? false) {
          errorMessage = '❌ Usuario y/o Contraseña Incorrectos';
        } else if (authService.errorMessage?.contains('invalid-email') ?? false) {
          errorMessage = '❌ Correo electrónico inválido';
        } else if (authService.errorMessage?.contains('too-many-requests') ?? false) {
          errorMessage = '⏳ Demasiados intentos. Intenta más tarde.';
        } else if (authService.errorMessage?.contains('Solicitud pendiente de aprobación') ?? false) {
          errorMessage = '⏳ Tu solicitud está pendiente de aprobación por un administrador';
        } else {
          errorMessage = authService.errorMessage ?? 'Error al iniciar sesión';
        }
      }
    } else {
      // ✨ AUTOREGISTRO: Pasar tipoUsuario y gradoNombre
      success = await authService.register(
        email: _email,
        password: _password,
        displayName: _nombre,
        tipoUsuario: _tipoUsuario,
        gradoNombre: _tipoUsuario == 'alumno' ? _gradoNombre : null,
        mantenerSesion: false,
      );
      
      if (!success) {
        if (authService.errorMessage?.contains('email-already-in-use') ?? false) {
          errorMessage = '❌ Este correo ya está registrado';
        } else if (authService.errorMessage?.contains('weak-password') ?? false) {
          errorMessage = '❌ La contraseña es muy débil';
        } else {
          errorMessage = authService.errorMessage ?? 'Error al registrarse';
        }
      }
    }

    if (!mounted) return;

    if (success) {
      if (mounted) {
        if (_isLogin) {
          DialogHelper.showSuccess(context, '¡Bienvenido!');
          widget.onLogin?.call();
        } else if (_tipoUsuario == 'maestro') {
          // ✨ NUEVO: Diálogo especial para maestros con instrucciones
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('✅ Solicitud Enviada'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu registro ha sido enviado para validación.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '📋 Próximos pasos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Un administrador revisará tu solicitud\n'
                    '2. Recibirás confirmación de aprobación\n'
                    '3. Luego podrás iniciar sesión\n\n'
                    '⏳ Esto puede tomar hasta 24 horas',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '💡 Mientras esperas, cierra esta app y vuelve más tarde para intentar iniciar sesión.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        } else {
          DialogHelper.showSuccess(context, '¡Bienvenido!');
          widget.onLogin?.call();
        }
      }
    } else {
      if (mounted) {
        DialogHelper.showError(context, errorMessage);
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
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
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
                                  
                                  // ✨ NUEVO: Selector de tipo de usuario
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _tipoUsuario,
                                        isExpanded: true,
                                        items: [
                                          DropdownMenuItem(
                                            value: 'alumno',
                                            child: Row(
                                              children: [
                                                Icon(Icons.school, 
                                                  color: Colors.blue.shade600,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Alumno'),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'maestro',
                                            child: Row(
                                              children: [
                                                Icon(Icons.person_outline,
                                                  color: Colors.orange.shade600,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Maestro'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() => _tipoUsuario = value ?? 'alumno');
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  // ✨ NUEVO: Mensaje informativo para maestros
                                  if (_tipoUsuario == 'maestro')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.orange.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                              color: Colors.orange.shade700,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Tu registro será validado por un administrador',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // ✨ NUEVO: Selector de grado para alumnos
                                  if (_tipoUsuario == 'alumno')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _gradoNombre,
                                                isExpanded: true,
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 'Primaria',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.school, 
                                                          color: Colors.blue.shade500,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        const Text('📚 Primaria'),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Secundaria',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.school_outlined, 
                                                          color: Colors.purple.shade500,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        const Text('📖 Secundaria'),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Preparatoria',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.auto_stories, 
                                                          color: Colors.amber.shade600,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        const Text('📕 Preparatoria'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() => _gradoNombre = value ?? 'Primaria');
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.info_outline,
                                                  color: Colors.blue.shade600,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Solo verás exámenes de tu grado',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue.shade600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                              validator: (v) => _isLogin 
                                ? Validators.passwordLogin(v)
                                : Validators.password(v),
                              onSaved: (v) => _password = v ?? '',
                            ),
                            const SizedBox(height: 24),

                            // Botón de envío
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: authService.isLoading
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isLogin ? 'Iniciando sesión...' : 'Registrando...',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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
                                MouseRegion(
                                  onEnter: (_) {
                                    setState(() => _isHoveringLink = true);
                                  },
                                  onExit: (_) {
                                    setState(() => _isHoveringLink = false);
                                  },
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _toggleAuthMode,
                                    child: Text(
                                      _isLogin ? 'Regístrate' : 'Inicia sesión',
                                      style: TextStyle(
                                        color: _isHoveringLink 
                                            ? Colors.green.shade900
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 12 : 13,
                                        decoration: TextDecoration.underline,
                                      ),
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
