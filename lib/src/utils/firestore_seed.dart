import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para popular Firestore con datos de prueba
/// Ejecutar desde una pantalla de debug o button
class FirestoreSeedData {
  static final _firestore = FirebaseFirestore.instance;

  /// Crea categorías por defecto
  static Future<void> seedCategorias() async {
    try {
      final categorias = [
        {
          'id': 'algebra',
          'nombre': 'Álgebra',
          'descripcion': 'Expresiones y ecuaciones algebraicas',
          'orden': 0,
        },
        {
          'id': 'geometria',
          'nombre': 'Geometría',
          'descripcion': 'Formas, ángulos y espacios',
          'orden': 1,
        },
        {
          'id': 'estadistica',
          'nombre': 'Estadística',
          'descripcion': 'Análisis de datos y probabilidad',
          'orden': 2,
        },
        {
          'id': 'trigonometria',
          'nombre': 'Trigonometría',
          'descripcion': 'Funciones trigonométricas',
          'orden': 3,
        },
        {
          'id': 'calculo',
          'nombre': 'Cálculo',
          'descripcion': 'Límites y derivadas',
          'orden': 4,
        },
      ];

      for (var cat in categorias) {
        await _firestore
            .collection('categorias')
            .doc(cat['id'] as String)
            .set(cat);
      }

      print('✅ Categorías creadas');
    } catch (e) {
      print('❌ Error creando categorías: $e');
    }
  }

  /// Crea reactivos (preguntas) de prueba
  static Future<void> seedReactivos() async {
    try {
      final reactivos = [
        // ÁLGEBRA
        {
          'id': 'alg_001',
          'categoryId': 'algebra',
          'pregunta': '¿Cuál es el valor de x en: 2x + 5 = 13?',
          'opciones': ['2', '3', '4', '5'],
          'respuestaCorrecta': 2,
          'dificultad': 1,
          'explicacion': '2x + 5 = 13 → 2x = 8 → x = 4',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'alg_002',
          'categoryId': 'algebra',
          'pregunta': 'Simplifica: (x² × x³)',
          'opciones': ['x⁵', 'x⁶', 'x⁸', '2x⁵'],
          'respuestaCorrecta': 0,
          'dificultad': 1,
          'explicacion': 'Al multiplicar potencias se suman exponentes: 2 + 3 = 5',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'alg_003',
          'categoryId': 'algebra',
          'pregunta': 'Resuelve: 3x - 7 = 2x + 5',
          'opciones': ['10', '11', '12', '13'],
          'respuestaCorrecta': 2,
          'dificultad': 2,
          'explicacion': '3x - 2x = 5 + 7 → x = 12',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'alg_004',
          'categoryId': 'algebra',
          'pregunta': '¿Cuál es la factorización de x² + 5x + 6?',
          'opciones': ['(x+1)(x+6)', '(x+2)(x+3)', '(x+3)(x+2)', '(x+1)(x+5)'],
          'respuestaCorrecta': 1,
          'dificultad': 2,
          'explicacion': 'Buscamos dos números que multiplicados den 6 y sumados den 5: 2 y 3',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'alg_005',
          'categoryId': 'algebra',
          'pregunta': '¿Cuál es el valor de (2³)²?',
          'opciones': ['32', '64', '128', '256'],
          'respuestaCorrecta': 2,
          'dificultad': 1,
          'explicacion': '(2³)² = 2^(3×2) = 2⁶ = 64',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },

        // GEOMETRÍA
        {
          'id': 'geo_001',
          'categoryId': 'geometria',
          'pregunta': 'La suma de los ángulos interiores de un triángulo es:',
          'opciones': ['90°', '120°', '180°', '360°'],
          'respuestaCorrecta': 2,
          'dificultad': 1,
          'explicacion': 'La suma de los ángulos de un triángulo siempre es 180°',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'geo_002',
          'categoryId': 'geometria',
          'pregunta': '¿Cuál es el área de un rectángulo con base 5 cm y altura 3 cm?',
          'opciones': ['8 cm²', '15 cm²', '16 cm²', '30 cm²'],
          'respuestaCorrecta': 1,
          'dificultad': 1,
          'explicacion': 'Área = base × altura = 5 × 3 = 15 cm²',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'geo_003',
          'categoryId': 'geometria',
          'pregunta': '¿Cuál es la circunferencia de un círculo con radio 4 cm?',
          'opciones': ['8π cm', '16π cm', '8 cm', '16 cm'],
          'respuestaCorrecta': 0,
          'dificultad': 2,
          'explicacion': 'C = 2πr = 2π(4) = 8π cm',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'geo_004',
          'categoryId': 'geometria',
          'pregunta': '¿Cuál es el área de un triángulo con base 6 cm y altura 4 cm?',
          'opciones': ['10 cm²', '12 cm²', '24 cm²', '48 cm²'],
          'respuestaCorrecta': 1,
          'dificultad': 1,
          'explicacion': 'Área = (base × altura) / 2 = (6 × 4) / 2 = 12 cm²',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'geo_005',
          'categoryId': 'geometria',
          'pregunta': 'En un triángulo rectángulo, si a=3 y b=4, ¿cuál es c (hipotenusa)?',
          'opciones': ['5', '6', '7', '25'],
          'respuestaCorrecta': 0,
          'dificultad': 2,
          'explicacion': 'Por Pitágoras: c² = a² + b² = 9 + 16 = 25 → c = 5',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },

        // ESTADÍSTICA
        {
          'id': 'est_001',
          'categoryId': 'estadistica',
          'pregunta': '¿Qué medida es más sensible a valores extremos?',
          'opciones': ['Media', 'Mediana', 'Moda', 'Rango'],
          'respuestaCorrecta': 0,
          'dificultad': 2,
          'explicacion': 'La media se ve afectada por valores muy altos o bajos',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'est_002',
          'categoryId': 'estadistica',
          'pregunta': 'Si los datos son: 2, 4, 6, 8, 10; ¿cuál es la media?',
          'opciones': ['4', '6', '8', '10'],
          'respuestaCorrecta': 1,
          'dificultad': 1,
          'explicacion': 'Media = (2+4+6+8+10)/5 = 30/5 = 6',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
        {
          'id': 'est_003',
          'categoryId': 'estadistica',
          'pregunta': 'En los datos: 1, 2, 2, 3, 4, 4, 4; ¿cuál es la moda?',
          'opciones': ['1', '2', '3', '4'],
          'respuestaCorrecta': 3,
          'dificultad': 1,
          'explicacion': 'La moda es el valor que más se repite. El 4 aparece 3 veces',
          'activa': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'creadoPor': 'admin',
        },
      ];

      for (var reactivo in reactivos) {
        await _firestore
            .collection('reactivos')
            .doc(reactivo['id'] as String)
            .set(reactivo);
      }

      print('✅ ${reactivos.length} Reactivos creados');
    } catch (e) {
      print('❌ Error creando reactivos: $e');
    }
  }

  /// Ejecuta todo el seed
  static Future<void> seedAll() async {
    print('🌱 Iniciando población de datos...');
    await seedCategorias();
    await seedReactivos();
    print('✅ Datos de prueba listos');
  }
}
