/// Modelo para Reactivos (Preguntas del PLANEA)
class ReactiveModel {
  final String id;
  final String categoryId; // ID de la categoría (algebra, trigonometria, etc)
  final String pregunta; // La pregunta
  final List<String> opciones; // 4 opciones de respuesta
  final int respuestaCorrecta; // Índice de la respuesta correcta (0-3)
  final String? explicacion; // Explicación opcional
  final int dificultad; // 1=fácil, 2=medio, 3=difícil
  final bool activa;
  final DateTime fechaCreacion;
  final String creadoPor; // ID del admin que la creó

  ReactiveModel({
    required this.id,
    required this.categoryId,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    this.explicacion,
    this.dificultad = 2,
    this.activa = true,
    required this.fechaCreacion,
    required this.creadoPor,
  });

  // Validar que haya exactamente 4 opciones
  bool esValido() {
    return opciones.length == 4 && 
           respuestaCorrecta >= 0 && 
           respuestaCorrecta < 4 &&
           pregunta.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'pregunta': pregunta,
      'opciones': opciones,
      'respuestaCorrecta': respuestaCorrecta,
      'explicacion': explicacion,
      'dificultad': dificultad,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'creadoPor': creadoPor,
    };
  }

  factory ReactiveModel.fromMap(Map<String, dynamic> map) {
    return ReactiveModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      pregunta: map['pregunta'] ?? '',
      opciones: List<String>.from(map['opciones'] ?? []),
      respuestaCorrecta: map['respuestaCorrecta'] ?? 0,
      explicacion: map['explicacion'],
      dificultad: map['dificultad'] ?? 2,
      activa: map['activa'] ?? true,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      creadoPor: map['creadoPor'] ?? '',
    );
  }

  ReactiveModel copyWith({
    String? id,
    String? categoryId,
    String? pregunta,
    List<String>? opciones,
    int? respuestaCorrecta,
    String? explicacion,
    int? dificultad,
    bool? activa,
    DateTime? fechaCreacion,
    String? creadoPor,
  }) {
    return ReactiveModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      pregunta: pregunta ?? this.pregunta,
      opciones: opciones ?? this.opciones,
      respuestaCorrecta: respuestaCorrecta ?? this.respuestaCorrecta,
      explicacion: explicacion ?? this.explicacion,
      dificultad: dificultad ?? this.dificultad,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      creadoPor: creadoPor ?? this.creadoPor,
    );
  }
}
