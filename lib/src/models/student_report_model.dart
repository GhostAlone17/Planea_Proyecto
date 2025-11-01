/// Modelo para Reportes de Desempeño del Estudiante
class StudentReportModel {
  final String id;
  final String userId; // ID del estudiante
  final String userName; // Nombre del estudiante
  final String userEmail; // Email del estudiante
  
  // Estadísticas generales
  final int totalTestsRealizados;
  final int totalAciertos;
  final int totalIntentos;
  final double promedioGeneral; // % de aciertos promedio
  
  // Por categoría
  final Map<String, CategoryPerformance> desempenoPorCategoria;
  
  // Temporales
  final DateTime fechaUltimoTest;
  final DateTime fechaReporte;

  StudentReportModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.totalTestsRealizados = 0,
    this.totalAciertos = 0,
    this.totalIntentos = 0,
    this.promedioGeneral = 0.0,
    Map<String, CategoryPerformance>? desempenoPorCategoria,
    required this.fechaUltimoTest,
    required this.fechaReporte,
  }) : desempenoPorCategoria = desempenoPorCategoria ?? {};

  // Obtener nivel de desempeño general
  String obtenerNivelDesempenio() {
    if (promedioGeneral >= 80) return 'Excelente';
    if (promedioGeneral >= 60) return 'Bueno';
    if (promedioGeneral >= 40) return 'Regular';
    return 'Necesita Mejorar';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'totalTestsRealizados': totalTestsRealizados,
      'totalAciertos': totalAciertos,
      'totalIntentos': totalIntentos,
      'promedioGeneral': promedioGeneral,
      'desempenoPorCategoria': desempenoPorCategoria
          .map((key, value) => MapEntry(key, value.toMap())),
      'fechaUltimoTest': fechaUltimoTest.toIso8601String(),
      'fechaReporte': fechaReporte.toIso8601String(),
    };
  }

  factory StudentReportModel.fromMap(Map<String, dynamic> map) {
    final desempenio = <String, CategoryPerformance>{};
    if (map['desempenoPorCategoria'] != null) {
      final Map<String, dynamic> categoryMap = map['desempenoPorCategoria'];
      categoryMap.forEach((key, value) {
        desempenio[key] = CategoryPerformance.fromMap(value);
      });
    }

    return StudentReportModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      totalTestsRealizados: map['totalTestsRealizados'] ?? 0,
      totalAciertos: map['totalAciertos'] ?? 0,
      totalIntentos: map['totalIntentos'] ?? 0,
      promedioGeneral: (map['promedioGeneral'] ?? 0.0).toDouble(),
      desempenoPorCategoria: desempenio,
      fechaUltimoTest: DateTime.parse(map['fechaUltimoTest']),
      fechaReporte: DateTime.parse(map['fechaReporte']),
    );
  }
}

/// Modelo para desempeño por categoría individual
class CategoryPerformance {
  final String categoryId;
  final String categoryNombre;
  final int aciertos;
  final int intentos;
  final double porcentaje; // % de aciertos en esta categoría

  CategoryPerformance({
    required this.categoryId,
    required this.categoryNombre,
    this.aciertos = 0,
    this.intentos = 0,
    this.porcentaje = 0.0,
  });

  String obtenerNivelCategoria() {
    if (porcentaje >= 80) return 'Domina';
    if (porcentaje >= 60) return 'Competente';
    if (porcentaje >= 40) return 'Desarrollo';
    return 'Inicio';
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryNombre': categoryNombre,
      'aciertos': aciertos,
      'intentos': intentos,
      'porcentaje': porcentaje,
    };
  }

  factory CategoryPerformance.fromMap(Map<String, dynamic> map) {
    return CategoryPerformance(
      categoryId: map['categoryId'] ?? '',
      categoryNombre: map['categoryNombre'] ?? '',
      aciertos: map['aciertos'] ?? 0,
      intentos: map['intentos'] ?? 0,
      porcentaje: (map['porcentaje'] ?? 0.0).toDouble(),
    );
  }
}
