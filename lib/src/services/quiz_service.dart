import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/quiz_progress_model.dart';

/// Servicio que gestiona categorías, preguntas y progreso del test PLANEA
/// - Obtiene preguntas desde Firestore
/// - Sincroniza progreso con SharedPreferences (caché local)
/// - Guarda reportes en Firestore
class QuizService {
  // Singleton
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ===================== API PÚBLICA =====================

  /// Devuelve las categorías disponibles desde Firestore
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categorias')
          .orderBy('orden', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        // Si no existen, crear las categorías por defecto
        return _crearCategoriasDefault();
      }

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return CategoryModel(
              id: data['id'] ?? doc.id,
              nombre: data['nombre'] ?? 'Sin nombre',
              descripcion: data['descripcion'],
              grado: data['grado'],
            );
          })
          .toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return _crearCategoriasDefault();
    }
  }

  /// ✨ NUEVO: Obtiene categorías filtradas por grado del estudiante
  Future<List<CategoryModel>> getCategoriesByGrade(String gradoNombre) async {
    try {
      // Obtener todas las categorías sin filtro en Firestore
      final snapshot = await _firestore
          .collection('categorias')
          .orderBy('orden', descending: false)
          .get();

      print('📚 Total de categorías en Firestore: ${snapshot.docs.length}');
      print('🔍 Buscando categorías para grado: $gradoNombre');

      // Mostrar qué hay en cada documento
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('   - ${data['nombre'] ?? doc.id}: grado=${data['grado'] ?? "NO ESPECIFICADO"}');
      }

      // Filtrar en código aquellas que tengan el grado especificado
      final categorias = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return CategoryModel(
              id: data['id'] ?? doc.id,
              nombre: data['nombre'] ?? 'Sin nombre',
              descripcion: data['descripcion'],
              grado: data['grado'], // Puede ser null
            );
          })
          .where((cat) => cat.grado == gradoNombre)
          .toList();

      print('✅ Categorías filtradas para $gradoNombre: ${categorias.length}');

      // Si no hay categorías con ese grado, retornar todas
      if (categorias.isEmpty) {
        print('⚠️ No hay categorías específicas para el grado: $gradoNombre. Mostrando todas.');
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              return CategoryModel(
                id: data['id'] ?? doc.id,
                nombre: data['nombre'] ?? 'Sin nombre',
                descripcion: data['descripcion'],
                grado: data['grado'],
              );
            })
            .toList();
      }

      return categorias;
    } catch (e) {
      print('❌ Error obteniendo categorías por grado: $e');
      // Fallback: obtener todas las categorías
      return getCategories();
    }
  }

  /// Crea categorías por defecto si no existen
  Future<List<CategoryModel>> _crearCategoriasDefault() async {
    final categoriasPorDefecto = [
      CategoryModel(id: 'algebra', nombre: 'Álgebra'),
      CategoryModel(id: 'geometria', nombre: 'Geometría'),
      CategoryModel(id: 'estadistica', nombre: 'Estadística'),
    ];

    try {
      for (var (index, cat) in categoriasPorDefecto.indexed) {
        await _firestore.collection('categorias').doc(cat.id).set({
          'id': cat.id,
          'nombre': cat.nombre,
          'descripcion': 'Categoría de ${cat.nombre}',
          'orden': index,
        });
      }
    } catch (e) {
      print('⚠️ No se pudieron crear categorías: $e');
    }

    return categoriasPorDefecto;
  }

  /// Obtiene todas las preguntas de una categoría desde Firestore
  Future<List<QuestionModel>> getQuestionsFromFirestore(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('reactivos')
          .where('categoryId', isEqualTo: categoryId)
          .where('activa', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ No hay preguntas para la categoría: $categoryId');
        return [];
      }

      return snapshot.docs
          .map((doc) => QuestionModel(
                id: doc['id'],
                categoryId: doc['categoryId'],
                pregunta: doc['pregunta'],
                opciones: List<String>.from(doc['opciones']),
                indiceCorrecto: doc['respuestaCorrecta'] ?? doc['indiceCorrecto'],
                explicacion: doc['explicacion'],
                dificultad: doc['dificultad'],
              ))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo preguntas: $e');
      return [];
    }
  }

  /// Inicia un test para una categoría
  /// - Obtiene preguntas de Firestore
  /// - Randomiza preguntas con seed determinístico (reproducible)
  /// - Randomiza opciones y guarda el orden
  /// - Guarda sesión en Firestore con reintentos offline
  /// - Guarda progreso localmente
  Future<QuizProgressModel> startQuiz(String categoryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final prefs = await SharedPreferences.getInstance();

      // Verificar si ya existe sesión activa
      final existingSession = await _getOngoingSessionFromFirestore(userId, categoryId);
      if (existingSession != null) {
        return existingSession;
      }

      // Obtener preguntas de Firestore
      final questions = await getQuestionsFromFirestore(categoryId);
      if (questions.isEmpty) {
        throw Exception('No hay preguntas disponibles para esta categoría');
      }

      // ✨ NUEVA LÓGICA: Generar seed determinístico
      final randomSeed = DateTime.now().millisecondsSinceEpoch;
      final random = Random(randomSeed);

      // Randomizar orden de preguntas
      final order = List<int>.generate(questions.length, (i) => i)..shuffle(random);

      // ✨ NUEVA LÓGICA: Generar y guardar orden de opciones para cada pregunta
      final optionOrders = <int, List<int>>{};
      for (int i = 0; i < questions.length; i++) {
        final options = [0, 1, 2, 3];
        options.shuffle(random);
        optionOrders[i] = options;
      }

      // Generar ID de sesión único
      final sessionId = _firestore.collection('dummy').doc().id;

      // Guardar orden localmente
      await prefs.setStringList(_keyOrder(categoryId), order.map((e) => e.toString()).toList());
      await prefs.setInt(_keyIndex(categoryId), 0);
      await prefs.setStringList(_keyAnswers(categoryId), List.filled(questions.length, '').toList());
      await prefs.setString(_keySessionId(categoryId), sessionId);
      
      // ✨ NUEVA LÓGICA: Guardar seed y optionOrders localmente
      await prefs.setInt(_keyRandomSeed(categoryId), randomSeed);
      await prefs.setString(_keyOptionOrders(categoryId), _encodeOptionOrders(optionOrders));

      // Crear sesión en Firestore CON REINTENTOS
      await _executeWithRetry(
        operation: () => _firestore
            .collection('quizSessions')
            .doc(userId)
            .collection('sessions')
            .doc(sessionId)
            .set({
              'sessionId': sessionId,
              'userId': userId,
              'categoryId': categoryId,
              'questionIds': questions.map((q) => q.id).toList(),
              'questionOrder': order,
              'totalQuestions': questions.length,
              'startDate': FieldValue.serverTimestamp(),
              'endDate': null,
              'status': 'en_progreso',
              'score': null,
              'answers': {},
              'randomSeed': randomSeed,
              'optionOrders': optionOrders,
              'lastSyncTime': FieldValue.serverTimestamp(),
              'syncVersion': 1,
            }),
      );

      return QuizProgressModel(
        categoryId: categoryId,
        currentIndex: 0,
        total: questions.length,
        respuestas: List<int?>.filled(questions.length, null),
      );
    } catch (e) {
      print('❌ Error iniciando quiz: $e');
      rethrow;
    }
  }

  /// Obtiene sesión en progreso de Firestore CON VALIDACIONES Y RECUPERACIÓN OFFLINE
  Future<QuizProgressModel?> _getOngoingSessionFromFirestore(
    String userId,
    String categoryId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('quizSessions')
          .doc(userId)
          .collection('sessions')
          .where('categoryId', isEqualTo: categoryId)
          .where('status', isEqualTo: 'en_progreso')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Intenta cargar sesión local si existe
        return await _loadProgressLocally(categoryId);
      }

      final sessionData = snapshot.docs.first.data();
      final sessionId = sessionData['sessionId'];

      // ✨ NUEVA LÓGICA: Validar integridad de sesión
      if (!_isValidSession(sessionData)) {
        print('⚠️ Sesión inválida detectada');
        return null;
      }

      // Cargar progreso local
      final prefs = await SharedPreferences.getInstance();
      final answers = prefs.getStringList(_keyAnswers(categoryId));
      final index = prefs.getInt(_keyIndex(categoryId));

      if (answers == null || index == null) {
        // Si no hay en local, inicializar desde Firestore
        await prefs.setStringList(_keySessionId(categoryId), [sessionId]);
        await prefs.setStringList(_keyAnswers(categoryId), List.filled(sessionData['totalQuestions'], '').toList());
        await prefs.setInt(_keyIndex(categoryId), 0);
        
        // ✨ NUEVA LÓGICA: Guardar seed y optionOrders desde Firestore
        if (sessionData['randomSeed'] != null) {
          await prefs.setInt(_keyRandomSeed(categoryId), sessionData['randomSeed']);
        }
        if (sessionData['optionOrders'] != null) {
          await prefs.setString(
            _keyOptionOrders(categoryId),
            _encodeOptionOrders(sessionData['optionOrders']),
          );
        }

        return QuizProgressModel(
          categoryId: categoryId,
          currentIndex: 0,
          total: sessionData['totalQuestions'],
          respuestas: List<int?>.filled(sessionData['totalQuestions'], null),
        );
      }

      return QuizProgressModel(
        categoryId: categoryId,
        currentIndex: index,
        total: sessionData['totalQuestions'],
        respuestas: answers.map((a) => a.isEmpty ? null : int.tryParse(a)).toList(),
      );
    } catch (e) {
      print('⚠️ Error buscando sesión en Firestore: $e');
      // Intenta cargar desde local como fallback
      return await _loadProgressLocally(categoryId);
    }
  }

  /// Carga el progreso guardado si existe
  Future<QuizProgressModel?> loadProgress(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final order = prefs.getStringList(_keyOrder(categoryId));
      final index = prefs.getInt(_keyIndex(categoryId));
      final answers = prefs.getStringList(_keyAnswers(categoryId));

      if (order == null || index == null || answers == null) {
        // Si no está en local, buscar en Firestore
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          return await _getOngoingSessionFromFirestore(userId, categoryId);
        }
        return null;
      }

      return QuizProgressModel(
        categoryId: categoryId,
        currentIndex: index,
        total: answers.length,
        respuestas: answers.map((a) => a.isEmpty ? null : int.tryParse(a)).toList(),
      );
    } catch (e) {
      print('❌ Error cargando progreso: $e');
      return null;
    }
  }

  /// Obtiene la pregunta actual
  Future<QuestionModel?> getCurrentQuestion(QuizProgressModel progress) async {
    try {
      final order = await _getOrder(progress.categoryId);
      if (order == null || progress.currentIndex >= order.length) return null;

      final questions = await getQuestionsFromFirestore(progress.categoryId);
      if (questions.isEmpty) return null;

      final qIndex = order[progress.currentIndex];
      if (qIndex >= questions.length) return null;

      return questions[qIndex];
    } catch (e) {
      print('❌ Error obteniendo pregunta actual: $e');
      return null;
    }
  }

  /// ✨ NUEVA FUNCIÓN: Obtiene el orden de opciones para la pregunta actual
  Future<List<int>> getOptionOrderForCurrentQuestion(
    QuizProgressModel progress,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final optionOrdersJson = prefs.getString(_keyOptionOrders(progress.categoryId));
      
      if (optionOrdersJson == null) {
        // Si no existe, retornar orden por defecto
        return [0, 1, 2, 3];
      }

      final optionOrders = _decodeOptionOrders(optionOrdersJson);
      return optionOrders[progress.currentIndex] ?? [0, 1, 2, 3];
    } catch (e) {
      print('⚠️ Error obteniendo orden de opciones: $e');
      return [0, 1, 2, 3];
    }
  }

  /// Registra una respuesta y avanza a la siguiente
  /// Sincroniza con Firestore
  /// ✨ MEJORA: Mapea índice visual al índice real usando optionOrders
  Future<QuizProgressModel> answerAndNext(
    QuizProgressModel progress,
    int selectedIndex,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final prefs = await SharedPreferences.getInstance();
      final answers = List<String>.from(
        prefs.getStringList(_keyAnswers(progress.categoryId)) ?? [],
      );

      if (answers.isEmpty) {
        answers.addAll(List.filled(progress.total, ''));
      }

      // ✨ NUEVA LÓGICA: Mapear índice visual al índice real
      final optionOrder = await getOptionOrderForCurrentQuestion(progress);
      final realOptionIndex = optionOrder[selectedIndex];

      answers[progress.currentIndex] = realOptionIndex.toString();
      await prefs.setStringList(_keyAnswers(progress.categoryId), answers);

      // Sincronizar con Firestore CON REINTENTOS
      final sessionId = prefs.getString(_keySessionId(progress.categoryId));
      if (sessionId != null) {
        final order = await _getOrder(progress.categoryId);
        if (order != null && progress.currentIndex < order.length) {
          final questionIndex = order[progress.currentIndex];

          await _executeWithRetry(
            operation: () => _firestore
                .collection('quizSessions')
                .doc(userId)
                .collection('sessions')
                .doc(sessionId)
                .update({
                  'answers.$questionIndex': realOptionIndex,
                  'lastSyncTime': FieldValue.serverTimestamp(),
                }),
          );
        }
      }

      final nextIndex = progress.currentIndex + 1;
      await prefs.setInt(_keyIndex(progress.categoryId), nextIndex);

      return progress.copyWith(
        currentIndex: nextIndex,
        respuestas: _toIntList(answers),
      );
    } catch (e) {
      print('❌ Error guardando respuesta: $e');
      rethrow;
    }
  }

  /// Finaliza el test, calcula puntuación y guarda en Firestore
  Future<int> finishAndScore(String categoryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final prefs = await SharedPreferences.getInstance();
      final answers = prefs.getStringList(_keyAnswers(categoryId));
      final order = await _getOrder(categoryId);
      final sessionId = prefs.getString(_keySessionId(categoryId));

      if (answers == null || order == null || sessionId == null) {
        throw Exception('Datos de sesión incompletos');
      }

      // Obtener preguntas
      final questions = await getQuestionsFromFirestore(categoryId);
      if (questions.isEmpty) throw Exception('No hay preguntas');

      // Calcular puntaje
      int score = 0;
      final answersData = <int, int>{};

      for (int i = 0; i < order.length; i++) {
        final q = questions[order[i]];
        final ans = answers[i].isEmpty ? null : int.tryParse(answers[i]);

        answersData[i] = ans ?? -1;

        if (ans != null && ans == q.indiceCorrecto) {
          score++;
        }
      }

      // Finalizar sesión en Firestore
      final endTime = DateTime.now();
      await _firestore
          .collection('quizSessions')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'endDate': endTime,
        'status': 'completado',
        'score': score,
        'answers': answersData,
      });

      // Actualizar reporte del estudiante
      await _updateStudentReport(userId, categoryId, score, order.length);

      // Limpiar progreso local
      await clearProgress(categoryId);

      return score;
    } catch (e) {
      print('❌ Error finalizando quiz: $e');
      rethrow;
    }
  }

  /// Actualiza el reporte del estudiante en Firestore
  Future<void> _updateStudentReport(
    String userId,
    String categoryId,
    int score,
    int total,
  ) async {
    try {
      final reportRef = _firestore.collection('reportes_estudiantes').doc(userId);
      final reportDoc = await reportRef.get();

      final currentReport = reportDoc.exists ? reportDoc.data() as Map<String, dynamic> : null;

      final totalTests = ((currentReport?['totalTestsRealizados'] ?? 0) as int) + 1;
      final totalHits = ((currentReport?['totalAciertos'] ?? 0) as int) + score;
      final totalAttempts = ((currentReport?['totalIntentos'] ?? 0) as int) + total;
      final newAverage = totalAttempts > 0 ? (totalHits / totalAttempts * 100) : 0.0;

      // Obtener datos del usuario
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      final userName = userDoc.data()?['nombre'] ?? 'Usuario';
      final userEmail = userDoc.data()?['email'] ?? '';

      // Actualizar desempeño por categoría
      final categoryPerformance = currentReport?['desempenoPorCategoria'] as Map<String, dynamic>? ?? {};

      if (categoryPerformance.containsKey(categoryId)) {
        final catData = categoryPerformance[categoryId] as Map<String, dynamic>;
        final oldHits = catData['aciertos'] as int;
        final oldAttempts = catData['intentos'] as int;
        final newCatHits = oldHits + score;
        final newCatAttempts = oldAttempts + total;
        final newCatPercentage = (newCatHits / newCatAttempts * 100);

        categoryPerformance[categoryId] = {
          'categoryId': categoryId,
          'categoryNombre': catData['categoryNombre'],
          'aciertos': newCatHits,
          'intentos': newCatAttempts,
          'porcentaje': newCatPercentage,
        };
      } else {
        // Primera vez en esta categoría
        final categories = await getCategories();
        final categoryName = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => CategoryModel(id: categoryId, nombre: categoryId),
        ).nombre;

        categoryPerformance[categoryId] = {
          'categoryId': categoryId,
          'categoryNombre': categoryName,
          'aciertos': score,
          'intentos': total,
          'porcentaje': (score / total * 100),
        };
      }

      await reportRef.set({
        'id': userId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'totalTestsRealizados': totalTests,
        'totalAciertos': totalHits,
        'totalIntentos': totalAttempts,
        'promedioGeneral': newAverage,
        'desempenoPorCategoria': categoryPerformance,
        'fechaUltimoTest': DateTime.now(),
        'fechaReporte': DateTime.now(),
      });

      print('✅ Reporte actualizado para $userName');
    } catch (e) {
      print('❌ Error actualizando reporte: $e');
    }
  }

  /// Limpia el progreso almacenado para una categoría
  Future<void> clearProgress(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOrder(categoryId));
      await prefs.remove(_keyIndex(categoryId));
      await prefs.remove(_keyAnswers(categoryId));
      await prefs.remove(_keySessionId(categoryId));
      await prefs.remove(_keyRandomSeed(categoryId));
      await prefs.remove(_keyOptionOrders(categoryId));
    } catch (e) {
      print('⚠️ Error limpiando progreso: $e');
    }
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

  /// ✨ NUEVA FUNCIÓN: Validar integridad de sesión
  bool _isValidSession(Map<String, dynamic> sessionData) {
    try {
      // Verificar que tenga los campos requeridos
      if (sessionData['randomSeed'] == null || sessionData['optionOrders'] == null) {
        print('⚠️ Sesión sin datos de aleatoriedad');
        return false;
      }

      // Verificar que la sesión no sea demasiado antigua (> 7 días)
      if (sessionData['startDate'] != null) {
        final startDate = sessionData['startDate'] is DateTime
            ? sessionData['startDate']
            : DateTime.parse(sessionData['startDate'].toString());
        final ageInDays = DateTime.now().difference(startDate).inDays;
        if (ageInDays > 7) {
          print('⚠️ Sesión demasiado antigua ($ageInDays días)');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('⚠️ Error validando sesión: $e');
      return false;
    }
  }

  /// ✨ NUEVA FUNCIÓN: Ejecutar con reintentos y backoff exponencial
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          print('❌ Operación falló después de $maxRetries intentos: $e');
          rethrow;
        }

        print('⚠️ Intento $attempt falló, reintentando en ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        delay *= backoffMultiplier;
      }
    }

    throw Exception('Operación falló después de $maxRetries intentos');
  }

  /// ✨ NUEVA FUNCIÓN: Codificar orden de opciones a string
  String _encodeOptionOrders(Map<int, List<int>> optionOrders) {
    final encoded = optionOrders.map(
      (k, v) => MapEntry(k.toString(), v),
    );
    return encoded.toString(); // En producción usar jsonEncode
  }

  /// ✨ NUEVA FUNCIÓN: Decodificar orden de opciones desde string
  Map<int, List<int>> _decodeOptionOrders(String encoded) {
    try {
      // Parsear manualmente (en producción usar jsonDecode)
      final decoded = <int, List<int>>{};
      
      // Formato esperado: {0: [1, 0, 3, 2], 1: [2, 3, 1, 0], ...}
      final regex = RegExp(r'(\d+):\s*\[([0-9, ]+)\]');
      for (final match in regex.allMatches(encoded)) {
        final index = int.parse(match.group(1)!);
        final options = match.group(2)!
            .split(',')
            .map((s) => int.parse(s.trim()))
            .toList();
        decoded[index] = options;
      }
      
      return decoded;
    } catch (e) {
      print('⚠️ Error decodificando optionOrders: $e');
      return {};
    }
  }

  /// ✨ NUEVA FUNCIÓN: Cargar progreso desde almacenamiento local
  Future<QuizProgressModel?> _loadProgressLocally(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final order = prefs.getStringList(_keyOrder(categoryId));
      final index = prefs.getInt(_keyIndex(categoryId));
      final answers = prefs.getStringList(_keyAnswers(categoryId));

      if (order == null || index == null || answers == null) {
        return null;
      }

      return QuizProgressModel(
        categoryId: categoryId,
        currentIndex: index,
        total: answers.length,
        respuestas: answers.map((a) => a.isEmpty ? null : int.tryParse(a)).toList(),
      );
    } catch (e) {
      print('⚠️ Error cargando progreso local: $e');
      return null;
    }
  }

  // ===================== CLAVES DE ALMACENAMIENTO =====================
  String _keyOrder(String categoryId) => 'quiz_order_$categoryId';
  String _keyIndex(String categoryId) => 'quiz_index_$categoryId';
  String _keyAnswers(String categoryId) => 'quiz_answers_$categoryId';
  String _keySessionId(String categoryId) => 'quiz_sessionid_$categoryId';
  String _keyRandomSeed(String categoryId) => 'quiz_seed_$categoryId';
  String _keyOptionOrders(String categoryId) => 'quiz_options_$categoryId';
}
