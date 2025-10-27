/// Modelo que representa a un usuario del sistema
/// Puede ser: Alumno, Padre de Familia o Docente
class UserModel {
  /// Identificador único del usuario
  final String id;
  
  /// Nombre completo del usuario
  final String nombre;
  
  /// Correo electrónico para autenticación
  final String email;
  
  /// Tipo de usuario: 'alumno', 'padre', 'docente'
  final String tipoUsuario;
  
  /// URL de la foto de perfil (opcional)
  final String? fotoPerfil;
  
  /// Token de notificaciones push para Firebase Cloud Messaging
  final String? tokenNotificacion;
  
  /// Fecha de registro del usuario
  final DateTime fechaRegistro;
  
  /// Indica si el usuario está activo en el sistema
  final bool activo;
  
  /// Para padres de familia: lista de IDs de sus hijos
  final List<String>? hijosIds;
  
  /// Para alumnos: ID del grado o curso
  final String? gradoId;

  /// Constructor principal del modelo de usuario
  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipoUsuario,
    this.fotoPerfil,
    this.tokenNotificacion,
    required this.fechaRegistro,
    this.activo = true,
    this.hijosIds,
    this.gradoId,
  });

  /// Convierte el modelo a un Map para guardarlo en base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'tipoUsuario': tipoUsuario,
      'fotoPerfil': fotoPerfil,
      'tokenNotificacion': tokenNotificacion,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'activo': activo,
      'hijosIds': hijosIds,
      'gradoId': gradoId,
    };
  }

  /// Crea una instancia de UserModel desde un Map (base de datos)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      tipoUsuario: map['tipoUsuario'] ?? '',
      fotoPerfil: map['fotoPerfil'],
      tokenNotificacion: map['tokenNotificacion'],
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
      activo: map['activo'] ?? true,
      hijosIds: map['hijosIds'] != null 
          ? List<String>.from(map['hijosIds']) 
          : null,
      gradoId: map['gradoId'],
    );
  }

  /// Crea una copia del usuario con campos modificados
  UserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? tipoUsuario,
    String? fotoPerfil,
    String? tokenNotificacion,
    DateTime? fechaRegistro,
    bool? activo,
    List<String>? hijosIds,
    String? gradoId,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      tokenNotificacion: tokenNotificacion ?? this.tokenNotificacion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
      hijosIds: hijosIds ?? this.hijosIds,
      gradoId: gradoId ?? this.gradoId,
    );
  }
}
