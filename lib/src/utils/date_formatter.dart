import 'package:intl/intl.dart';

/// Clase de utilidades para formatear fechas
/// Provee métodos estáticos para convertir fechas a formatos legibles
class DateFormatter {
  /// Prevenir instanciación de la clase
  DateFormatter._();

  /// Formatea una fecha en formato: "15 de Octubre de 2025"
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fecha = DateTime.now();
  /// final formateada = DateFormatter.formatoCompleto(fecha);
  /// print(formateada); // "20 de Octubre de 2025"
  /// ```
  static String formatoCompleto(DateTime fecha) {
    return DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(fecha);
  }

  /// Formatea una fecha en formato corto: "15/10/2025"
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fecha = DateTime.now();
  /// final formateada = DateFormatter.formatoCorto(fecha);
  /// print(formateada); // "20/10/2025"
  /// ```
  static String formatoCorto(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  /// Formatea una hora en formato: "14:30"
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fecha = DateTime.now();
  /// final hora = DateFormatter.formatoHora(fecha);
  /// print(hora); // "14:30"
  /// ```
  static String formatoHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }

  /// Formatea fecha y hora: "15/10/2025 14:30"
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fecha = DateTime.now();
  /// final formateada = DateFormatter.formatoFechaHora(fecha);
  /// print(formateada); // "20/10/2025 14:30"
  /// ```
  static String formatoFechaHora(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  /// Calcula el tiempo relativo desde una fecha
  /// Retorna texto como: "Hace 5 minutos", "Hace 2 horas", "Hace 3 días"
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fechaPasada = DateTime.now().subtract(Duration(hours: 2));
  /// final relativo = DateFormatter.tiempoRelativo(fechaPasada);
  /// print(relativo); // "Hace 2 horas"
  /// ```
  static String tiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'Hace ${diferencia.inSeconds} segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes != 1 ? 's' : ''}';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours != 1 ? 's' : ''}';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays != 1 ? 's' : ''}';
    } else if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();
      return 'Hace $semanas semana${semanas != 1 ? 's' : ''}';
    } else if (diferencia.inDays < 365) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace $meses mes${meses != 1 ? 'es' : ''}';
    } else {
      final anios = (diferencia.inDays / 365).floor();
      return 'Hace $anios año${anios != 1 ? 's' : ''}';
    }
  }

  /// Obtiene el nombre del día de la semana en español
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fecha = DateTime.now();
  /// final dia = DateFormatter.nombreDia(fecha);
  /// print(dia); // "Lunes"
  /// ```
  static String nombreDia(DateTime fecha) {
    return DateFormat('EEEE', 'es').format(fecha);
  }

  /// Obtiene el nombre del mes en español
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fecha = DateTime.now();
  /// final mes = DateFormatter.nombreMes(fecha);
  /// print(mes); // "Octubre"
  /// ```
  static String nombreMes(DateTime fecha) {
    return DateFormat('MMMM', 'es').format(fecha);
  }
}
