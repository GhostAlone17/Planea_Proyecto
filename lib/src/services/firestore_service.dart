import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio para interactuar con Firestore
/// Maneja operaciones CRUD para todas las colecciones
/// 
/// Uso:
/// ```dart
/// final firestoreService = context.read<FirestoreService>();
/// final docs = await firestoreService.getCollection(collection: 'noticias');
/// ```
class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene un documento por ID
  Future<DocumentSnapshot<Map<String, dynamic>>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final doc = await _firestore.collection(collection).doc(docId).get();

      _isLoading = false;
      notifyListeners();
      return doc;
    } catch (e) {
      _errorMessage = 'Error obteniendo documento: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Obtiene todos los documentos de una colección con opciones de filtrado
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?> getCollection({
    required String collection,
    List<Map<String, dynamic>>? filters,
    List<Map<String, dynamic>>? orderBy,
    int? limit,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      Query<Map<String, dynamic>> query = _firestore.collection(collection);

      // Aplicar filtros
      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          query = query.where(
            filter['field'],
            isEqualTo: filter['value'],
          );
        }
      }

      // Aplicar ordenamiento
      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(
            order['field'],
            descending: order['descending'] ?? false,
          );
        }
      }

      // Aplicar límite
      if (limit != null) {
        query = query.limit(limit);
      }

      final docs = await query.get();

      _isLoading = false;
      notifyListeners();
      return docs.docs;
    } catch (e) {
      _errorMessage = 'Error obteniendo colección: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Crea un nuevo documento
  Future<String?> createDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? customId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      late String docId;
      if (customId != null) {
        await _firestore.collection(collection).doc(customId).set(data);
        docId = customId;
      } else {
        final docRef = await _firestore.collection(collection).add(data);
        docId = docRef.id;
      }

      _isLoading = false;
      notifyListeners();
      return docId;
    } catch (e) {
      _errorMessage = 'Error creando documento: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Actualiza un documento existente
  Future<bool> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection(collection).doc(docId).update(data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando documento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina un documento
  Future<bool> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection(collection).doc(docId).delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando documento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Stream para escuchar cambios en tiempo real de un documento
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// Stream para escuchar cambios en tiempo real de una colección
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection({
    required String collection,
    List<Map<String, dynamic>>? filters,
    List<Map<String, dynamic>>? orderBy,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        query = query.where(filter['field'], isEqualTo: filter['value']);
      }
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      for (final order in orderBy) {
        query = query.orderBy(
          order['field'],
          descending: order['descending'] ?? false,
        );
      }
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Realiza una transacción en Firestore
  Future<bool> transaction(
    Future<void> Function(Transaction) updateFunction,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.runTransaction(updateFunction);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error en transacción: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
