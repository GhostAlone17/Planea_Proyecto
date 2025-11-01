import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Servicio para interactuar con Firebase Storage
/// Maneja carga y descarga de archivos
///
/// Uso:
/// ```dart
/// final storageService = context.read<StorageService>();
/// final url = await storageService.uploadFile(
///   file: imageFile,
///   path: 'images/profile.jpg',
/// );
/// ```
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube un archivo a Storage
  /// Retorna la URL de descarga
  Future<String?> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);

      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error subiendo archivo: $e');
      return null;
    }
  }

  /// Descarga un archivo de Storage
  Future<File?> downloadFile({
    required String path,
    required String localPath,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final file = File(localPath);

      await ref.writeToFile(file);

      return file;
    } catch (e) {
      debugPrint('Error descargando archivo: $e');
      return null;
    }
  }

  /// Obtiene la URL de descarga de un archivo
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error obteniendo URL: $e');
      return null;
    }
  }

  /// Elimina un archivo de Storage
  Future<bool> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error eliminando archivo: $e');
      return false;
    }
  }

  /// Lista archivos en una carpeta
  Future<List<Reference>?> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      debugPrint('Error listando archivos: $e');
      return null;
    }
  }
}
