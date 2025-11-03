import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/student_report_model.dart';
import '../models/reactive_model.dart';

/// Servicio para operaciones del maestro/docente
/// 
/// El maestro usa las MISMAS funcionalidades que el admin, pero:
/// - Estudiantes: Solo ve sus estudiantes asignados (maestroIds contiene su ID)
/// - Reactivos: Solo ve reactivos en sus categorías asignadas (categoriasAsignadas)
/// - Reportes: Solo accede a reportes de sus estudiantes
/// - Deshabilitar: NO elimina, solo marca inactivo (activo: false)
/// 
/// ARQUITECTURA: Reutiliza métodos del AdminService pero filtra por scope
class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== DATOS DEL MAESTRO ====================

  /// Obtener información del maestro actual
  Future<UserModel?> obtenerDatosMaestroActual() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('usuarios').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = userId;
      return UserModel.fromMap(data);
    } catch (e) {
      print('❌ Error obteniendo datos del maestro: $e');
      return null;
    }
  }

  // ==================== ESTUDIANTES ====================

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
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return UserModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  /// Buscar estudiantes asignados por nombre o email
  Future<List<UserModel>> buscarMisEstudiantes(String busqueda) async {
    try {
      final estudiantes = await obtenerMisEstudiantes();

      // Filtrar por búsqueda
      return estudiantes
          .where((est) =>
              est.nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
              est.email.toLowerCase().contains(busqueda.toLowerCase()))
          .toList();
    } catch (e) {
      print('❌ Error buscando estudiantes: $e');
      return [];
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

  /// Asignar estudiante al maestro (agrega al array maestroIds)
  Future<bool> asignarEstudiante(String studentId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      await _firestore.collection('usuarios').doc(studentId).update({
        'maestroIds': FieldValue.arrayUnion([teacherId]),
      });

      print('✅ Estudiante asignado correctamente');
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

      print('✅ Estudiante desasignado correctamente');
      return true;
    } catch (e) {
      print('❌ Error desasignando estudiante: $e');
      return false;
    }
  }

  /// Deshabilitar estudiante (solo para estudiantes asignados)
  /// No se elimina, solo se marca como inactivo
  Future<bool> deshabilitarEstudiante(String studentId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el estudiante está asignado a este maestro
      final estudianteDoc = await _firestore
          .collection('usuarios')
          .doc(studentId)
          .get();

      if (!estudianteDoc.exists) return false;

      final estudianteData = estudianteDoc.data() as Map<String, dynamic>;
      final maestroIds = estudianteData['maestroIds'] as List<dynamic>?;

      if (maestroIds == null || !maestroIds.contains(teacherId)) {
        throw Exception('No tienes acceso a este estudiante');
      }

      // Marcar como inactivo
      await _firestore.collection('usuarios').doc(studentId).update({
        'activo': false,
        'fechaDeshabilitacion': FieldValue.serverTimestamp(),
        'deshabilitadoPor': teacherId,
      });

      print('✅ Estudiante deshabilitado correctamente');
      return true;
    } catch (e) {
      print('❌ Error deshabilitando estudiante: $e');
      return false;
    }
  }

  /// Habilitar estudiante (solo para estudiantes asignados)
  Future<bool> habilitarEstudiante(String studentId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el estudiante está asignado a este maestro
      final estudianteDoc = await _firestore
          .collection('usuarios')
          .doc(studentId)
          .get();

      if (!estudianteDoc.exists) return false;

      final estudianteData = estudianteDoc.data() as Map<String, dynamic>;
      final maestroIds = estudianteData['maestroIds'] as List<dynamic>?;

      if (maestroIds == null || !maestroIds.contains(teacherId)) {
        throw Exception('No tienes acceso a este estudiante');
      }

      // Marcar como activo
      await _firestore.collection('usuarios').doc(studentId).update({
        'activo': true,
      });

      print('✅ Estudiante habilitado correctamente');
      return true;
    } catch (e) {
      print('❌ Error habilitando estudiante: $e');
      return false;
    }
  }

  // ==================== REPORTES ====================

  /// Obtener el reporte de un estudiante específico
  Future<StudentReportModel?> obtenerReporteEstudiante(String estudianteId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el estudiante está asignado a este maestro
      final estudianteDoc = await _firestore
          .collection('usuarios')
          .doc(estudianteId)
          .get();

      if (!estudianteDoc.exists) return null;

      final estudianteData = estudianteDoc.data() as Map<String, dynamic>;
      final maestroIds = estudianteData['maestroIds'] as List<dynamic>?;

      if (maestroIds == null || !maestroIds.contains(teacherId)) {
        throw Exception('No tienes acceso a este estudiante');
      }

      // Obtener reporte
      final reporteDoc = await _firestore
          .collection('reportes_estudiantes')
          .doc(estudianteId)
          .get();

      if (!reporteDoc.exists) return null;

      final data = reporteDoc.data() as Map<String, dynamic>;
      data['id'] = reporteDoc.id;

      return StudentReportModel.fromMap(data);
    } catch (e) {
      print('❌ Error obteniendo reporte del estudiante: $e');
      return null;
    }
  }

  /// Obtener desempeño general de un estudiante
  Future<Map<String, dynamic>> obtenerDesempenoEstudiante(String estudianteId) async {
    try {
      final reporte = await obtenerReporteEstudiante(estudianteId);
      if (reporte == null) return {};

      return {
        'totalAciertos': reporte.totalAciertos,
        'totalIntentos': reporte.totalIntentos,
        'promedioGeneral': reporte.promedioGeneral,
        'totalTests': reporte.totalTestsRealizados,
        'nivel': reporte.obtenerNivelDesempenio(),
        'ultimoTest': reporte.fechaUltimoTest,
      };
    } catch (e) {
      print('❌ Error obteniendo desempeño: $e');
      return {};
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

  /// Obtener estadísticas del grupo (todos los estudiantes del maestro)
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

  // ==================== VALIDACIÓN DE MAESTROS ====================

  /// Obtener maestros pendientes de validación (solo si el maestro actual está aprobado)
  Future<List<UserModel>> obtenerMaestrosPendientes() async {
    try {
      final maestroActual = await obtenerDatosMaestroActual();

      // Solo maestros aprobados pueden validar a otros
      if (maestroActual?.aprobado != true) {
        throw Exception('Solo maestros aprobados pueden validar otros maestros');
      }

      // Obtener maestros no aprobados
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'maestro')
          .where('aprobado', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return UserModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('❌ Error obteniendo maestros pendientes: $e');
      return [];
    }
  }

  /// Aprobar un maestro (solo si el maestro actual está aprobado)
  Future<bool> aprobarMaestro(String maestroId) async {
    try {
      final maestroActual = await obtenerDatosMaestroActual();

      // Verificar que el maestro actual está aprobado
      if (maestroActual?.aprobado != true) {
        throw Exception('Solo maestros aprobados pueden validar otros maestros');
      }

      // Actualizar estado del maestro
      await _firestore.collection('usuarios').doc(maestroId).update({
        'aprobado': true,
        'fechaAprobacion': FieldValue.serverTimestamp(),
        'aprobadoPor': _auth.currentUser?.uid,
      });

      print('✅ Maestro aprobado correctamente');
      return true;
    } catch (e) {
      print('❌ Error aprobando maestro: $e');
      return false;
    }
  }

  /// Rechazar un maestro (solo si el maestro actual está aprobado)
  Future<bool> rechazarMaestro(String maestroId, String razon) async {
    try {
      final maestroActual = await obtenerDatosMaestroActual();

      // Verificar que el maestro actual está aprobado
      if (maestroActual?.aprobado != true) {
        throw Exception('Solo maestros aprobados pueden validar otros maestros');
      }

      // Actualizar estado del maestro
      await _firestore.collection('usuarios').doc(maestroId).update({
        'aprobado': false,
        'estado': 'rechazado',
        'razonRechazo': razon,
        'fechaRechazo': FieldValue.serverTimestamp(),
        'rechazadoPor': _auth.currentUser?.uid,
      });

      print('✅ Maestro rechazado correctamente');
      return true;
    } catch (e) {
      print('❌ Error rechazando maestro: $e');
      return false;
    }
  }

  // ==================== REACTIVOS ====================

  /// Obtener reactivos de las categorías asignadas al maestro
  /// Los reactivos deben estar activos y en categorías que el maestro pueda ver
  Future<List<ReactiveModel>> obtenerMisReactivos({String? categoryId}) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Obtener datos del maestro para saber sus categorías asignadas
      final maestroDoc = await _firestore
          .collection('usuarios')
          .doc(teacherId)
          .get();

      if (!maestroDoc.exists) return [];

      final maestroData = maestroDoc.data() as Map<String, dynamic>;
      final categoriasAsignadas = maestroData['categoriasAsignadas'] as List<dynamic>? ?? [];

      // Si se especifica una categoría, verificar que esté asignada
      if (categoryId != null) {
        if (!categoriasAsignadas.contains(categoryId)) {
          throw Exception('No tienes acceso a esta categoría');
        }
      }

      // Obtener reactivos activos
      Query query = _firestore
          .collection('reactivos')
          .where('activa', isEqualTo: true);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      } else if (categoriasAsignadas.isNotEmpty) {
        query = query.where('categoryId', whereIn: categoriasAsignadas);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ReactiveModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo reactivos: $e');
      return [];
    }
  }

  /// Crear nuevo reactivo en una categoría asignada
  Future<bool> crearReactivo({
    required String categoryId,
    required String pregunta,
    required List<String> opciones,
    required int respuestaCorrecta,
    required int dificultad,
    String? explicacion,
  }) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el maestro tiene acceso a esta categoría
      final maestroDoc = await _firestore
          .collection('usuarios')
          .doc(teacherId)
          .get();

      if (!maestroDoc.exists) throw Exception('Maestro no encontrado');

      final maestroData = maestroDoc.data() as Map<String, dynamic>;
      final categoriasAsignadas = maestroData['categoriasAsignadas'] as List<dynamic>? ?? [];

      if (!categoriasAsignadas.contains(categoryId)) {
        throw Exception('No tienes acceso a esta categoría');
      }

      // Crear reactivo
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
        creadoPor: teacherId,
      );

      await _firestore
          .collection('reactivos')
          .doc(nuevoReactivo.id)
          .set(nuevoReactivo.toMap());

      print('✅ Reactivo creado correctamente');
      return true;
    } catch (e) {
      print('❌ Error creando reactivo: $e');
      return false;
    }
  }

  /// Actualizar un reactivo existente
  Future<bool> actualizarReactivo({
    required String id,
    required String pregunta,
    required List<String> opciones,
    required int respuestaCorrecta,
    required int dificultad,
    String? explicacion,
  }) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el reactivo existe y fue creado por este maestro
      final reactivoDoc = await _firestore
          .collection('reactivos')
          .doc(id)
          .get();

      if (!reactivoDoc.exists) return false;

      final reactivoData = reactivoDoc.data() as Map<String, dynamic>;
      if (reactivoData['creadoPor'] != teacherId) {
        throw Exception('Solo puedes editar reactivos que creaste');
      }

      // Verificar que el maestro tiene acceso a la categoría del reactivo
      final maestroDoc = await _firestore
          .collection('usuarios')
          .doc(teacherId)
          .get();

      if (!maestroDoc.exists) throw Exception('Maestro no encontrado');

      final maestroData = maestroDoc.data() as Map<String, dynamic>;
      final categoriasAsignadas = maestroData['categoriasAsignadas'] as List<dynamic>? ?? [];
      
      if (!categoriasAsignadas.contains(reactivoData['categoryId'])) {
        throw Exception('No tienes acceso a esta categoría');
      }

      // Actualizar reactivo
      await _firestore.collection('reactivos').doc(id).update({
        'pregunta': pregunta,
        'opciones': opciones,
        'respuestaCorrecta': respuestaCorrecta,
        'dificultad': dificultad,
        'explicacion': explicacion,
      });

      print('✅ Reactivo actualizado correctamente');
      return true;
    } catch (e) {
      print('❌ Error actualizando reactivo: $e');
      return false;
    }
  }

  /// Deshabilitar reactivo (marcar como inactivo)
  Future<bool> deshabilitarReactivo(String reactivoId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el reactivo fue creado por este maestro
      final reactivoDoc = await _firestore
          .collection('reactivos')
          .doc(reactivoId)
          .get();

      if (!reactivoDoc.exists) return false;

      final reactivoData = reactivoDoc.data() as Map<String, dynamic>;
      if (reactivoData['creadoPor'] != teacherId) {
        throw Exception('Solo puedes deshabilitar reactivos que creaste');
      }

      // Deshabilitar reactivo
      await _firestore.collection('reactivos').doc(reactivoId).update({
        'activa': false,
        'fechaDeshabilitacion': FieldValue.serverTimestamp(),
      });

      print('✅ Reactivo deshabilitado correctamente');
      return true;
    } catch (e) {
      print('❌ Error deshabilitando reactivo: $e');
      return false;
    }
  }

  /// Habilitar reactivo
  Future<bool> habilitarReactivo(String reactivoId) async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      // Verificar que el reactivo fue creado por este maestro
      final reactivoDoc = await _firestore
          .collection('reactivos')
          .doc(reactivoId)
          .get();

      if (!reactivoDoc.exists) return false;

      final reactivoData = reactivoDoc.data() as Map<String, dynamic>;
      if (reactivoData['creadoPor'] != teacherId) {
        throw Exception('Solo puedes habilitar reactivos que creaste');
      }

      // Habilitar reactivo
      await _firestore.collection('reactivos').doc(reactivoId).update({
        'activa': true,
      });

      print('✅ Reactivo habilitado correctamente');
      return true;
    } catch (e) {
      print('❌ Error habilitando reactivo: $e');
      return false;
    }
  }

  /// Obtener número total de reactivos creados por el maestro
  Future<int> obtenerTotalMisReactivos() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) throw Exception('Maestro no autenticado');

      final snapshot = await _firestore
          .collection('reactivos')
          .where('creadoPor', isEqualTo: teacherId)
          .where('activa', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error contando reactivos: $e');
      return 0;
    }
  }

  // ==================== STREAMS EN TIEMPO REAL ====================

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
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return UserModel.fromMap(data);
            })
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
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return StudentReportModel.fromMap(data);
              })
              .toList();
        });
  }
}
