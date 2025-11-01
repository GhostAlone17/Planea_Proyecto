/// Modelo que representa una categoría/tema del examen PLANEA
/// Ejemplos: Álgebra, Geometría, Trigonometría, Estadística
class CategoryModel {
  /// ID único de la categoría
  final String id;

  /// Nombre visible de la categoría
  final String nombre;

  /// Descripción (opcional)
  final String? descripcion;

  /// Número total estimado de reactivos (si se conoce)
  final int? totalReactivos;

  /// ✨ NUEVO: Grado para el cual es esta categoría ('Primaria', 'Secundaria', 'Preparatoria')
  final String? grado;

  const CategoryModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.totalReactivos,
    this.grado,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'totalReactivos': totalReactivos,
        'grado': grado,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    // Asegurar que id sea un String (manejar si viene como int)
    final idValue = map['id'];
    final id = idValue is String ? idValue : (idValue?.toString() ?? '');
    
    return CategoryModel(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      totalReactivos: map['totalReactivos'],
      grado: map['grado'],
    );
  }
}
