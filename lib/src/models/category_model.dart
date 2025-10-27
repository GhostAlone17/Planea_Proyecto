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

  const CategoryModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.totalReactivos,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'totalReactivos': totalReactivos,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'],
        nombre: map['nombre'],
        descripcion: map['descripcion'],
        totalReactivos: map['totalReactivos'],
      );
}
