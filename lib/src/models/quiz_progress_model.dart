/// Modelo que almacena el avance del usuario en un test
class QuizProgressModel {
  /// ID de la categoría del test
  final String categoryId;

  /// Índice de la pregunta actual (0-based)
  final int currentIndex;

  /// Número total de preguntas de este intento
  final int total;

  /// Respuestas del usuario por índice de pregunta (null si no respondida)
  final List<int?> respuestas;

  const QuizProgressModel({
    required this.categoryId,
    required this.currentIndex,
    required this.total,
    required this.respuestas,
  });

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'currentIndex': currentIndex,
        'total': total,
        'respuestas': respuestas,
      };

  factory QuizProgressModel.fromMap(Map<String, dynamic> map) => QuizProgressModel(
        categoryId: map['categoryId'],
        currentIndex: map['currentIndex'],
        total: map['total'],
        respuestas: List<int?>.from(map['respuestas']),
      );

  QuizProgressModel copyWith({
    String? categoryId,
    int? currentIndex,
    int? total,
    List<int?>? respuestas,
  }) => QuizProgressModel(
        categoryId: categoryId ?? this.categoryId,
        currentIndex: currentIndex ?? this.currentIndex,
        total: total ?? this.total,
        respuestas: respuestas ?? this.respuestas,
      );
}
