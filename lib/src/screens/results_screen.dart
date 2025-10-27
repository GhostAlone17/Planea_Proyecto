import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../models/category_model.dart';

/// Pantalla de resultados del test
class ResultsScreen extends StatelessWidget {
  final CategoryModel category;
  final int total;
  final int correct;
  const ResultsScreen({super.key, required this.category, required this.total, required this.correct});

  @override
  Widget build(BuildContext context) {
    final porcentaje = (correct / total * 100).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              category.nombre,
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('$correct de $total correctas ($porcentaje%)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver a categorías'),
            )
          ],
        ),
      ),
    );
  }
}
