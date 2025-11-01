/// Utilidades para convertir códigos de grado a nombres legibles
/// Mapea valores como '12EMS', 'PREP', etc. a 'Preparatoria'
class GradoUtils {
  /// Mapeo de códigos de grado a nombres legibles
  static const Map<String, String> gradoMap = {
    // Primaria
    '1': 'Primaria',
    '2': 'Primaria',
    '3': 'Primaria',
    '4': 'Primaria',
    '5': 'Primaria',
    '6': 'Primaria',
    
    // Secundaria
    '7': 'Secundaria',
    '8': 'Secundaria',
    '9': 'Secundaria',
    'SEC': 'Secundaria',
    'SECUNDARIA': 'Secundaria',
    
    // Preparatoria
    '10': 'Preparatoria',
    '11': 'Preparatoria',
    '12': 'Preparatoria',
    '12EMS': 'Preparatoria',
    'PREP': 'Preparatoria',
    'PREPARATORIA': 'Preparatoria',
  };

  /// Convierte un código de grado a su nombre legible
  /// Ej: '12EMS' -> 'Preparatoria'
  static String getNombreGrado(String? gradoId) {
    if (gradoId == null || gradoId.isEmpty) {
      return 'Primaria';
    }

    // Intentar búsqueda directa
    if (gradoMap.containsKey(gradoId)) {
      return gradoMap[gradoId]!;
    }

    // Intentar búsqueda case-insensitive
    final upper = gradoId.toUpperCase();
    if (gradoMap.containsKey(upper)) {
      return gradoMap[upper]!;
    }

    // Si contiene 'prep' o similar
    if (upper.contains('PREP')) return 'Preparatoria';
    if (upper.contains('SEC')) return 'Secundaria';
    if (upper.contains('PRIM')) return 'Primaria';

    // Si no coincide, retornar el valor original
    return gradoId;
  }

  /// Obtiene el emoji correspondiente al grado
  static String getEmojiGrado(String? gradoId) {
    final nombre = getNombreGrado(gradoId);
    switch (nombre) {
      case 'Primaria':
        return '🎓';
      case 'Secundaria':
        return '📚';
      case 'Preparatoria':
        return '🎯';
      default:
        return '📖';
    }
  }
}
