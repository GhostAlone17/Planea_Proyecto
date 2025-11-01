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
  /// Filtra solo las categorías que tienen al menos una pregunta
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

      // Obtener todos los categoryIds disponibles en reactivos
      final reactivosSnapshot = await _firestore
          .collection('reactivos')
          .where('activa', isEqualTo: true)
          .get();
      
      final availableCategoryIds = <String>{};
      for (var doc in reactivosSnapshot.docs) {
        final catId = doc['categoryId'];
        if (catId != null) {
          // Normalizar a minúsculas para comparación
          availableCategoryIds.add(catId.toString().toLowerCase());
        }
      }

      print('✅ Categorías con reactivos activos: $availableCategoryIds');

      // Retornar solo las categorías que tienen preguntas
      final filteredCategories = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final id = data['id'] is String 
                ? data['id'] 
                : (data['id']?.toString() ?? doc.id);
            // Comparar en minúsculas
            return availableCategoryIds.contains(id.toLowerCase());
          })
          .map((doc) {
            final data = doc.data();
            // Asegurar que id sea un String
            final id = data['id'] is String 
                ? data['id'] 
                : (data['id']?.toString() ?? doc.id);
            
            return CategoryModel(
              id: id,
              nombre: data['nombre'] ?? 'Sin nombre',
              descripcion: data['descripcion'],
              grado: data['grado'],
            );
          })
          .toList();

      if (filteredCategories.isEmpty) {
        print('⚠️ No hay categorías con reactivos activos');
      }

      return filteredCategories;
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return _crearCategoriasDefault();
    }
  }

  /// ✨ NUEVO: Obtiene categorías filtradas por grado del estudiante
  /// Solo retorna categorías que tienen preguntas activas
  Future<List<CategoryModel>> getCategoriesByGrade(String gradoNombre) async {
    try {
      // Obtener todas las categorías sin filtro en Firestore
      final snapshot = await _firestore
          .collection('categorias')
          .orderBy('orden', descending: false)
          .get();

      print('📚 Total de categorías en Firestore: ${snapshot.docs.length}');
      print('🔍 Buscando categorías para grado: $gradoNombre');

      // Obtener todos los categoryIds disponibles en reactivos
      final reactivosSnapshot = await _firestore
          .collection('reactivos')
          .where('activa', isEqualTo: true)
          .get();
      
      final availableCategoryIds = <String>{};
      for (var doc in reactivosSnapshot.docs) {
        final catId = doc['categoryId'];
        if (catId != null) {
          availableCategoryIds.add(catId.toString());
        }
      }

      print('✅ Categorías con reactivos activos: $availableCategoryIds');

      // Mostrar qué hay en cada documento
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'];
        final hasReactivos = availableCategoryIds.contains(id);
        print('   - ${data['nombre'] ?? doc.id}: grado=${data['grado'] ?? "NO ESPECIFICADO"}, tiene reactivos=$hasReactivos');
      }

      // Filtrar categorías por: grado Y que tengan preguntas
      final categorias = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final id = data['id'] is String 
                ? data['id'] 
                : (data['id']?.toString() ?? doc.id);
            final grado = data['grado'];
            
            // Incluir si: tiene grado especificado Y tiene preguntas
            return grado == gradoNombre && availableCategoryIds.contains(id);
          })
          .map((doc) {
            final data = doc.data();
            final id = data['id'] is String 
                ? data['id'] 
                : (data['id']?.toString() ?? doc.id);
            
            return CategoryModel(
              id: id,
              nombre: data['nombre'] ?? 'Sin nombre',
              descripcion: data['descripcion'],
              grado: data['grado'],
            );
          })
          .toList();

      print('✅ Categorías filtradas para $gradoNombre con reactivos: ${categorias.length}');

      // Si no hay categorías con ese grado, retornar todas las que tengan preguntas
      if (categorias.isEmpty) {
        print('⚠️ No hay categorías específicas para el grado: $gradoNombre. Mostrando todas con preguntas.');
        return snapshot.docs
            .where((doc) {
              final data = doc.data();
              final id = data['id'] is String 
                  ? data['id'] 
                  : (data['id']?.toString() ?? doc.id);
              return availableCategoryIds.contains(id);
            })
            .map((doc) {
              final data = doc.data();
              final id = data['id'] is String 
                  ? data['id'] 
                  : (data['id']?.toString() ?? doc.id);
              
              return CategoryModel(
                id: id,
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
      CategoryModel(id: 'trigonometria', nombre: 'Trigonometría'),
      CategoryModel(id: 'calculo', nombre: 'Cálculo'),
      CategoryModel(id: 'logica-matematica', nombre: 'Lógica Matemática'),
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
      // Asegurar que categoryId sea un String válido
      if (categoryId.isEmpty) {
        print('❌ categoryId vacío');
        return [];
      }

      print('🔍 Buscando preguntas para categoryId: "$categoryId"');

      // Búsqueda directa: obtener preguntas activas para esta categoría
      final snapshot = await _firestore
          .collection('reactivos')
          .where('categoryId', isEqualTo: categoryId)
          .where('activa', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            print('⏱️ TIMEOUT en Firestore.get()');
            throw Exception('Firestore timeout al obtener reactivos');
          });

      print('📝 Preguntas encontradas (activa=true): ${snapshot.docs.length}');

      // Si no hay preguntas, retornar vacío
      if (snapshot.docs.isEmpty) {
        print('⚠️ No hay preguntas activas para la categoría: "$categoryId"');
        return [];
      }

      final questions = snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Asegurar que categoryId sea un String
            final catId = data['categoryId'] is String 
                ? data['categoryId'] 
                : data['categoryId'].toString();
            
            return QuestionModel(
              id: doc['id'] as String? ?? '',
              categoryId: catId,
              pregunta: data['pregunta'] as String? ?? '',
              opciones: List<String>.from(data['opciones'] ?? []),
              indiceCorrecto: data['respuestaCorrecta'] as int? ?? data['indiceCorrecto'] as int? ?? 0,
              explicacion: data['explicacion'],
              dificultad: data['dificultad'],
            );
          })
          .toList();
      
      print('✅ ${questions.length} preguntas mapeadas correctamente');
      return questions;
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
        print('❌ DEBUG: Verificando preguntas para categoryId="$categoryId"');
        // Buscar cualquier pregunta con este categoryId para debug
        final allReactivos = await _firestore.collection('reactivos').get();
        print('📊 Total de reactivos en Firestore: ${allReactivos.docs.length}');
        print('🔍 Categorías encontradas en reactivos:');
        final categoriesInReactivos = <String>{};
        for (var doc in allReactivos.docs) {
          final catId = doc['categoryId'];
          if (catId != null) {
            categoriesInReactivos.add(catId.toString());
          }
        }
        for (var cat in categoriesInReactivos) {
          print('   - "$cat"');
        }
        throw Exception(
          'No hay preguntas disponibles para esta categoría. '
          'Por favor, contacta al administrador.'
        );
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

      // Guardar orden localmente CON VALIDACIÓN
      print('💾 Guardando quiz en local para categoryId=$categoryId, ${questions.length} preguntas');
      final orderList = order.map((e) => e.toString()).toList();
      print('   Intentando guardar orden: $orderList');
      
      try {
        // IMPORTANTE: En SharedPreferences el método es síncrono pero retorna Future
        final ordenGuardado = await prefs.setStringList(_keyOrder(categoryId), orderList);
        print('   setStringList resultado: $ordenGuardado');
        
        if (!ordenGuardado) {
          print('   ⚠️ ADVERTENCIA: setStringList retornó false (posiblemente por permisos o limitaciones)');
          print('   📌 Continuando de todas formas...');
        }
      } catch (e) {
        print('   ❌ Error CRÍTICO en setStringList: $e');
        print('   📌 Continuando de todas formas (fallback a Firestore)...');
      }
      
      // Verificar que se guardó correctamente (lectura síncrona)
      final ordenVerificacion = prefs.getStringList(_keyOrder(categoryId));
      print('   📋 Verificación immediata: orden en prefs = $ordenVerificacion');
      
      if (ordenVerificacion == null || ordenVerificacion.isEmpty) {
        print('   ⚠️ ADVERTENCIA: No se guardó el orden localmente!');
        print('   📌 Se usará Firestore como fuente de verdad');
      } else {
        print('✅ Orden guardado localmente correctamente');
      }
      
      try {
        final indexGuardado = await prefs.setInt(_keyIndex(categoryId), 0);
        final answersGuardado = await prefs.setStringList(_keyAnswers(categoryId), List.filled(questions.length, '').toList());
        final sessionGuardado = await prefs.setString(_keySessionId(categoryId), sessionId);
        print('   Index: $indexGuardado, Answers: $answersGuardado, SessionId: $sessionGuardado');
        
        if (!indexGuardado || !answersGuardado || !sessionGuardado) {
          print('   ⚠️ ADVERTENCIA: Algunos datos no se guardaron en SharedPreferences');
        } else {
          print('✅ Index, answers, sessionId guardados correctamente');
        }
      } catch (e) {
        print('   ❌ Error guardando otros datos: $e');
      }
      
      // ✨ NUEVA LÓGICA: Guardar seed y optionOrders localmente
      try {
        final seedGuardado = await prefs.setInt(_keyRandomSeed(categoryId), randomSeed);
        final optionsGuardado = await prefs.setString(_keyOptionOrders(categoryId), _encodeOptionOrders(optionOrders));
        print('   Seed: $seedGuardado, OptionOrders: $optionsGuardado');
        
        if (!seedGuardado || !optionsGuardado) {
          print('   ⚠️ ADVERTENCIA: Seed/OptionOrders no se guardaron correctamente');
        } else {
          print('✅ RandomSeed y optionOrders guardados correctamente');
        }
      } catch (e) {
        print('   ❌ Error guardando seed/options: $e');
      }
      
      print('📌 NOTA: Se guardará sesión en Firestore como respaldo (fuente de verdad)');

      // Crear sesión en Firestore CON REINTENTOS
      // Convertir optionOrders a Map<String, dynamic> para Firestore
      final optionOrdersForFirestore = optionOrders.map((k, v) => MapEntry(k.toString(), v));
      
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
              'optionOrders': optionOrdersForFirestore,
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
      print('📋 DEBUG getCurrentQuestion START');
      print('   categoryId="${progress.categoryId}", currentIndex=${progress.currentIndex}');
      
      final order = await _getOrder(progress.categoryId);
      print('   Order guardado: $order');
      
      if (order == null) {
        print('❌ No hay orden guardado en local. Probablemente el quiz no se guardó correctamente.');
        print('   Devolviendo null para que se maneje en la UI');
        return null;
      }
      
      if (progress.currentIndex >= order.length) {
        print('❌ currentIndex (${progress.currentIndex}) >= orden.length (${order.length})');
        return null;
      }

      print('📝 Cargando preguntas...');
      final questions = await getQuestionsFromFirestore(progress.categoryId);
      print('   Preguntas cargadas: ${questions.length}');
      
      if (questions.isEmpty) {
        print('❌ No hay preguntas para la categoría');
        return null;
      }

      final qIndex = order[progress.currentIndex];
      print('   qIndex de orden: $qIndex');
      
      if (qIndex >= questions.length) {
        print('❌ qIndex ($qIndex) >= questions.length (${questions.length})');
        return null;
      }

      final question = questions[qIndex];
      final preguntaPreview = question.pregunta.length > 50 
          ? question.pregunta.substring(0, 50) + '...'
          : question.pregunta;
      print('✅ Pregunta cargada: "$preguntaPreview"');
      return question;
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
      
      if (optionOrdersJson != null) {
        // Encontrado en SharedPreferences
        final optionOrders = _decodeOptionOrders(optionOrdersJson);
        final order = optionOrders[progress.currentIndex] ?? [0, 1, 2, 3];
        print('   ✅ Orden de opciones cargada de SharedPreferences para índice ${progress.currentIndex}: $order');
        return order;
      }
      
      // Fallback: intenta cargar de Firestore
      print('   ⚠️ Orden de opciones NO encontrada en SharedPreferences, intentando Firestore...');
      
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          print('   ❌ Usuario no autenticado para fallback a Firestore');
          return [0, 1, 2, 3];
        }
        
        // Buscar sesión en progreso para esta categoría
        final snapshot = await _firestore
            .collection('quizSessions')
            .doc(userId)
            .collection('sessions')
            .where('categoryId', isEqualTo: progress.categoryId)
            .where('status', isEqualTo: 'en_progreso')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));
        
        if (snapshot.docs.isEmpty) {
          print('   ℹ️ No hay sesión en Firestore, usando orden por defecto');
          return [0, 1, 2, 3];
        }
        
        final sessionData = snapshot.docs.first.data();
        final optionOrdersMap = (sessionData['optionOrders'] as Map?)
            ?.cast<String, dynamic>();
        
        if (optionOrdersMap == null) {
          print('   ℹ️ Sesión no tiene optionOrders, usando orden por defecto');
          return [0, 1, 2, 3];
        }
        
        final currentIndexStr = progress.currentIndex.toString();
        final optionOrder = (optionOrdersMap[currentIndexStr] as List?)
            ?.cast<int>() ?? [0, 1, 2, 3];
        
        print('   ✅ Orden de opciones cargada de Firestore para índice ${progress.currentIndex}: $optionOrder');
        
        // Guardar en SharedPreferences para la próxima vez
        try {
          final optionOrdersJson = _encodeOptionOrders(
            Map.from(optionOrdersMap.map(
              (k, v) => MapEntry(int.parse(k), (v as List).cast<int>()),
            )),
          );
          await prefs.setString(_keyOptionOrders(progress.categoryId), optionOrdersJson);
          print('   ✅ Orden de opciones sincronizada a SharedPreferences');
        } catch (e) {
          print('   ⚠️ No se pudo guardar orden de opciones en SharedPreferences: $e');
        }
        
        return optionOrder;
      } catch (e) {
        print('   ⚠️ Error cargando orden de opciones de Firestore: $e');
        return [0, 1, 2, 3];
      }
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
    // Primero intenta cargar de SharedPreferences (rápido)
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyOrder(categoryId));
    
    if (list != null) {
      print('   ✅ Orden cargada de SharedPreferences');
      return list.map((e) => int.parse(e)).toList();
    }
    
    print('   ⚠️ Orden NO encontrada en SharedPreferences, intentando Firestore...');
    
    // Fallback: intenta cargar de Firestore
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('   ❌ Usuario no autenticado para fallback a Firestore');
        return null;
      }
      
      // Buscar sesión en progreso para esta categoría
      final snapshot = await _firestore
          .collection('quizSessions')
          .doc(userId)
          .collection('sessions')
          .where('categoryId', isEqualTo: categoryId)
          .where('status', isEqualTo: 'en_progreso')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (snapshot.docs.isEmpty) {
        print('   ❌ No hay sesión en progreso en Firestore');
        return null;
      }
      
      final sessionData = snapshot.docs.first.data();
      final order = (sessionData['questionOrder'] as List?)
          ?.cast<int>();
      
      if (order == null) {
        print('   ❌ Sesión en Firestore no tiene questionOrder');
        return null;
      }
      
      print('   ✅ Orden cargada de Firestore: $order');
      
      // Guardar en SharedPreferences para la próxima vez
      try {
        final orderStrings = order.map((e) => e.toString()).toList();
        await prefs.setStringList(_keyOrder(categoryId), orderStrings);
        print('   ✅ Orden sincronizada a SharedPreferences');
      } catch (e) {
        print('   ⚠️ No se pudo guardar orden en SharedPreferences: $e');
      }
      
      return order;
    } catch (e) {
      print('   ❌ Error cargando orden de Firestore: $e');
      return null;
    }
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
        DateTime startDate;
        
        if (sessionData['startDate'] is DateTime) {
          startDate = sessionData['startDate'];
        } else if (sessionData['startDate'] is Timestamp) {
          // Manejar Timestamp de Firestore
          startDate = (sessionData['startDate'] as Timestamp).toDate();
        } else {
          // Intenta parsear como String (fallback)
          try {
            startDate = DateTime.parse(sessionData['startDate'].toString());
          } catch (_) {
            print('⚠️ No se puede parsear startDate: ${sessionData['startDate']}');
            return false;
          }
        }
        
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
  /// Maneja tanto Map<int, List<int>> como Map<String, dynamic> de Firestore
  String _encodeOptionOrders(dynamic optionOrders) {
    try {
      if (optionOrders is String) {
        // Ya está codificado
        return optionOrders;
      }
      
      if (optionOrders is Map) {
        // Convertir Map a string formateado
        final buffer = StringBuffer('{');
        final entries = optionOrders.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          final key = entries[i].key;
          final value = entries[i].value;
          
          // Manejar tanto claves int como String
          final keyStr = key is int ? key.toString() : key;
          
          // Manejar valores que podrían ser List<int> o List<dynamic>
          final valueList = (value is List) 
              ? value.map((v) => v is int ? v : int.tryParse(v.toString()) ?? 0).toList()
              : [];
          
          buffer.write('$keyStr: $valueList');
          if (i < entries.length - 1) {
            buffer.write(', ');
          }
        }
        buffer.write('}');
        return buffer.toString();
      }
      
      return optionOrders.toString();
    } catch (e) {
      print('⚠️ Error codificando optionOrders: $e');
      return '{}';
    }
  }

  /// ✨ NUEVA FUNCIÓN: Decodificar orden de opciones desde string
  Map<int, List<int>> _decodeOptionOrders(String encoded) {
    try {
      // Parsear manualmente (en producción usar jsonDecode)
      final decoded = <int, List<int>>{};
      
      // Formato esperado: {0: [1, 0, 3, 2], 1: [2, 3, 1, 0], ...}
      // o desde Firestore: {0: [1, 0, 3, 2], 1: [2, 3, 1, 0], ...}
      final regex = RegExp(r'(\d+):\s*\[([0-9, ]+)\]');
      for (final match in regex.allMatches(encoded)) {
        final index = int.parse(match.group(1)!);
        final optionsStr = match.group(2)!;
        final options = optionsStr
            .split(',')
            .map((s) => int.tryParse(s.trim()) ?? 0)
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
      print('💾 _loadProgressLocally() para categoryId=$categoryId');
      final prefs = await SharedPreferences.getInstance();
      
      final order = prefs.getStringList(_keyOrder(categoryId));
      print('   order: $order');
      
      final index = prefs.getInt(_keyIndex(categoryId));
      print('   index: $index');
      
      final answers = prefs.getStringList(_keyAnswers(categoryId));
      print('   answers: $answers');

      if (order == null || index == null || answers == null) {
        print('❌ Faltan datos locales');
        return null;
      }

      print('✅ Progreso local recuperado');
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
