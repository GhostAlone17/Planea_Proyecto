import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/reactive_model.dart';
import '../models/category_model_v2.dart';
import '../models/student_report_model.dart';
import 'password_service.dart';

/// Servicio para operaciones administrativas
/// Maneja CRUD de estudiantes, reactivos, categorías y reportes
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== ESTUDIANTES ====================

  /// Obtener lista de todos los estudiantes
  Future<List<UserModel>> obtenerEstudiantes() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener estudiantes: $e');
      return [];
    }
  }

  /// Crear nuevo estudiante con roles y contraseña por defecto
  Future<bool> crearEstudiante({
    required String nombre,
    required String email,
    required String gradoId,
    required List<String> roles,
  }) async {
    try {
      // Crear usuario en Firebase Auth con contraseña por defecto
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: PasswordService.DEFAULT_PASSWORD,
          );

      final nuevoEstudiante = UserModel(
        id: userCredential.user!.uid,
        nombre: nombre,
        email: email,
        tipoUsuario: 'alumno',
        gradoId: gradoId,
        fechaRegistro: DateTime.now(),
        activo: true,
        roles: roles,
      );

      await _firestore
          .collection('usuarios')
          .doc(nuevoEstudiante.id)
          .set(nuevoEstudiante.toMap());

      return true;
    } catch (e) {
      print('Error al crear estudiante: $e');
      return false;
    }
  }

  /// Actualizar información del estudiante
  Future<bool> actualizarEstudiante({
    required String id,
    required String nombre,
    required String gradoId,
    bool? activo,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'nombre': nombre,
        'gradoId': gradoId,
      };
      
      if (activo != null) {
        updateData['activo'] = activo;
      }

      await _firestore.collection('usuarios').doc(id).update(updateData);

      return true;
    } catch (e) {
      print('Error al actualizar estudiante: $e');
      return false;
    }
  }

  /// Cambiar el estado (activo/inactivo) de un estudiante
  Future<bool> cambiarEstadoEstudiante(String id, bool activo) async {
    try {
      await _firestore.collection('usuarios').doc(id).update({
        'activo': activo,
      });

      return true;
    } catch (e) {
      print('Error al cambiar estado del estudiante: $e');
      return false;
    }
  }

  /// Eliminar estudiante (marcar como inactivo)
  Future<bool> eliminarEstudiante(String id) async {
    try {
      await _firestore.collection('usuarios').doc(id).update({
        'activo': false,
      });

      return true;
    } catch (e) {
      print('Error al eliminar estudiante: $e');
      return false;
    }
  }

  /// Obtener número total de estudiantes activos
  Future<int> obtenerTotalEstudiantes() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .where('activo', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error al contar estudiantes: $e');
      return 0;
    }
  }

  // ==================== REACTIVOS ====================

  /// Obtener lista de todos los reactivos
  Future<List<ReactiveModel>> obtenerReactivos({String? categoryId}) async {
    try {
      Query query = _firestore.collection('reactivos').where('activa', isEqualTo: true);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ReactiveModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener reactivos: $e');
      return [];
    }
  }

  /// Crear nuevo reactivo
  Future<bool> crearReactivo({
    required String categoryId,
    required String pregunta,
    required List<String> opciones,
    required int respuestaCorrecta,
    required int dificultad,
    String? explicacion,
    required String creadoPor,
  }) async {
    try {
      final nuevoReactivo = ReactiveModel(
        id: _firestore.collection('reactivos').doc().id,
        categoryId: categoryId,
        pregunta: pregunta,
        opciones: opciones,
        respuestaCorrecta: respuestaCorrecta,
        dificultad: dificultad,
        explicacion: explicacion,
        activa: true,
        fechaCreacion: DateTime.now(),
        creadoPor: creadoPor,
      );

      await _firestore
          .collection('reactivos')
          .doc(nuevoReactivo.id)
          .set(nuevoReactivo.toMap());

      return true;
    } catch (e) {
      print('Error al crear reactivo: $e');
      return false;
    }
  }

  /// Actualizar reactivo
  Future<bool> actualizarReactivo({
    required String id,
    required String pregunta,
    required List<String> opciones,
    required int respuestaCorrecta,
    required int dificultad,
    String? explicacion,
  }) async {
    try {
      await _firestore.collection('reactivos').doc(id).update({
        'pregunta': pregunta,
        'opciones': opciones,
        'respuestaCorrecta': respuestaCorrecta,
        'dificultad': dificultad,
        'explicacion': explicacion,
      });

      return true;
    } catch (e) {
      print('Error al actualizar reactivo: $e');
      return false;
    }
  }

  /// Eliminar reactivo (marcar como inactivo)
  Future<bool> eliminarReactivo(String id) async {
    try {
      await _firestore.collection('reactivos').doc(id).update({
        'activa': false,
      });

      return true;
    } catch (e) {
      print('Error al eliminar reactivo: $e');
      return false;
    }
  }

  /// Obtener número total de reactivos
  Future<int> obtenerTotalReactivos() async {
    try {
      final snapshot = await _firestore
          .collection('reactivos')
          .where('activa', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error al contar reactivos: $e');
      return 0;
    }
  }

  // ==================== CATEGORÍAS ====================

  /// Obtener todas las categorías predefinidas
  /// (Las categorías son estáticas, solo lectura)
  List<CategoryModelV2> obtenerCategorias() {
    return CategoryModelV2.categoriasDefault();
  }

  /// Obtener número de reactivos por categoría
  Future<Map<String, int>> obtenerReactivosPorCategoria() async {
    try {
      final result = <String, int>{};
      final categorias = CategoryModelV2.categoriasDefault();

      for (var categoria in categorias) {
        final snapshot = await _firestore
            .collection('reactivos')
            .where('categoryId', isEqualTo: categoria.id)
            .where('activa', isEqualTo: true)
            .count()
            .get();

        result[categoria.id] = snapshot.count ?? 0;
      }

      return result;
    } catch (e) {
      print('Error al contar reactivos por categoría: $e');
      return {};
    }
  }

  // ==================== REPORTES ====================

  /// Obtener reporte de desempeño de un estudiante
  Future<StudentReportModel?> obtenerReporteEstudiante(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reportes_estudiantes')
          .doc(userId)
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return StudentReportModel.fromMap(snapshot.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error al obtener reporte del estudiante: $e');
      return null;
    }
  }

  /// Obtener reportes de todos los estudiantes
  Future<List<StudentReportModel>> obtenerTodosLosReportes() async {
    try {
      final snapshot = await _firestore
          .collection('reportes_estudiantes')
          .get();

      return snapshot.docs
          .map((doc) => StudentReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener todos los reportes: $e');
      return [];
    }
  }

  /// Guardar/actualizar reporte de estudiante
  Future<bool> guardarReporteEstudiante(StudentReportModel reporte) async {
    try {
      await _firestore
          .collection('reportes_estudiantes')
          .doc(reporte.userId)
          .set(reporte.toMap());

      return true;
    } catch (e) {
      print('Error al guardar reporte: $e');
      return false;
    }
  }

  /// Obtener estadísticas generales
  Future<Map<String, dynamic>> obtenerEstadisticasGenerales() async {
    try {
      final totalEstudiantes = await obtenerTotalEstudiantes();
      final totalReactivos = await obtenerTotalReactivos();
      final reportes = await obtenerTodosLosReportes();

      double promedioGeneral = 0;
      if (reportes.isNotEmpty) {
        promedioGeneral = reportes
                .map((r) => r.promedioGeneral)
                .reduce((a, b) => a + b) /
            reportes.length;
      }

      final totalTests = reportes.fold<int>(
        0,
        (sum, r) => sum + r.totalTestsRealizados,
      );

      return {
        'totalEstudiantes': totalEstudiantes,
        'totalReactivos': totalReactivos,
        'totalTests': totalTests,
        'promedioGeneral': promedioGeneral,
        'totalCategorias': CategoryModelV2.categoriasDefault().length,
      };
    } catch (e) {
      print('Error al obtener estadísticas generales: $e');
      return {
        'totalEstudiantes': 0,
        'totalReactivos': 0,
        'totalTests': 0,
        'promedioGeneral': 0.0,
        'totalCategorias': 6,
      };
    }
  }

  /// Stream de estudiantes en tiempo real
  Stream<List<UserModel>> streamEstudiantes() {
    return _firestore
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'alumno')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  /// Stream de reactivos en tiempo real
  Stream<List<ReactiveModel>> streamReactivos({String? categoryId}) {
    Query query = _firestore
        .collection('reactivos')
        .where('activa', isEqualTo: true);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ReactiveModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Stream de reportes en tiempo real
  Stream<List<StudentReportModel>> streamReportes() {
    return _firestore
        .collection('reportes_estudiantes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentReportModel.fromMap(doc.data()))
            .toList());
  }
}
