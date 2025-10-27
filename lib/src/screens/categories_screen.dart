import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../models/category_model.dart';
import 'quiz_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _futureCategories = _quizService.getCategories();
  }

  void _logout() {
    AuthService().logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLANEA - Matemáticas'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
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
