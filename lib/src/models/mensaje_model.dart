/// Modelo que representa un mensaje entre usuarios
/// Usado para comunicación entre padres/alumnos y la administración
class MensajeModel {
  /// Identificador único del mensaje
  final String id;
  
  /// ID del usuario que envía el mensaje
  final String remitenteId;
  
  /// Nombre del remitente
  final String remitenteNombre;
  
  /// ID del usuario que recibe el mensaje
  final String destinatarioId;
  
  /// Nombre del destinatario
  final String destinatarioNombre;
  
  /// Asunto del mensaje
  final String asunto;
  
  /// Contenido del mensaje
  final String contenido;
  
  /// Fecha y hora de envío
  final DateTime fechaEnvio;
  
  /// Indica si el mensaje ha sido leído
  final bool leido;
  
  /// Fecha y hora de lectura (si fue leído)
  final DateTime? fechaLectura;
  
  /// Tipo de mensaje: 'solicitud', 'respuesta', 'general'
  final String tipoMensaje;
  
  /// ID del mensaje al que responde (si es una respuesta)
  final String? mensajePadreId;
  
  /// Lista de URLs de archivos adjuntos (opcional)
  final List<String>? archivosAdjuntos;

  /// Constructor principal del modelo de mensaje
  MensajeModel({
    required this.id,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.destinatarioId,
    required this.destinatarioNombre,
    required this.asunto,
    required this.contenido,
    required this.fechaEnvio,
    this.leido = false,
    this.fechaLectura,
    this.tipoMensaje = 'general',
    this.mensajePadreId,
    this.archivosAdjuntos,
  });

  /// Convierte el modelo a un Map para guardarlo en base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remitenteId': remitenteId,
      'remitenteNombre': remitenteNombre,
      'destinatarioId': destinatarioId,
      'destinatarioNombre': destinatarioNombre,
      'asunto': asunto,
      'contenido': contenido,
      'fechaEnvio': fechaEnvio.toIso8601String(),
      'leido': leido,
      'fechaLectura': fechaLectura?.toIso8601String(),
      'tipoMensaje': tipoMensaje,
      'mensajePadreId': mensajePadreId,
      'archivosAdjuntos': archivosAdjuntos,
    };
  }

  /// Crea una instancia de MensajeModel desde un Map (base de datos)
  factory MensajeModel.fromMap(Map<String, dynamic> map) {
    return MensajeModel(
      id: map['id'] ?? '',
      remitenteId: map['remitenteId'] ?? '',
      remitenteNombre: map['remitenteNombre'] ?? '',
      destinatarioId: map['destinatarioId'] ?? '',
      destinatarioNombre: map['destinatarioNombre'] ?? '',
      asunto: map['asunto'] ?? '',
      contenido: map['contenido'] ?? '',
      fechaEnvio: DateTime.parse(map['fechaEnvio']),
      leido: map['leido'] ?? false,
      fechaLectura: map['fechaLectura'] != null
          ? DateTime.parse(map['fechaLectura'])
          : null,
      tipoMensaje: map['tipoMensaje'] ?? 'general',
      mensajePadreId: map['mensajePadreId'],
      archivosAdjuntos: map['archivosAdjuntos'] != null
          ? List<String>.from(map['archivosAdjuntos'])
          : null,
    );
  }

  /// Crea una copia del mensaje con campos modificados
  MensajeModel copyWith({
    String? id,
    String? remitenteId,
    String? remitenteNombre,
    String? destinatarioId,
    String? destinatarioNombre,
    String? asunto,
    String? contenido,
    DateTime? fechaEnvio,
    bool? leido,
    DateTime? fechaLectura,
    String? tipoMensaje,
    String? mensajePadreId,
    List<String>? archivosAdjuntos,
  }) {
    return MensajeModel(
      id: id ?? this.id,
      remitenteId: remitenteId ?? this.remitenteId,
      remitenteNombre: remitenteNombre ?? this.remitenteNombre,
      destinatarioId: destinatarioId ?? this.destinatarioId,
      destinatarioNombre: destinatarioNombre ?? this.destinatarioNombre,
      asunto: asunto ?? this.asunto,
      contenido: contenido ?? this.contenido,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      leido: leido ?? this.leido,
      fechaLectura: fechaLectura ?? this.fechaLectura,
      tipoMensaje: tipoMensaje ?? this.tipoMensaje,
      mensajePadreId: mensajePadreId ?? this.mensajePadreId,
      archivosAdjuntos: archivosAdjuntos ?? this.archivosAdjuntos,
    );
  }
}
