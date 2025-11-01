import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../services/authentication_service.dart';
import '../models/category_model.dart';
import 'quiz_screen.dart';
import 'user_profile_modal.dart';

/// Pantalla que muestra las categorías disponibles del test PLANEA
class CategoriesScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const CategoriesScreen({super.key, this.onLogout});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _quizService = QuizService();
  late Future<List<CategoryModel>> _futureCategories;
  String? _gradoNombre;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      // Obtener el grado del usuario actual
      final authService = AuthenticationService();
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists) {
          _gradoNombre = doc['gradoNombre'] as String?;
        }
      }

      // Cargar categorías filtradas por grado
      if (_gradoNombre != null && _gradoNombre!.isNotEmpty) {
        _futureCategories = _quizService.getCategoriesByGrade(_gradoNombre!);
        print('📚 Cargando categorías para grado: $_gradoNombre');
      } else {
        _futureCategories = _quizService.getCategories();
        print('📚 Cargando todas las categorías (sin filtro de grado)');
      }
      
      setState(() {});
    } catch (e) {
      print('Error cargando grado del usuario: $e');
      _futureCategories = _quizService.getCategories();
      if (mounted) setState(() {});
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService().logout();
              widget.onLogout?.call();
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PLANEA - Matemáticas'),
            if (_gradoNombre != null)
              Text(
                '📚 $_gradoNombre',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                showDialog(
                  context: context,
                  builder: (_) => const UserProfileModal(),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.account_circle),
            ),
          )
        ],
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            itemBuilder: (context, index) {
              final c = categories[index];
              return Card(
                child: ListTile(
                  title: Text(c.nombre),
                  subtitle: Text(c.descripcion ?? 'Práctica de ${c.nombre}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    // Iniciar o continuar test
                    final progress = await _quizService.startQuiz(c.id);
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(category: c, initialProgress: progress),
                      ),
                    );
                    setState(() {}); // Por si cambia el progreso
                  },
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: categories.length,
          );
        },
      ),
    );
  }
}
