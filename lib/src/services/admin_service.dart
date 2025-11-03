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

  // ==================== HELPERS ====================

  /// Infiere el gradoNombre completo basándose en el gradoId
  /// Ejemplos: 
  /// - '6P' → 'Primaria'
  /// - '3S' → 'Secundaria' 
  /// - '12EMS' → 'Preparatoria'
  /// - '1Prep' → 'Preparatoria'
  String inferirGradoNombre(String gradoId) {
    // Eliminar espacios y convertir a mayúsculas para comparación
    final id = gradoId.trim().toUpperCase();
    
    // Preparatoria: contiene "PREP" o "EMS"
    if (id.contains('PREP') || id.contains('EMS')) {
      return 'Preparatoria';
    }
    
    // Primaria: termina en "P" (pero no es "PREP")
    if (id.endsWith('P')) {
      return 'Primaria';
    }
    
    // Secundaria: termina en "S" (pero no contiene "EMS")
    if (id.endsWith('S')) {
      return 'Secundaria';
    }
    
    // Por defecto, retornar vacío (se manejará como caso especial)
    return '';
  }

  /// Extrae el número de grado del gradoId
  /// Ejemplos:
  /// - '6P' → 6
  /// - '3S' → 3
  /// - '12EMS' → 12 (o 3 si queremos el año de preparatoria)
  /// - '1Prep' → 1
  int? extraerNumeroGrado(String gradoId) {
    // Eliminar espacios
    final id = gradoId.trim();
    
    // Extraer todos los dígitos
    final digitos = id.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitos.isEmpty) return null;
    
    return int.tryParse(digitos);
  }

  /// Genera una descripción completa del grado
  /// Ejemplos:
  /// - '6P' → '6° de Primaria'
  /// - '3S' → '3° de Secundaria'
  /// - '12EMS' → '3° de Preparatoria'
  String generarDescripcionGrado(String gradoId) {
    final nivel = inferirGradoNombre(gradoId);
    final numero = extraerNumeroGrado(gradoId);
    
    if (nivel.isEmpty || numero == null) {
      return gradoId; // Fallback al ID original
    }
    
    // Para EMS, convertir 10→1°, 11→2°, 12→3°
    int gradoMostrar = numero;
    if (gradoId.toUpperCase().contains('EMS')) {
      gradoMostrar = numero - 9; // 10→1, 11→2, 12→3
    }
    
    return '$gradoMostrar° de $nivel';
  }

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

      // ✅ AUTOMÁTICO: Inferir gradoNombre desde gradoId
      final gradoNombre = inferirGradoNombre(gradoId);
      
      print('✅ Creando estudiante: gradoId="$gradoId" → gradoNombre="$gradoNombre"');

      final nuevoEstudiante = UserModel(
        id: userCredential.user!.uid,
        nombre: nombre,
        email: email,
        tipoUsuario: 'alumno',
        gradoId: gradoId,
        gradoNombre: gradoNombre.isNotEmpty ? gradoNombre : null, // Solo establecer si se infirió correctamente
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
      // ✅ AUTOMÁTICO: Inferir gradoNombre desde gradoId
      final gradoNombre = inferirGradoNombre(gradoId);
      
      print('✅ Actualizando estudiante: gradoId="$gradoId" → gradoNombre="$gradoNombre"');
      
      final updateData = <String, dynamic>{
        'nombre': nombre,
        'gradoId': gradoId,
        'gradoNombre': gradoNombre.isNotEmpty ? gradoNombre : null, // Actualizar también gradoNombre
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

  /// ✨ NUEVO: Obtener maestros pendientes de aprobación
  Future<List<UserModel>> obtenerMaestrosPendientes() async {
    try {
      print('🔍 Buscando maestros pendientes...');
      
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'maestro')
          .where('aprobado', isEqualTo: false)
          .where('activo', isEqualTo: true)
          .get();

      print('📊 Encontrados ${snapshot.docs.length} maestros pendientes');
      
      final maestros = snapshot.docs
          .map((doc) {
            // ✨ IMPORTANTE: Incluir el ID del documento en los datos
            final data = doc.data();
            data['id'] = doc.id; // Agregar el ID
            
            print('👨‍🏫 Maestro: ${data['nombre']} - Email: ${data['email']} - ID: ${doc.id}');
            return UserModel.fromMap(data);
          })
          .toList();
      
      return maestros;
    } catch (e) {
      print('❌ Error al obtener maestros pendientes: $e');
      return [];
    }
  }

  /// ✨ NUEVO: Aprobar maestro
  Future<bool> aprobarMaestro(String maestroId) async {
    try {
      await _firestore.collection('usuarios').doc(maestroId).update({
        'aprobado': true,
        'fechaAprobacion': DateTime.now(),
      });

      print('✅ Maestro $maestroId aprobado');
      return true;
    } catch (e) {
      print('Error al aprobar maestro: $e');
      return false;
    }
  }

  /// ✨ NUEVO: Rechazar maestro (marcar como inactivo)
  Future<bool> rechazarMaestro(String maestroId) async {
    try {
      await _firestore.collection('usuarios').doc(maestroId).update({
        'activo': false,
        'fechaRechazo': DateTime.now(),
      });

      print('❌ Maestro $maestroId rechazado');
      return true;
    } catch (e) {
      print('Error al rechazar maestro: $e');
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

  /// Obtener todas las categorías desde Firestore
  /// Si no hay categorías en Firestore, devuelve las predefinidas
  Future<List<CategoryModelV2>> obtenerCategorias() async {
    try {
      final snapshot = await _firestore.collection('categorias').get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay categorías en Firestore, usar las default
        return CategoryModelV2.categoriasDefault();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CategoryModelV2(
          id: doc.id,
          nombre: data['nombre'] as String? ?? '',
          descripcion: data['descripcion'] as String? ?? '',
          icono: data['icono'] as String? ?? '📐',
          orden: data['orden'] as int? ?? 0,
          activa: data['activa'] as bool? ?? true,
          fechaCreacion: data['fechaCreacion'] != null 
              ? (data['fechaCreacion'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error al obtener categorías: $e');
      // En caso de error, devolver categorías default
      return CategoryModelV2.categoriasDefault();
    }
  }

  /// Obtener número de reactivos por categoría
  Future<Map<String, int>> obtenerReactivosPorCategoria() async {
    try {
      final result = <String, int>{};
      // Usar categorías desde Firestore
      final categorias = await obtenerCategorias();

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

  /// Stream de todos los usuarios (estudiantes y maestros) en tiempo real
  Stream<List<UserModel>> streamUsuarios() {
    return _firestore
        .collection('usuarios')
        .where('tipoUsuario', whereIn: ['alumno', 'maestro'])
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

  /// ✨ NUEVO: Función de migración para actualizar categorías con el campo 'grado'
  /// Útil si las categorías existen pero no tienen el campo grado especificado
  Future<void> migrarCategoriasConGrado() async {
    try {
      print('📊 Iniciando migración de categorías...');
      
      final snapshot = await _firestore.collection('categorias').get();
      
      // Mapeo de categorías a sus grados correspondientes
      final gradoPorCategoria = {
        'algebra': 'Primaria',
        'geometria': 'Primaria',
        'estadistica': 'Primaria',
        // Agregar más según sea necesario
      };

      for (var doc in snapshot.docs) {
        final id = doc.id;
        final grado = gradoPorCategoria[id];

        if (grado != null) {
          await _firestore.collection('categorias').doc(id).update({
            'grado': grado,
          });
          print('✅ Actualizada categoría $id con grado: $grado');
        }
      }

      print('✅ Migración completada');
    } catch (e) {
      print('❌ Error en migración: $e');
    }
  }

  /// Migra usuarios que no tienen gradoNombre basándose en su gradoId
  Future<void> migrarGradoNombreUsuarios() async {
    try {
      print('📊 Iniciando migración de gradoNombre para usuarios...');
      
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .get();

      int actualizados = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final gradoNombre = data['gradoNombre'] as String?;
        final gradoId = data['gradoId'] as String?;
        final nombre = data['nombre'] as String? ?? 'Sin nombre';

        // Solo actualizar si no tiene gradoNombre pero sí tiene gradoId
        if ((gradoNombre == null || gradoNombre.isEmpty) && gradoId != null && gradoId.isNotEmpty) {
          String nuevoGradoNombre = '';

          // Inferir gradoNombre basado en gradoId
          if (gradoId.endsWith('P') && gradoId != 'Prep' && !gradoId.contains('EMS')) {
            nuevoGradoNombre = 'Primaria';
          } else if (gradoId.endsWith('S') && !gradoId.contains('EMS')) {
            nuevoGradoNombre = 'Secundaria';
          } else if (gradoId.contains('Prep') || gradoId.contains('EMS')) {
            nuevoGradoNombre = 'Preparatoria';
          }

          if (nuevoGradoNombre.isNotEmpty) {
            await _firestore.collection('usuarios').doc(doc.id).update({
              'gradoNombre': nuevoGradoNombre,
            });
            actualizados++;
            print('✅ Actualizado $nombre (gradoId: $gradoId) -> gradoNombre: $nuevoGradoNombre');
          }
        }
      }

      print('✅ Migración completada. Usuarios actualizados: $actualizados');
    } catch (e) {
      print('❌ Error en migración de gradoNombre: $e');
    }
  }
}

