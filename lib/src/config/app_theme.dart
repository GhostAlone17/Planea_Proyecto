import 'package:flutter/material.dart';
import 'app_constants.dart';

/// Clase que define el tema visual de la aplicación
/// Contiene configuraciones de colores, tipografías y estilos
class AppTheme {
  /// Prevenir instanciación de la clase
  AppTheme._();

  /// Tema claro de la aplicación
  static ThemeData get lightTheme {
    return ThemeData(
      // ============ CONFIGURACIÓN BÁSICA ============
      
      /// Usa Material 3
      useMaterial3: true,
      
      /// Brillo del tema (claro)
      brightness: Brightness.light,
      
      // ============ ESQUEMA DE COLORES ============
      
      colorScheme: ColorScheme.light(
        primary: AppConstants.colorPrimario,
        secondary: AppConstants.colorSecundario,
        tertiary: AppConstants.colorAcento,
        error: AppConstants.colorError,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppConstants.colorTextoPrincipal,
      ),
      
      // ============ TIPOGRAFÍA ============
      
      textTheme: const TextTheme(
        /// Encabezado grande
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Encabezado medio
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Encabezado pequeño
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Título grande
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Título medio
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Texto del cuerpo grande
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Texto del cuerpo medio
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppConstants.colorTextoPrincipal,
        ),
        
        /// Texto del cuerpo pequeño
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppConstants.colorTextoSecundario,
        ),
      ),
      
      // ============ ESTILO DE APPBAR ============
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.colorPrimario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // ============ ESTILO DE TARJETAS ============
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        color: Colors.white,
      ),
      
      // ============ ESTILO DE BOTONES ============
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.colorPrimario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.colorPrimario,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          side: const BorderSide(
            color: AppConstants.colorPrimario,
            width: 1.5,
          ),
        ),
      ),
      
      // ============ ESTILO DE CAMPOS DE TEXTO ============
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppConstants.colorPrimario,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppConstants.colorError,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
      ),
      
      // ============ ESTILO DE FLOATING ACTION BUTTON ============
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.colorAcento,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
