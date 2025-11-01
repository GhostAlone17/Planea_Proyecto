/// Modelo que representa una sesión de quiz activa o completada
class QuizSessionModel {
  final String sessionId;
  final String userId;
  final String categoryId;
  final List<String> questionIds;
  final List<int> questionOrder;
  final int totalQuestions;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'en_progreso', 'completado', 'abandonado'
  final int? score;
  final Map<int, int> answers; // índice -> respuesta seleccionada

  QuizSessionModel({
    required this.sessionId,
    required this.userId,
    required this.categoryId,
    required this.questionIds,
    required this.questionOrder,
    required this.totalQuestions,
    required this.startDate,
    this.endDate,
    this.status = 'en_progreso',
    this.score,
    Map<int, int>? answers,
  }) : answers = answers ?? {};

  /// Calcula el progreso actual (0-100)
  double get progressPercentage {
    if (totalQuestions == 0) return 0;
    return (answers.length / totalQuestions * 100);
  }

  /// Indica si el quiz está completo
  bool get isCompleted => status == 'completado';

  /// Convierte el modelo a Map para Firestore
  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'userId': userId,
        'categoryId': categoryId,
        'questionIds': questionIds,
        'questionOrder': questionOrder,
        'totalQuestions': totalQuestions,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'score': score,
        'answers': answers,
      };

  /// Crea un modelo desde datos de Firestore
  factory QuizSessionModel.fromMap(Map<String, dynamic> map) => QuizSessionModel(
        sessionId: map['sessionId'],
        userId: map['userId'],
        categoryId: map['categoryId'],
        questionIds: List<String>.from(map['questionIds']),
        questionOrder: List<int>.from(map['questionOrder']),
        totalQuestions: map['totalQuestions'],
        startDate: map['startDate'] is DateTime ? map['startDate'] : DateTime.parse(map['startDate']),
        endDate: map['endDate'] != null 
            ? (map['endDate'] is DateTime ? map['endDate'] : DateTime.parse(map['endDate']))
            : null,
        status: map['status'] ?? 'en_progreso',
        score: map['score'],
        answers: Map<int, int>.from(
          (map['answers'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(int.parse(k), v as int)),
        ),
      );

  /// Copia el modelo con valores opcionales
  QuizSessionModel copyWith({
    String? sessionId,
    String? userId,
    String? categoryId,
    List<String>? questionIds,
    List<int>? questionOrder,
    int? totalQuestions,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? score,
    Map<int, int>? answers,
  }) =>
      QuizSessionModel(
        sessionId: sessionId ?? this.sessionId,
        userId: userId ?? this.userId,
        categoryId: categoryId ?? this.categoryId,
        questionIds: questionIds ?? this.questionIds,
        questionOrder: questionOrder ?? this.questionOrder,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        score: score ?? this.score,
        answers: answers ?? this.answers,
      );
}
