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

  /// Valida una contraseña (fuerte: 8+ caracteres, mayúscula, número)
  /// SOLO para REGISTRO de nuevos usuarios
  /// 
  /// Parámetros:
  /// - [value]: La contraseña a validar
  /// - [minLength]: Longitud mínima (por defecto 8)
  /// 
  /// Retorna:
  /// - `null` si es válida
  /// - Mensaje de error si no cumple los requisitos
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    // Verificar mayúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }

    // Verificar número
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }

    return null;
  }

  /// Valida una contraseña para LOGIN (débil: solo longitud mínima)
  /// Permite contraseñas antiguas sin mayúscula ni número
  /// 
  /// Parámetros:
  /// - [value]: La contraseña a validar
  /// - [minLength]: Longitud mínima (por defecto 6)
  /// 
  /// Retorna:
  /// - `null` si es válida
  /// - Mensaje de error si es muy corta
  static String? passwordLogin(String? value, {int minLength = 6}) {
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

  /// Valida un nombre (sin caracteres especiales, solo letras y espacios)
  /// 
  /// Parámetros:
  /// - [value]: El nombre a validar
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si contiene caracteres especiales
  /// 
  /// Ejemplo:
  /// ```dart
  /// final error = Validators.nombre('Juan@123');
  /// print(error); // "El nombre solo puede contener letras y espacios"
  /// ```
  static String? nombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    // Solo permite letras, espacios, acentos, ñ, puntos y apóstrofes
    final nameRegex = RegExp(r"^[a-záéíóúñ\s.'-]+$", caseSensitive: false);

    if (!nameRegex.hasMatch(value.trim())) {
      return 'El nombre solo puede contener letras, espacios, puntos y apóstrofes';
    }

    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  /// Valida que haya exactamente 4 opciones en un reactivo
  /// 
  /// Parámetros:
  /// - [opciones]: Lista de opciones
  /// 
  /// Retorna:
  /// - `null` si hay 4 opciones
  /// - Mensaje de error si no hay 4
  static String? opcionesCount(List<String>? opciones) {
    if (opciones == null || opciones.isEmpty) {
      return 'Debes agregar al menos 4 opciones';
    }

    if (opciones.length != 4) {
      return 'Debe haber exactamente 4 opciones (actualmente: ${opciones.length})';
    }

    // Verificar que ninguna opción esté vacía
    for (var i = 0; i < opciones.length; i++) {
      if (opciones[i].trim().isEmpty) {
        return 'La opción ${i + 1} no puede estar vacía';
      }
    }

    return null;
  }

  /// Valida que la respuesta correcta sea válida
  /// 
  /// Parámetros:
  /// - [respuestaCorrecta]: Índice de la respuesta correcta
  /// - [totalOpciones]: Total de opciones disponibles
  /// 
  /// Retorna:
  /// - `null` si es válido
  /// - Mensaje de error si está fuera de rango
  static String? respuestaCorrecta(int? respuestaCorrecta, int totalOpciones) {
    if (respuestaCorrecta == null) {
      return 'Debes seleccionar la respuesta correcta';
    }

    if (respuestaCorrecta < 0 || respuestaCorrecta >= totalOpciones) {
      return 'La respuesta correcta debe estar entre 0 y ${totalOpciones - 1}';
    }

    return null;
  }

  /// Valida que opciones no estén duplicadas
  /// 
  /// Parámetros:
  /// - [opciones]: Lista de opciones
  /// 
  /// Retorna:
  /// - `null` si son únicas
  /// - Mensaje de error si hay duplicados
  static String? opcionesDuplicated(List<String>? opciones) {
    if (opciones == null || opciones.length < 2) {
      return null; // Si hay menos de 2, no puede haber duplicados
    }

    final trimmedOpciones = opciones.map((o) => o.trim().toLowerCase()).toList();
    final uniqueOpciones = trimmedOpciones.toSet();

    if (trimmedOpciones.length != uniqueOpciones.length) {
      return 'No pueden haber opciones duplicadas';
    }

    return null;
  }
}
