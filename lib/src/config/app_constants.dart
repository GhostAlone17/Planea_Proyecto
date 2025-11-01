import 'package:flutter/material.dart';

/// Clase que contiene todas las constantes de la aplicación
/// Incluye colores, textos, configuraciones, etc.
class AppConstants {
  /// Prevenir instanciación de la clase
  AppConstants._();

  // ============ INFORMACIÓN DE LA APP ============
  
  /// Nombre de la aplicación
  static const String appName = 'Plantel App';
  
  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  // ============ TIPOS DE USUARIO ============
  
  /// Tipo de usuario: Alumno
  static const String tipoUsuarioAlumno = 'alumno';
  
  /// Tipo de usuario: Padre de familia
  static const String tipoUsuarioPadre = 'padre';
  
  /// Tipo de usuario: Docente
  static const String tipoUsuarioDocente = 'docente';
  
  /// Tipo de usuario: Administrador (solo web)
  static const String tipoUsuarioAdmin = 'admin';

  // ============ TIPOS DE NOTICIA ============
  
  /// Noticia de tipo general
  static const String tipoNoticiaGeneral = 'general';
  
  /// Noticia sobre becas u oportunidades
  static const String tipoNoticiaBeca = 'beca';
  
  /// Noticia sobre suspensión de clases
  static const String tipoNoticiaSuspension = 'suspension';
  
  /// Noticia sobre eventos del plantel
  static const String tipoNoticiaEvento = 'evento';
  
  /// Noticia de tipo académico
  static const String tipoNoticiaAcademica = 'academica';

  // ============ DESTINATARIOS DE NOTICIA ============
  
  /// Noticia para todos los usuarios
  static const String destinatariosTodos = 'todos';
  
  /// Noticia solo para alumnos
  static const String destinatariosAlumnos = 'alumnos';
  
  /// Noticia solo para padres de familia
  static const String destinatariosPadres = 'padres';
  
  /// Noticia solo para docentes
  static const String destinatariosDocentes = 'docentes';
  
  /// Noticia para usuarios específicos
  static const String destinatariosEspecifico = 'especifico';

  // ============ PRIORIDADES ============
  
  /// Prioridad alta (urgente)
  static const String prioridadAlta = 'alta';
  
  /// Prioridad media (normal)
  static const String prioridadMedia = 'media';
  
  /// Prioridad baja
  static const String prioridadBaja = 'baja';

  // ============ TIPOS DE MENSAJE ============
  
  /// Mensaje de solicitud
  static const String tipoMensajeSolicitud = 'solicitud';
  
  /// Mensaje de respuesta
  static const String tipoMensajeRespuesta = 'respuesta';
  
  /// Mensaje general
  static const String tipoMensajeGeneral = 'general';

  // ============ COLORES DE LA APP ============
  
  /// Color principal de la aplicación
  static const Color colorPrimario = Color(0xFF2C5F4F);
  
  /// Color secundario de la aplicación
  static const Color colorSecundario = Color(0xFF4A8B73);
  
  /// Color de acento
  static const Color colorAcento = Color(0xFFFFB84D);
  
  /// Color de fondo claro
  static const Color colorFondo = Color(0xFFF5F5F5);
  
  /// Color de texto principal
  static const Color colorTextoPrincipal = Color(0xFF212121);
  
  /// Color de texto secundario
  static const Color colorTextoSecundario = Color(0xFF757575);
  
  /// Color de error
  static const Color colorError = Color(0xFFD32F2F);
  
  /// Color de éxito
  static const Color colorExito = Color(0xFF388E3C);
  
  /// Color de advertencia
  static const Color colorAdvertencia = Color(0xFFF57C00);

  // ============ TAMAÑOS Y ESPACIADO ============
  
  /// Padding pequeño
  static const double paddingSmall = 8.0;
  
  /// Padding medio
  static const double paddingMedium = 16.0;
  
  /// Padding grande
  static const double paddingLarge = 24.0;
  
  /// Radio de bordes para tarjetas
  static const double borderRadius = 12.0;

  // ============ RUTAS DE NAVEGACIÓN ============
  
  /// Ruta de la pantalla de login
  static const String routeLogin = '/login';
  
  /// Ruta de la pantalla principal
  static const String routeHome = '/home';
  
  /// Ruta de la pantalla de noticias
  static const String routeNoticias = '/noticias';
  
  /// Ruta de la pantalla de mensajes
  static const String routeMensajes = '/mensajes';
  
  /// Ruta de la pantalla de perfil
  static const String routePerfil = '/perfil';

  // ============ MENSAJES DE ERROR ============
  
  /// Error de conexión
  static const String errorConexion = 'Error de conexión. Verifica tu internet.';
  
  /// Error de autenticación
  static const String errorAutenticacion = 'Usuario o contraseña incorrectos.';
  
  /// Error genérico
  static const String errorGenerico = 'Ha ocurrido un error. Intenta de nuevo.';
  
  /// Sesión expirada
  static const String errorSesionExpirada = 'Tu sesión ha expirado. Inicia sesión nuevamente.';

  // ============ CONFIGURACIONES ============
  
  /// Número máximo de reintentos para peticiones
  static const int maxReintentos = 3;
  
  /// Timeout para peticiones HTTP (en segundos)
  static const int timeoutSegundos = 30;
  
  /// Número de elementos por página en listas
  static const int elementosPorPagina = 20;

  // ============ CONSTANTES PLANEA ============
  
  /// Grados permitidos para PLANEA
  /// Primaria: 4° y 6°
  /// Secundaria: 3°
  /// Media Superior: Último año
  static const Map<String, List<Map<String, String>>> GRADOS_PLANEA = {
    'Primaria': [
      {'valor': '4P', 'label': '4° Primaria', 'emoji': '📚'},
      {'valor': '6P', 'label': '6° Primaria', 'emoji': '📚'},
    ],
    'Secundaria': [
      {'valor': '3S', 'label': '3° Secundaria', 'emoji': '🎓'},
    ],
    'Educación Media Superior': [
      {'valor': '12EMS', 'label': '3° de Preparatoria', 'emoji': '👨‍🎓'},
    ],
  };

  /// Obtener lista plana de todos los grados PLANEA
  static List<Map<String, String>> obtenerTodosGrados() {
    final list = <Map<String, String>>[];
    GRADOS_PLANEA.forEach((key, grados) {
      list.addAll(grados);
    });
    return list;
  }

  /// Dificultades de reactivos PLANEA
  static const Map<String, String> DIFICULTADES = {
    '1': '🟢 Fácil',
    '2': '🟡 Medio',
    '3': '🔴 Difícil',
  };

  /// Categorías PLANEA - Matemáticas
  static const List<String> CATEGORIAS_PLANEA = [
    'Aritmética',
    'Álgebra',
    'Geometría',
    'Trigonometría',
    'Estadística',
    'Cálculo',
  ];

  /// Mapeo de categorías a IDs
  static const Map<String, String> CATEGORIAS_IDS = {
    'Aritmética': 'aritmetica',
    'Álgebra': 'algebra',
    'Geometría': 'geometria',
    'Trigonometría': 'trigonometria',
    'Estadística': 'estadistica',
    'Cálculo': 'calculo',
  };

  /// Descripción de niveles de dificultad
  static const Map<String, String> DIFICULTAD_DESCRIPCION = {
    '1': 'Fácil - Conceptos básicos y ejercicios simples',
    '2': 'Medio - Requiere comprensión y análisis',
    '3': 'Difícil - Requiere razonamiento avanzado',
  };

  /// Traduce tipo de usuario a etiqueta legible
  static String traducirTipoUsuario(String tipoUsuario) {
    switch (tipoUsuario) {
      case 'alumno':
        return 'Alumno';
      case 'padre':
        return 'Padre de Familia';
      case 'docente':
        return 'Docente';
      case 'admin':
        return 'Administrador';
      default:
        return tipoUsuario;
    }
  }
}
