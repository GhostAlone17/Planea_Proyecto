import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// Clase de utilidades para mostrar diálogos y snackbars
/// Facilita la comunicación con el usuario mediante mensajes
class DialogHelper {
  /// Prevenir instanciación de la clase
  DialogHelper._();

  /// Muestra un SnackBar con un mensaje de información
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [message]: El mensaje a mostrar
  /// 
  /// Ejemplo:
  /// ```dart
  /// DialogHelper.showInfo(context, 'Información guardada exitosamente');
  /// ```
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.colorPrimario,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un SnackBar con un mensaje de éxito
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [message]: El mensaje a mostrar
  /// 
  /// Ejemplo:
  /// ```dart
  /// DialogHelper.showSuccess(context, 'Operación completada con éxito');
  /// ```
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.colorExito,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un SnackBar con un mensaje de error
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [message]: El mensaje de error a mostrar
  /// 
  /// Ejemplo:
  /// ```dart
  /// DialogHelper.showError(context, 'Ha ocurrido un error');
  /// ```
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.colorError,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un SnackBar con un mensaje de advertencia
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [message]: El mensaje de advertencia a mostrar
  /// 
  /// Ejemplo:
  /// ```dart
  /// DialogHelper.showWarning(context, 'Ten cuidado con esta acción');
  /// ```
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.colorAdvertencia,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un diálogo de confirmación
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [title]: Título del diálogo
  /// - [message]: Mensaje del diálogo
  /// - [confirmText]: Texto del botón de confirmación (por defecto: 'Confirmar')
  /// - [cancelText]: Texto del botón de cancelar (por defecto: 'Cancelar')
  /// 
  /// Retorna:
  /// - `true` si el usuario confirma
  /// - `false` si el usuario cancela
  /// 
  /// Ejemplo:
  /// ```dart
  /// final confirmado = await DialogHelper.showConfirmDialog(
  ///   context,
  ///   'Eliminar',
  ///   '¿Estás seguro de eliminar este elemento?',
  /// );
  /// if (confirmado) {
  ///   // Proceder con la eliminación
  /// }
  /// ```
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Muestra un diálogo de carga con un indicador de progreso
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [message]: Mensaje a mostrar (por defecto: 'Cargando...')
  /// 
  /// Ejemplo:
  /// ```dart
  /// DialogHelper.showLoadingDialog(context);
  /// // Realizar operación
  /// await Future.delayed(Duration(seconds: 2));
  /// Navigator.of(context).pop(); // Cerrar el diálogo
  /// ```
  static void showLoadingDialog(BuildContext context, {String message = 'Cargando...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: AppConstants.paddingMedium),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Muestra un diálogo de información simple
  /// 
  /// Parámetros:
  /// - [context]: El BuildContext actual
  /// - [title]: Título del diálogo
  /// - [message]: Mensaje del diálogo
  /// 
  /// Ejemplo:
  /// ```dart
  /// DialogHelper.showInfoDialog(
  ///   context,
  ///   'Información',
  ///   'Esta es una noticia importante del plantel',
  /// );
  /// ```
  static void showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}
