/// Modelo que representa una noticia del plantel
/// Las noticias son creadas desde la web-admin y enviadas a la app móvil
class NoticiaModel {
  /// Identificador único de la noticia
  final String id;
  
  /// Título de la noticia
  final String titulo;
  
  /// Contenido completo de la noticia
  final String contenido;
  
  /// URL de la imagen principal de la noticia (opcional)
  final String? imagenUrl;
  
  /// Tipo de noticia: 'general', 'beca', 'suspension', 'evento', 'academica'
  final String tipoNoticia;
  
  /// Destinatarios: 'todos', 'alumnos', 'padres', 'docentes', 'especifico'
  final String destinatarios;
  
  /// Lista de IDs de usuarios específicos (si destinatarios = 'especifico')
  final List<String>? usuariosEspecificos;
  
  /// Fecha y hora de publicación
  final DateTime fechaPublicacion;
  
  /// ID del usuario que creó la noticia (administrador)
  final String autorId;
  
  /// Nombre del autor de la noticia
  final String autorNombre;
  
  /// Indica si la noticia está activa/visible
  final bool activa;
  
  /// Prioridad de la noticia: 'alta', 'media', 'baja'
  final String prioridad;
  
  /// Indica si debe enviarse notificación push
  final bool enviarNotificacion;
  
  /// URL del post de Facebook relacionado (opcional)
  final String? facebookPostUrl;

  /// Constructor principal del modelo de noticia
  NoticiaModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.imagenUrl,
    required this.tipoNoticia,
    required this.destinatarios,
    this.usuariosEspecificos,
    required this.fechaPublicacion,
    required this.autorId,
    required this.autorNombre,
    this.activa = true,
    this.prioridad = 'media',
    this.enviarNotificacion = true,
    this.facebookPostUrl,
  });

  /// Convierte el modelo a un Map para guardarlo en base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'imagenUrl': imagenUrl,
      'tipoNoticia': tipoNoticia,
      'destinatarios': destinatarios,
      'usuariosEspecificos': usuariosEspecificos,
      'fechaPublicacion': fechaPublicacion.toIso8601String(),
      'autorId': autorId,
      'autorNombre': autorNombre,
      'activa': activa,
      'prioridad': prioridad,
      'enviarNotificacion': enviarNotificacion,
      'facebookPostUrl': facebookPostUrl,
    };
  }

  /// Crea una instancia de NoticiaModel desde un Map (base de datos)
  factory NoticiaModel.fromMap(Map<String, dynamic> map) {
    return NoticiaModel(
      id: map['id'] ?? '',
      titulo: map['titulo'] ?? '',
      contenido: map['contenido'] ?? '',
      imagenUrl: map['imagenUrl'],
      tipoNoticia: map['tipoNoticia'] ?? 'general',
      destinatarios: map['destinatarios'] ?? 'todos',
      usuariosEspecificos: map['usuariosEspecificos'] != null
          ? List<String>.from(map['usuariosEspecificos'])
          : null,
      fechaPublicacion: DateTime.parse(map['fechaPublicacion']),
      autorId: map['autorId'] ?? '',
      autorNombre: map['autorNombre'] ?? '',
      activa: map['activa'] ?? true,
      prioridad: map['prioridad'] ?? 'media',
      enviarNotificacion: map['enviarNotificacion'] ?? true,
      facebookPostUrl: map['facebookPostUrl'],
    );
  }

  /// Crea una copia de la noticia con campos modificados
  NoticiaModel copyWith({
    String? id,
    String? titulo,
    String? contenido,
    String? imagenUrl,
    String? tipoNoticia,
    String? destinatarios,
    List<String>? usuariosEspecificos,
    DateTime? fechaPublicacion,
    String? autorId,
    String? autorNombre,
    bool? activa,
    String? prioridad,
    bool? enviarNotificacion,
    String? facebookPostUrl,
  }) {
    return NoticiaModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      tipoNoticia: tipoNoticia ?? this.tipoNoticia,
      destinatarios: destinatarios ?? this.destinatarios,
      usuariosEspecificos: usuariosEspecificos ?? this.usuariosEspecificos,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
      autorId: autorId ?? this.autorId,
      autorNombre: autorNombre ?? this.autorNombre,
      activa: activa ?? this.activa,
      prioridad: prioridad ?? this.prioridad,
      enviarNotificacion: enviarNotificacion ?? this.enviarNotificacion,
      facebookPostUrl: facebookPostUrl ?? this.facebookPostUrl,
    );
  }
}
