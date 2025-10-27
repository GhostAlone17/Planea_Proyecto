/// Clase de utilidades para validaciones de formularios
/// Provee métodos estáticos para validar campos de entrada
class Validators {
  /// Prevenir instanciación de la clase
  Validators._();

  /// Valida que un campo no esté vacío
  /// 
  /// Parámetros:
  /// - [value]: El valor a validar
  /// - [fieldName]: El nombre del campo (para el mensaje de error)
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si está vacío
  /// 
  /// Ejemplo:
  /// ```dart
  /// final error = Validators.required('', 'Nombre');
  /// print(error); // "El campo Nombre es requerido"
  /// ```
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es requerido';
    }
    return null;
  }

  /// Valida un correo electrónico
  /// 
  /// Parámetros:
  /// - [value]: El email a validar
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si no es un email válido
  /// 
  /// Ejemplo:
  /// ```dart
  /// final error = Validators.email('usuario@ejemplo');
  /// print(error); // "Ingresa un correo electrónico válido"
  /// ```
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es requerido';
    }

    // Expresión regular para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  /// Valida una contraseña
  /// 
  /// Parámetros:
  /// - [value]: La contraseña a validar
  /// - [minLength]: Longitud mínima (por defecto 6)
  /// 
  /// Retorna:
  /// - `null` si es válida
  /// - Mensaje de error si no cumple los requisitos
  /// 
  /// Ejemplo:
  /// ```dart
  /// final error = Validators.password('12345');
  /// print(error); // "La contraseña debe tener al menos 6 caracteres"
  /// ```
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    return null;
  }

  /// Valida que dos contraseñas coincidan
  /// 
  /// Parámetros:
  /// - [password]: La contraseña original
  /// - [confirmPassword]: La contraseña de confirmación
  /// 
  /// Retorna:
  /// - `null` si coinciden
  /// - Mensaje de error si no coinciden
  /// 
  /// Ejemplo:
  /// ```dart
  /// final error = Validators.confirmPassword('123456', '123457');
  /// print(error); // "Las contraseñas no coinciden"
  /// ```
  static String? confirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'La confirmación de contraseña es requerida';
    }

    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida un número de teléfono
  /// 
  /// Parámetros:
  /// - [value]: El número de teléfono a validar
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si no es válido
  /// 
  /// Ejemplo:
  /// ```dart
  /// final error = Validators.phone('123');
  /// print(error); // "Ingresa un número de teléfono válido"
  /// ```
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de teléfono es requerido';
    }

    // Expresión regular para validar teléfono (10 dígitos)
    final phoneRegex = RegExp(r'^\d{10}$');

    // Remover espacios, guiones y paréntesis
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Ingresa un número de teléfono válido (10 dígitos)';
    }

    return null;
  }

  /// Valida la longitud mínima de un campo
  /// 
  /// Parámetros:
  /// - [value]: El valor a validar
  /// - [minLength]: Longitud mínima requerida
  /// - [fieldName]: Nombre del campo
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si es muy corto
  static String? minLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'El campo $fieldName es requerido';
    }

    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    return null;
  }

  /// Valida la longitud máxima de un campo
  /// 
  /// Parámetros:
  /// - [value]: El valor a validar
  /// - [maxLength]: Longitud máxima permitida
  /// - [fieldName]: Nombre del campo
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si es muy largo
  static String? maxLength(String? value, int maxLength, String fieldName) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName no puede tener más de $maxLength caracteres';
    }

    return null;
  }

  /// Valida que un valor sea numérico
  /// 
  /// Parámetros:
  /// - [value]: El valor a validar
  /// - [fieldName]: Nombre del campo
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si no es numérico
  static String? numeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'El campo $fieldName es requerido';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }

    return null;
  }
}
