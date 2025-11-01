import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/student_report_model.dart';

/// Servicio para operaciones específicas del maestro/docente
/// Permite gestionar solo sus estudiantes asignados
class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener los estudiantes asignados al maestro actual
  Future<List<UserModel>> obtenerMisEstudiantes() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Obtener alumnos donde este maestro está asignado
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .where('maestroIds', arrayContains: teacherId)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  /// Obtener reporte de un estudiante específico
  Future<StudentReportModel?> obtenerReporteEstudiante(String studentId) async {
    try {
      final doc = await _firestore
          .collection('reportes_estudiantes')
          .doc(studentId)
          .get();

      if (!doc.exists) return null;

      return StudentReportModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error obteniendo reporte: $e');
      return null;
    }
  }

  /// Obtener reportes de todos los estudiantes del maestro
  Future<List<StudentReportModel>> obtenerReportesMisEstudiantes() async {
    try {
      final estudiantes = await obtenerMisEstudiantes();
      final reportes = <StudentReportModel>[];

      for (var estudiante in estudiantes) {
        final reporte = await obtenerReporteEstudiante(estudiante.id);
        if (reporte != null) {
          reportes.add(reporte);
        }
      }

      return reportes;
    } catch (e) {
      print('❌ Error obteniendo reportes: $e');
      return [];
    }
  }

  /// Calcular estadísticas del grupo
  Future<Map<String, dynamic>> obtenerEstadisticasGrupo() async {
    try {
      final reportes = await obtenerReportesMisEstudiantes();

      if (reportes.isEmpty) {
        return {
          'totalEstudiantes': 0,
          'promedioGrupo': 0.0,
          'totalTests': 0,
          'mejorDesempenio': 0.0,
          'peorDesempenio': 0.0,
        };
      }

      final promedios = reportes.map((r) => r.promedioGeneral).toList();
      final promedioGrupo = promedios.fold(0.0, (a, b) => a + b) / promedios.length;

      final totalTests = reportes.fold<int>(0, (sum, r) => sum + r.totalTestsRealizados);

      return {
        'totalEstudiantes': reportes.length,
        'promedioGrupo': promedioGrupo,
        'totalTests': totalTests,
        'mejorDesempenio': promedios.reduce((a, b) => a > b ? a : b),
        'peorDesempenio': promedios.reduce((a, b) => a < b ? a : b),
      };
    } catch (e) {
      print('❌ Error calculando estadísticas: $e');
      return {};
    }
  }

  /// Stream de estudiantes en tiempo real
  Stream<List<UserModel>> streamMisEstudiantes() {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'alumno')
        .where('maestroIds', arrayContains: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  /// Stream de reportes en tiempo real
  Stream<List<StudentReportModel>> streamReportesMisEstudiantes() {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) {
      return Stream.empty();
    }

    // Primero obtener IDs de estudiantes
    return _firestore
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'alumno')
        .where('maestroIds', arrayContains: teacherId)
        .snapshots()
        .asyncMap((studentSnapshot) async {
          final studentIds = studentSnapshot.docs.map((doc) => doc.id).toList();

          if (studentIds.isEmpty) {
            return [];
          }

          final reportSnapshot = await _firestore
              .collection('reportes_estudiantes')
              .where(FieldPath.documentId, whereIn: studentIds)
              .get();

          return reportSnapshot.docs
              .map((doc) => StudentReportModel.fromMap(doc.data()))
              .toList();
        });
  }

  /// Asignar estudiante al maestro (agrega al array maestroIds)
  Future<bool> asignarEstudiante(String studentId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      await _firestore.collection('usuarios').doc(studentId).update({
        'maestroIds': FieldValue.arrayUnion([teacherId]),
      });

      return true;
    } catch (e) {
      print('❌ Error asignando estudiante: $e');
      return false;
    }
  }

  /// Desasignar estudiante del maestro
  Future<bool> desasignarEstudiante(String studentId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      await _firestore.collection('usuarios').doc(studentId).update({
        'maestroIds': FieldValue.arrayRemove([teacherId]),
      });

      return true;
    } catch (e) {
      print('❌ Error desasignando estudiante: $e');
      return false;
    }
  }

  /// Obtener número total de estudiantes asignados
  Future<int> obtenerTotalMisEstudiantes() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .where('maestroIds', arrayContains: teacherId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error contando estudiantes: $e');
      return 0;
    }
  }
}
