import 'dart:math';

import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/quiz_progress_model.dart';
import '../services/quiz_service.dart';
import 'results_screen.dart';

/// Pantalla que ejecuta el test de una categoría
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
  int? _selectedIndex; // índice respecto a opciones originales

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress;
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final q = await _quizService.getCurrentQuestion(_progress);
    if (!mounted) return;
    setState(() {
      _currentQuestion = q;
      _optionOrder = [0, 1, 2, 3]..shuffle(_rand); // aleatorizar opciones
      _selectedIndex = null;
    });
  }

  Future<void> _next() async {
    if (_selectedIndex == null) return;
    _progress = await _quizService.answerAndNext(_progress, _selectedIndex!);
    final q = await _quizService.getCurrentQuestion(_progress);
    if (!mounted) return;
    if (q == null) {
      // Finalizó
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
      setState(() {
        _currentQuestion = q;
        _optionOrder = [0, 1, 2, 3]..shuffle(_rand);
        _selectedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    return Scaffold(
      appBar: AppBar(
        title: Text('Test: ${widget.category.nombre}'),
      ),
      body: q == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pregunta ${_progress.currentIndex + 1} de ${_progress.total}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    q.pregunta,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  ..._optionOrder.map((optIdx) {
                    final optionText = q.opciones[optIdx];
                    return RadioListTile<int>(
                      value: optIdx,
                      groupValue: _selectedIndex,
                      title: Text(optionText),
                      onChanged: (val) => setState(() => _selectedIndex = val),
                    );
                  }),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedIndex == null ? null : _next,
                          child: Text(_progress.currentIndex + 1 == _progress.total
                              ? 'Finalizar'
                              : 'Siguiente'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
