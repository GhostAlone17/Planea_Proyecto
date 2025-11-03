/// Modelo para Categorías de Matemáticas
class CategoryModelV2 {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono; // emoji o URL
  final int orden; // para ordenar en la UI
  final bool activa;
  final DateTime fechaCreacion;

  CategoryModelV2({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.orden,
    this.activa = true,
    required this.fechaCreacion,
  });

  // Categorías predefinidas de Matemáticas PLANEA
  static List<CategoryModelV2> categoriasDefault() {
    return [
      CategoryModelV2(
        id: 'algebra',
        nombre: 'Álgebra',
        descripcion: 'Expresiones algebraicas, ecuaciones y sistemas',
        icono: '�',
        orden: 1,
        fechaCreacion: DateTime.now(),
      ),
      CategoryModelV2(
        id: 'trigonometria',
        nombre: 'Trigonometría',
        descripcion: 'Funciones trigonométricas y ángulos',
        icono: '�',
        orden: 2,
        fechaCreacion: DateTime.now(),
      ),
      CategoryModelV2(
        id: 'geometria',
        nombre: 'Geometría',
        descripcion: 'Figuras, áreas, volúmenes y propiedades',
        icono: '�',
        orden: 3,
        fechaCreacion: DateTime.now(),
      ),
      CategoryModelV2(
        id: 'estadistica',
        nombre: 'Estadística',
        descripcion: 'Datos, gráficos, probabilidad y medidas',
        icono: '📊',
        orden: 4,
        fechaCreacion: DateTime.now(),
      ),
      CategoryModelV2(
        id: 'calculo',
        nombre: 'Cálculo',
        descripcion: 'Límites, derivadas e integrales',
        icono: '📈',
        orden: 5,
        fechaCreacion: DateTime.now(),
      ),
      CategoryModelV2(
        id: 'logica',
        nombre: 'Lógica Matemática',
        descripcion: 'Proposiciones, conjuntos y operaciones',
        icono: '🧩',
        orden: 6,
        fechaCreacion: DateTime.now(),
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'orden': orden,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory CategoryModelV2.fromMap(Map<String, dynamic> map) {
    return CategoryModelV2(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      icono: map['icono'] ?? '📚',
      orden: map['orden'] ?? 0,
      activa: map['activa'] ?? true,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }

  CategoryModelV2 copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? icono,
    int? orden,
    bool? activa,
    DateTime? fechaCreacion,
  }) {
    return CategoryModelV2(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
