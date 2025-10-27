import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/quiz_progress_model.dart';

/// Servicio que gestiona categorías, preguntas y progreso del test PLANEA
/// - Usa datos locales (mock) por ahora
/// - Persiste el avance con SharedPreferences para poder continuar
class QuizService {
  // Singleton
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final _rand = Random();

  // ===================== DATOS MOCK =====================

  /// Lista de categorías disponibles
  final List<CategoryModel> _categories = const [
    CategoryModel(id: 'algebra', nombre: 'Álgebra'),
    CategoryModel(id: 'geometria', nombre: 'Geometría'),
    CategoryModel(id: 'estadistica', nombre: 'Estadística'),
  ];

  /// Banco de preguntas por categoría
  final Map<String, List<QuestionModel>> _questionsByCategory = {
    'algebra': [
      QuestionModel(
        id: 'alg1',
        categoryId: 'algebra',
        pregunta: '¿Cuál es el valor de x en: 2x + 3 = 11?',
        opciones: ['3', '4', '5', '8'],
        indiceCorrecto: 1,
        explicacion: '2x = 8, por lo tanto x = 4.',
      ),
      QuestionModel(
        id: 'alg2',
        categoryId: 'algebra',
        pregunta: 'Simplifica: (x^2 * x^3)',
        opciones: ['x^5', 'x^6', 'x^8', 'x^9'],
        indiceCorrecto: 0,
        explicacion: 'Se suman exponentes: 2 + 3 = 5.',
      ),
    ],
    'geometria': [
      QuestionModel(
        id: 'geo1',
        categoryId: 'geometria',
        pregunta: 'La suma de los ángulos interiores de un triángulo es:',
        opciones: ['90°', '120°', '180°', '360°'],
        indiceCorrecto: 2,
      ),
      QuestionModel(
        id: 'geo2',
        categoryId: 'geometria',
        pregunta: 'El área de un rectángulo 5x3 es:',
        opciones: ['8', '15', '16', '30'],
        indiceCorrecto: 1,
      ),
    ],
    'estadistica': [
      QuestionModel(
        id: 'est1',
        categoryId: 'estadistica',
        pregunta: '¿Qué medida es más sensible a valores extremos?',
        opciones: ['Media', 'Mediana', 'Moda', 'Rango intercuartílico'],
        indiceCorrecto: 0,
      ),
      QuestionModel(
        id: 'est2',
        categoryId: 'estadistica',
        pregunta: 'Si todos los datos se multiplican por 3, la varianza se multiplica por:',
        opciones: ['3', '6', '9', '12'],
        indiceCorrecto: 2,
      ),
    ],
  };

  // ===================== API PÚBLICA =====================

  /// Devuelve las categorías disponibles
  Future<List<CategoryModel>> getCategories() async {
    return _categories;
  }

  /// Devuelve las preguntas para una categoría
  List<QuestionModel> getQuestions(String categoryId) {
    return List<QuestionModel>.from(_questionsByCategory[categoryId] ?? []);
  }

  /// Inicia un test para una categoría (crea orden aleatorio y progreso)
  Future<QuizProgressModel> startQuiz(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();

    // Si ya existe progreso previo, lo cargamos para continuar
    final existing = await loadProgress(categoryId);
    if (existing != null) return existing;

    final questions = getQuestions(categoryId);
    if (questions.isEmpty) {
      throw StateError('No hay preguntas para la categoría: $categoryId');
    }

    // Orden aleatorio de preguntas
    final order = List<int>.generate(questions.length, (i) => i)..shuffle(_rand);

    // Guardar orden y progreso inicial
    await prefs.setStringList(_keyOrder(categoryId), order.map((e) => e.toString()).toList());
    await prefs.setInt(_keyIndex(categoryId), 0);
    await prefs.setStringList(_keyAnswers(categoryId), List.filled(questions.length, '').toList());

    return QuizProgressModel(
      categoryId: categoryId,
      currentIndex: 0,
      total: questions.length,
      respuestas: List<int?>.filled(questions.length, null),
    );
  }

  /// Carga el progreso guardado si existe
  Future<QuizProgressModel?> loadProgress(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList(_keyOrder(categoryId));
    final index = prefs.getInt(_keyIndex(categoryId));
    final answers = prefs.getStringList(_keyAnswers(categoryId));

    if (order == null || index == null || answers == null) return null;

    return QuizProgressModel(
      categoryId: categoryId,
      currentIndex: index,
      total: answers.length,
      respuestas: answers.map((a) => a.isEmpty ? null : int.parse(a)).toList(),
    );
  }

  /// Obtiene la pregunta actual según el progreso y el orden aleatorio
  Future<QuestionModel?> getCurrentQuestion(QuizProgressModel progress) async {
    final order = await _getOrder(progress.categoryId);
    if (order == null || progress.currentIndex >= order.length) return null;
    final questions = getQuestions(progress.categoryId);
    final qIndex = order[progress.currentIndex];
    return questions[qIndex];
  }

  /// Registra una respuesta y avanza a la siguiente pregunta
  Future<QuizProgressModel> answerAndNext(
    QuizProgressModel progress,
    int selectedIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final answers = List<String>.from(
      prefs.getStringList(_keyAnswers(progress.categoryId)) ?? [],
    );

    if (answers.isEmpty) {
      // Si no hay respuestas, inicializamos
      answers.addAll(List.filled(progress.total, ''));
    }

    answers[progress.currentIndex] = selectedIndex.toString();
    await prefs.setStringList(_keyAnswers(progress.categoryId), answers);

    final nextIndex = progress.currentIndex + 1;
    await prefs.setInt(_keyIndex(progress.categoryId), nextIndex);

    return progress.copyWith(currentIndex: nextIndex, respuestas: _toIntList(answers));
  }

  /// Calcula el puntaje total y limpia el progreso
  Future<int> finishAndScore(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final answers = prefs.getStringList(_keyAnswers(categoryId));
    final order = await _getOrder(categoryId);
    if (answers == null || order == null) return 0;

    final questions = getQuestions(categoryId);
    int score = 0;
    for (int i = 0; i < order.length; i++) {
      final q = questions[order[i]];
      final ans = answers[i].isEmpty ? null : int.parse(answers[i]);
      if (ans != null && ans == q.indiceCorrecto) score++;
    }

    await clearProgress(categoryId);
    return score;
  }

  /// Limpia el progreso almacenado para una categoría
  Future<void> clearProgress(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrder(categoryId));
    await prefs.remove(_keyIndex(categoryId));
    await prefs.remove(_keyAnswers(categoryId));
  }

  // ===================== HELPERS =====================

  List<int?> _toIntList(List<String> items) => items
      .map((a) => a.isEmpty ? null : int.tryParse(a))
      .toList(growable: false);

  Future<List<int>?> _getOrder(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyOrder(categoryId));
    return list?.map((e) => int.parse(e)).toList();
  }

  String _keyOrder(String categoryId) => 'quiz_order_$categoryId';
  String _keyIndex(String categoryId) => 'quiz_index_$categoryId';
  String _keyAnswers(String categoryId) => 'quiz_answers_$categoryId';
}
