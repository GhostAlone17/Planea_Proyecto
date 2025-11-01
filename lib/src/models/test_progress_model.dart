/// Modelo para el Progreso de un Test
/// Guarda dónde se quedó el estudiante
class TestProgressModel {
  final String id;
  final String userId; // ID del estudiante
  final String testId; // ID único del test/sesión
  final List<String> categoryIds; // Categorías del test
  final int totalReactivos; // Total de reactivos en el test
  final int reactivoActual; // En cuál va (0-based)
  final List<int?> respuestas; // Respuestas del estudiante (null si no contesta)
  final List<int> tiemposPorReactivo; // Tiempo en segundos por reactivo
  final bool completado;
  final DateTime fechaInicio;
  final DateTime? fechaFinalizacion;
  final double? calificacion; // % de aciertos

  TestProgressModel({
    required this.id,
    required this.userId,
    required this.testId,
    required this.categoryIds,
    required this.totalReactivos,
    this.reactivoActual = 0,
    List<int?>? respuestas,
    List<int>? tiemposPorReactivo,
    this.completado = false,
    required this.fechaInicio,
    this.fechaFinalizacion,
    this.calificacion,
  })  : respuestas = respuestas ?? List<int?>.filled(totalReactivos, null),
        tiemposPorReactivo = tiemposPorReactivo ?? List<int>.filled(totalReactivos, 0);

  // Contar aciertos
  int obtenerAciertos(List<int> respuestasCorrectas) {
    int aciertos = 0;
    for (int i = 0; i < respuestas.length; i++) {
      if (respuestas[i] != null && respuestas[i] == respuestasCorrectas[i]) {
        aciertos++;
      }
    }
    return aciertos;
  }

  // Calcular porcentaje
  double calcularPorcentaje(List<int> respuestasCorrectas) {
    int aciertos = obtenerAciertos(respuestasCorrectas);
    return (aciertos / totalReactivos) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'testId': testId,
      'categoryIds': categoryIds,
      'totalReactivos': totalReactivos,
      'reactivoActual': reactivoActual,
      'respuestas': respuestas,
      'tiemposPorReactivo': tiemposPorReactivo,
      'completado': completado,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFinalizacion': fechaFinalizacion?.toIso8601String(),
      'calificacion': calificacion,
    };
  }

  factory TestProgressModel.fromMap(Map<String, dynamic> map) {
    return TestProgressModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      testId: map['testId'] ?? '',
      categoryIds: List<String>.from(map['categoryIds'] ?? []),
      totalReactivos: map['totalReactivos'] ?? 0,
      reactivoActual: map['reactivoActual'] ?? 0,
      respuestas: map['respuestas'] != null 
          ? List<int?>.from(map['respuestas'])
          : null,
      tiemposPorReactivo: map['tiemposPorReactivo'] != null
          ? List<int>.from(map['tiemposPorReactivo'])
          : null,
      completado: map['completado'] ?? false,
      fechaInicio: DateTime.parse(map['fechaInicio']),
      fechaFinalizacion: map['fechaFinalizacion'] != null
          ? DateTime.parse(map['fechaFinalizacion'])
          : null,
      calificacion: map['calificacion']?.toDouble(),
    );
  }

  TestProgressModel copyWith({
    String? id,
    String? userId,
    String? testId,
    List<String>? categoryIds,
    int? totalReactivos,
    int? reactivoActual,
    List<int?>? respuestas,
    List<int>? tiemposPorReactivo,
    bool? completado,
    DateTime? fechaInicio,
    DateTime? fechaFinalizacion,
    double? calificacion,
  }) {
    return TestProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testId: testId ?? this.testId,
      categoryIds: categoryIds ?? this.categoryIds,
      totalReactivos: totalReactivos ?? this.totalReactivos,
      reactivoActual: reactivoActual ?? this.reactivoActual,
      respuestas: respuestas ?? this.respuestas,
      tiemposPorReactivo: tiemposPorReactivo ?? this.tiemposPorReactivo,
      completado: completado ?? this.completado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFinalizacion: fechaFinalizacion ?? this.fechaFinalizacion,
      calificacion: calificacion ?? this.calificacion,
    );
  }
}
