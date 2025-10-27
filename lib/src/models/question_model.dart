/// Modelo que representa un reactivo/pregunta del test PLANEA
class QuestionModel {
  /// ID único del reactivo
  final String id;

  /// ID de la categoría a la que pertenece
  final String categoryId;

  /// Pregunta en texto
  final String pregunta;

  /// Lista de 4 respuestas de opción múltiple
  final List<String> opciones;

  /// Índice de la opción correcta dentro de [opciones]
  final int indiceCorrecto;

  /// Explicación de la respuesta (opcional)
  final String? explicacion;

  /// Dificultad: 1-básico, 2-intermedio, 3-avanzado (opcional)
  final int? dificultad;

  const QuestionModel({
    required this.id,
    required this.categoryId,
    required this.pregunta,
    required this.opciones,
    required this.indiceCorrecto,
    this.explicacion,
    this.dificultad,
  }) : assert(opciones.length == 4, 'Deben existir 4 opciones');

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'pregunta': pregunta,
        'opciones': opciones,
        'indiceCorrecto': indiceCorrecto,
        'explicacion': explicacion,
        'dificultad': dificultad,
      };

  factory QuestionModel.fromMap(Map<String, dynamic> map) => QuestionModel(
        id: map['id'],
        categoryId: map['categoryId'],
        pregunta: map['pregunta'],
        opciones: List<String>.from(map['opciones']),
        indiceCorrecto: map['indiceCorrecto'],
        explicacion: map['explicacion'],
        dificultad: map['dificultad'],
      );
}
