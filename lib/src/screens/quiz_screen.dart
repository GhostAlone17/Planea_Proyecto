import 'dart:math';

import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/quiz_progress_model.dart';
import '../services/quiz_service.dart';
import 'results_screen.dart';

/// Pantalla que ejecuta el test de una categoría
/// - Muestra preguntas una por una
/// - Randomiza preguntas y opciones
/// - Guarda progreso automáticamente
/// - Permite pausar/reanudar sin reiniciar
class QuizScreen extends StatefulWidget {
  final CategoryModel category;
  final QuizProgressModel initialProgress;
  const QuizScreen({super.key, required this.category, required this.initialProgress});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _quizService = QuizService();
  final _rand = Random();

  late QuizProgressModel _progress;
  QuestionModel? _currentQuestion;
  List<int> _optionOrder = [0, 1, 2, 3];
  int? _selectedIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress;
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      setState(() => _isLoading = true);
      final q = await _quizService.getCurrentQuestion(_progress);
      if (!mounted) return;
      setState(() {
        _currentQuestion = q;
        _optionOrder = [0, 1, 2, 3]..shuffle(_rand); // aleatorizar opciones
        _selectedIndex = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _next() async {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una respuesta')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      _progress = await _quizService.answerAndNext(_progress, _selectedIndex!);

      final q = await _quizService.getCurrentQuestion(_progress);
      if (!mounted) return;

      if (q == null) {
        // Finalizó el test
        final score = await _quizService.finishAndScore(widget.category.id);
        if (!mounted) return;

        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              category: widget.category,
              total: widget.initialProgress.total,
              correct: score,
            ),
          ),
        );
      } else {
        // Siguiente pregunta
        setState(() {
          _currentQuestion = q;
          _optionOrder = [0, 1, 2, 3]..shuffle(_rand);
          _selectedIndex = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmarSalir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonar Test'),
        content: const Text(
          'Tu progreso será guardado. Podrás continuar después desde donde lo dejaste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final isLastQuestion = _progress.currentIndex + 1 == _progress.total;

    return WillPopScope(
      onWillPop: () async {
        _confirmarSalir();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.category.nombre} - Pregunta ${_progress.currentIndex + 1}/${_progress.total}'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarSalir,
          ),
        ),
        body: q == null || _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Barra de progreso
                  LinearProgressIndicator(
                    value: (_progress.currentIndex + 1) / _progress.total,
                    minHeight: 4,
                  ),

                  // Contenido principal
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Indicador de progreso
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text('${_progress.currentIndex + 1} de ${_progress.total}'),
                                backgroundColor: AppConstants.colorPrimario.withOpacity(0.2),
                              ),
                              if (_progress.respuestas
                                  .where((r) => r != null)
                                  .length >
                                  0)
                                Chip(
                                  label: Text(
                                    '${_progress.respuestas.where((r) => r != null).length} respondidas',
                                  ),
                                  backgroundColor: Colors.green.withOpacity(0.2),
                                ),
                            ],
                          ),

                          const SizedBox(height: AppConstants.paddingLarge),

                          // Pregunta
                          Text(
                            q.pregunta,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                          ),

                          const SizedBox(height: AppConstants.paddingLarge * 2),

                          // Opciones
                          ..._optionOrder.map((optIdx) {
                            final optionText = q.opciones[optIdx];
                            final isSelected = _selectedIndex == optIdx;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.paddingMedium,
                              ),
                              child: InkWell(
                                onTap: () => setState(() => _selectedIndex = optIdx),
                                child: Container(
                                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? AppConstants.colorPrimario
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: isSelected
                                        ? AppConstants.colorPrimario.withOpacity(0.1)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<int>(
                                        value: optIdx,
                                        groupValue: _selectedIndex,
                                        onChanged: (val) =>
                                            setState(() => _selectedIndex = val),
                                      ),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style:
                                              Theme.of(context).textTheme.bodyLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  // Botones de navegación
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedIndex == null
                                ? null
                                : _isLoading
                                    ? null
                                    : _next,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              isLastQuestion ? 'Finalizar' : 'Siguiente',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
