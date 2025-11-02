# 🛠️ PLAN DE ACCIÓN DETALLADO - IMPLEMENTACIÓN DEL MAESTRO

**Objetivo**: Completar el módulo del Maestro en 1-2 semanas  
**Dificultad**: Media  
**Requerimientos Previos**: Flutter, Dart, Firestore, Provider

---

## 📅 SEMANA 1: Backend (5-7 días)

### DÍA 1-2: Expansión de `teacher_service.dart`

#### Paso 1.1: Métodos de Consulta Base

```dart
// Agregar a teacher_service.dart

/// Obtiene información del maestro autenticado
Future<Map<String, dynamic>> obtenerDatosMaestro() async {
  try {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final doc = await _firestore.collection('usuarios').doc(userId).get();
    if (!doc.exists) throw Exception('Maestro no encontrado');

    final data = doc.data()!;
    
    // Obtener número de estudiantes
    final studentSnap = await _firestore
        .collection('usuarios')
        .where('gradoNombre', whereIn: (data['gradosAsignados'] as List? ?? []))
        .where('tipoUsuario', isEqualTo: 'alumno')
        .count()
        .get();

    return {
      'id': userId,
      'nombre': data['nombre'] ?? 'Maestro',
      'email': data['email'] ?? '',
      'gradosAsignados': (data['gradosAsignados'] ?? []) as List,
      'categoriasAsignadas': (data['categoriasAsignadas'] ?? []) as List,
      'totalEstudiantes': studentSnap.count,
      'activo': data['activo'] ?? true,
    };
  } catch (e) {
    print('❌ Error obteniendo datos del maestro: $e');
    return {};
  }
}

/// Obtiene lista de grados asignados
Future<List<String>> obtenerGradosAsignados() async {
  try {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final doc = await _firestore.collection('usuarios').doc(userId).get();
    if (!doc.exists) return [];

    final data = doc.data() ?? {};
    return List<String>.from(data['gradosAsignados'] ?? []);
  } catch (e) {
    print('❌ Error obteniendo grados: $e');
    return [];
  }
}

/// Obtiene categorías que el maestro puede ver
Future<List<CategoryModel>> obtenerCategorias() async {
  try {
    final snapshot = await _firestore
        .collection('categorias')
        .orderBy('orden', descending: false)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return CategoryModel(
            id: data['id'] as String? ?? doc.id,
            nombre: data['nombre'] ?? 'Sin nombre',
            descripcion: data['descripcion'],
            grado: data['grado'],
          );
        })
        .toList();
  } catch (e) {
    print('❌ Error obteniendo categorías: $e');
    return [];
  }
}
```

#### Paso 1.2: Métodos de Estudiantes

```dart
/// Obtiene lista de estudiantes asignados al maestro
Future<List<Map<String, dynamic>>> obtenerEstudiantesAsignados({
  String? gradoFiltro,
  String? busqueda,
}) async {
  try {
    final maestroData = await obtenerDatosMaestro();
    final gradosAsignados = (maestroData['gradosAsignados'] as List?) ?? [];

    if (gradosAsignados.isEmpty) return [];

    // Query base: estudiantes del grado del maestro
    Query query = _firestore
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'alumno')
        .where('gradoNombre', whereIn: gradosAsignados);

    // Filtro adicional por grado si se especifica
    if (gradoFiltro != null && gradosAsignados.contains(gradoFiltro)) {
      query = _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .where('gradoNombre', isEqualTo: gradoFiltro);
    }

    final snapshot = await query.get();
    final estudiantes = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final userData = doc.data() as Map<String, dynamic>;
      
      // Obtener datos del reporte
      final reporteDoc = await _firestore
          .collection('reportes_estudiantes')
          .doc(doc.id)
          .get();

      final reporteData = reporteDoc.data() ?? {};
      
      final nombre = userData['nombre'] as String? ?? 'Sin nombre';
      
      // Filtro por búsqueda (nombre o email)
      if (busqueda != null && busqueda.isNotEmpty) {
        if (!nombre.toLowerCase().contains(busqueda.toLowerCase()) &&
            !(userData['email'] as String? ?? '')
                .toLowerCase()
                .contains(busqueda.toLowerCase())) {
          continue;
        }
      }

      estudiantes.add({
        'id': doc.id,
        'nombre': nombre,
        'email': userData['email'] ?? '',
        'grado': userData['gradoNombre'] ?? '',
        'totalTests': reporteData['totalTestsRealizados'] ?? 0,
        'aciertos': reporteData['totalAciertos'] ?? 0,
        'intentos': reporteData['totalIntentos'] ?? 0,
        'promedio': (reporteData['promedioGeneral'] ?? 0.0) as double,
        'ultimoTest': reporteData['fechaUltimoTest'],
        'desempenoPorCategoria': reporteData['desempenoPorCategoria'] ?? {},
      });
    }

    return estudiantes;
  } catch (e) {
    print('❌ Error obteniendo estudiantes: $e');
    return [];
  }
}

/// Obtiene detalles completos de un estudiante
Future<Map<String, dynamic>> obtenerDetalleEstudiante(String studentId) async {
  try {
    // Datos del estudiante
    final userDoc = await _firestore
        .collection('usuarios')
        .doc(studentId)
        .get();

    if (!userDoc.exists) return {};

    final userData = userDoc.data()!;

    // Reporte del estudiante
    final reporteDoc = await _firestore
        .collection('reportes_estudiantes')
        .doc(studentId)
        .get();

    final reporteData = reporteDoc.data() ?? {};

    return {
      'id': studentId,
      'nombre': userData['nombre'] ?? '',
      'email': userData['email'] ?? '',
      'grado': userData['gradoNombre'] ?? '',
      'fotoPerfil': userData['fotoPerfil'],
      // Estadísticas
      'totalTests': reporteData['totalTestsRealizados'] ?? 0,
      'totalAciertos': reporteData['totalAciertos'] ?? 0,
      'totalIntentos': reporteData['totalIntentos'] ?? 0,
      'promedioGeneral': (reporteData['promedioGeneral'] ?? 0.0) as double,
      'ultimoTest': reporteData['fechaUltimoTest'],
      'desempenoPorCategoria': reporteData['desempenoPorCategoria'] ?? {},
      'nivelDesempenio': _calcularNivel(
        reporteData['promedioGeneral'] as double? ?? 0.0,
      ),
    };
  } catch (e) {
    print('❌ Error obteniendo detalle de estudiante: $e');
    return {};
  }
}

String _calcularNivel(double porcentaje) {
  if (porcentaje >= 80) return 'Excelente';
  if (porcentaje >= 60) return 'Bueno';
  if (porcentaje >= 40) return 'Regular';
  return 'Necesita Mejorar';
}
```

#### Paso 1.3: Métodos de Reportes

```dart
/// Obtiene reporte consolidado grupal
Future<Map<String, dynamic>> obtenerReporteGrupal({
  String? gradoFiltro,
  String? categoriaFiltro,
}) async {
  try {
    final estudiantes = await obtenerEstudiantesAsignados(
      gradoFiltro: gradoFiltro,
    );

    if (estudiantes.isEmpty) {
      return {'error': 'No hay estudiantes'};
    }

    // Calcular promedios
    double promedioGrupal = 0;
    int totalTests = 0;
    int totalAciertos = 0;

    for (var est in estudiantes) {
      promedioGrupal += (est['promedio'] as double? ?? 0.0);
      totalTests += (est['totalTests'] as int? ?? 0);
      totalAciertos += (est['aciertos'] as int? ?? 0);
    }

    promedioGrupal /= estudiantes.length;

    // Top 3 mejores estudiantes
    final mejores = (estudiantes..sort((a, b) =>
        (b['promedio'] as double).compareTo(a['promedio'] as double)))
        .take(3)
        .toList();

    // Top 3 estudiantes con bajo desempeño
    final enRiesgo = (estudiantes..sort((a, b) =>
        (a['promedio'] as double).compareTo(b['promedio'] as double)))
        .take(3)
        .toList();

    return {
      'totalEstudiantes': estudiantes.length,
      'promedioGrupal': promedioGrupal.toStringAsFixed(2),
      'totalTests': totalTests,
      'totalAciertos': totalAciertos,
      'mejoresEstudiantes': mejores,
      'estudiantesEnRiesgo': enRiesgo,
      'nivelGrupal': _calcularNivel(promedioGrupal),
    };
  } catch (e) {
    print('❌ Error generando reporte grupal: $e');
    return {};
  }
}

/// Obtiene preguntas donde más fallan los estudiantes
Future<List<Map<String, dynamic>>> obtenerPreguntasDifficultosas({
  String? categoriaFiltro,
}) async {
  try {
    final estudiantes = await obtenerEstudiantesAsignados();
    
    // Map para contar errores por pregunta
    final erroresPorPregunta = <String, Map<String, dynamic>>{};

    for (var student in estudiantes) {
      final desempenoPorCat = 
          student['desempenoPorCategoria'] as Map<String, dynamic>? ?? {};

      // Aquí necesitarías guardar en Firestore qué preguntas falló
      // Por ahora retorna vacío
    }

    return [];
  } catch (e) {
    print('❌ Error obteniendo preguntas difíciles: $e');
    return [];
  }
}
```

#### Paso 1.4: Métodos de Retroalimentación

```dart
/// Guarda retroalimentación para un estudiante
Future<void> guardarRetroalimentacion({
  required String studentId,
  required String categoriaId,
  required String mensaje,
  DateTime? fechaVencimiento,
  String prioridad = 'normal',
}) async {
  try {
    final maestroId = _auth.currentUser?.uid;
    if (maestroId == null) throw Exception('No autenticado');

    final feedbackId = _firestore
        .collection('maestros')
        .doc(maestroId)
        .collection('retroalimentaciones')
        .doc()
        .id;

    await _firestore
        .collection('maestros')
        .doc(maestroId)
        .collection('retroalimentaciones')
        .doc(feedbackId)
        .set({
      'studentId': studentId,
      'categoriaId': categoriaId,
      'mensaje': mensaje,
      'fechaEnviada': DateTime.now(),
      'leida': false,
      'prioridad': prioridad,
      'fechaVencimiento': fechaVencimiento,
    });

    print('✅ Retroalimentación guardada');
  } catch (e) {
    print('❌ Error guardando retroalimentación: $e');
  }
}

/// Obtiene retroalimentaciones pendientes del maestro
Future<List<Map<String, dynamic>>> 
    obtenerRetroalimentacionesPendientes() async {
  try {
    final maestroId = _auth.currentUser?.uid;
    if (maestroId == null) return [];

    final snapshot = await _firestore
        .collection('maestros')
        .doc(maestroId)
        .collection('retroalimentaciones')
        .where('leida', isEqualTo: false)
        .orderBy('fechaEnviada', descending: true)
        .get();

    final retroalimentaciones = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Obtener datos del estudiante
      final studentDoc = await _firestore
          .collection('usuarios')
          .doc(data['studentId'] as String)
          .get();

      final studentData = studentDoc.data() ?? {};

      retroalimentaciones.add({
        'id': doc.id,
        'studentId': data['studentId'],
        'studentNombre': studentData['nombre'] ?? 'Desconocido',
        'categoriaId': data['categoriaId'],
        'mensaje': data['mensaje'],
        'fechaEnviada': data['fechaEnviada'],
        'prioridad': data['prioridad'],
      });
    }

    return retroalimentaciones;
  } catch (e) {
    print('❌ Error obteniendo retroalimentaciones: $e');
    return [];
  }
}

/// Marca retroalimentación como leída
Future<void> marcarRetroalimentacionLeida(String feedbackId) async {
  try {
    final maestroId = _auth.currentUser?.uid;
    if (maestroId == null) return;

    await _firestore
        .collection('maestros')
        .doc(maestroId)
        .collection('retroalimentaciones')
        .doc(feedbackId)
        .update({'leida': true});
  } catch (e) {
    print('❌ Error marcando retroalimentación como leída: $e');
  }
}
```

#### Paso 1.5: Métodos de Exportación

```dart
/// Exporta reporte grupal a Excel
Future<Uint8List> exportarReporteExcel({
  String? gradoFiltro,
}) async {
  try {
    final reporteData = await obtenerReporteGrupal(gradoFiltro: gradoFiltro);
    final estudiantes = await obtenerEstudiantesAsignados(
      gradoFiltro: gradoFiltro,
    );

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Reporte Grupal';

    // Configurar anchos
    sheet.getRangeByName('A1:A1000').columnWidth = 30;
    sheet.getRangeByName('B1:B1000').columnWidth = 20;
    sheet.getRangeByName('C1:C1000').columnWidth = 15;
    sheet.getRangeByName('D1:D1000').columnWidth = 15;
    sheet.getRangeByName('E1:E1000').columnWidth = 15;

    int row = 1;

    // Título
    sheet.getRangeByIndex(row, 1).setText('REPORTE GRUPAL - MAESTRO');
    var titleStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    titleStyle.fontSize = 18;
    titleStyle.bold = true;
    titleStyle.backColor = '#1F4E78';
    titleStyle.fontColor = '#FFFFFF';
    row += 2;

    // Encabezados
    sheet.getRangeByIndex(row, 1).setText('Estudiante');
    sheet.getRangeByIndex(row, 2).setText('Grado');
    sheet.getRangeByIndex(row, 3).setText('Tests');
    sheet.getRangeByIndex(row, 4).setText('Aciertos');
    sheet.getRangeByIndex(row, 5).setText('Promedio %');

    for (int col = 1; col <= 5; col++) {
      var headerStyle = sheet.getRangeByIndex(row, col).cellStyle;
      headerStyle.bold = true;
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = HAlignType.center;
    }
    row++;

    // Datos
    for (var est in estudiantes) {
      sheet.getRangeByIndex(row, 1).setText(est['nombre'] as String);
      sheet.getRangeByIndex(row, 2).setText(est['grado'] as String);
      sheet.getRangeByIndex(row, 3).setText((est['totalTests'] as int).toString());
      sheet.getRangeByIndex(row, 4).setText((est['aciertos'] as int).toString());
      sheet.getRangeByIndex(row, 5).setText(
        ((est['promedio'] as double).toStringAsFixed(2))
      );

      for (int col = 1; col <= 5; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.hAlign = HAlignType.center;
      }
      row++;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  } catch (e) {
    print('❌ Error exportando Excel: $e');
    return Uint8List.fromList([]);
  }
}
```

### DÍA 3: Testing del Backend

```dart
// test/services/teacher_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:planea_proyecto/src/services/teacher_service.dart';

void main() {
  group('TeacherService', () {
    late TeacherService teacherService;

    setUp(() {
      teacherService = TeacherService();
    });

    test('obtenerDatosMaestro retorna datos válidos', () async {
      final data = await teacherService.obtenerDatosMaestro();
      expect(data.isNotEmpty, true);
      expect(data.containsKey('nombre'), true);
    });

    test('obtenerEstudiantesAsignados retorna lista', () async {
      final estudiantes = await teacherService.obtenerEstudiantesAsignados();
      expect(estudiantes, isA<List>());
    });

    test('obtenerReporteGrupal calcula promedios correctamente', () async {
      final reporte = await teacherService.obtenerReporteGrupal();
      if (reporte.containsKey('promedioGrupal')) {
        final promedio = double.parse(reporte['promedioGrupal'] as String);
        expect(promedio, greaterThanOrEqualTo(0));
        expect(promedio, lessThanOrEqualTo(100));
      }
    });
  });
}
```

---

## 📱 SEMANA 2: Frontend (7-10 días)

### DÍA 1: `teacher_dashboard.dart`

```dart
import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../config/app_constants.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _teacherService = TeacherService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Dashboard Maestro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No hay notificaciones')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: _construirDrawer(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _teacherService.obtenerDatosMaestro(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final datosMaestro = snapshot.data ?? {};

          return SingleChildScrollView(
            child: Column(
              children: [
                // Cards KPI
                _construirKPICards(datosMaestro),
                
                // Últimos tests
                _construirUltimosTests(),
                
                // Estudiantes en riesgo
                _construirEstudiantesEnRiesgo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirKPICards(Map<String, dynamic> datos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _construirKPICard(
            '📚',
            'Categorías',
            '${(datos['categoriasAsignadas'] as List? ?? []).length}',
            Colors.blue,
          ),
          _construirKPICard(
            '👥',
            'Estudiantes',
            '${datos['totalEstudiantes'] ?? 0}',
            Colors.green,
          ),
          _construirKPICard(
            '📊',
            'Promedio',
            '00.0%',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _construirKPICard(
    String icon,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirUltimosTests() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos Tests Realizados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _teacherService.obtenerEstudiantesAsignados(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              final estudiantes = snapshot.data ?? [];
              if (estudiantes.isEmpty) {
                return const Text('No hay datos');
              }

              // Mostrar solo los 3 primeros
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estudiantes.take(3).length,
                itemBuilder: (context, index) {
                  final est = estudiantes[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(est['nombre'] as String),
                    subtitle: Text('${est['totalTests']} tests realizados'),
                    trailing: Text('${est['promedio']}%'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirEstudiantesEnRiesgo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Estudiantes que Necesitan Apoyo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _teacherService.obtenerReporteGrupal(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              final reporte = snapshot.data ?? {};
              final enRiesgo = (reporte['estudiantesEnRiesgo'] as List? ?? []);

              if (enRiesgo.isEmpty) {
                return const Text('Todos van bien! 🎉');
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enRiesgo.length,
                itemBuilder: (context, index) {
                  final est = enRiesgo[index] as Map<String, dynamic>;
                  return Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(est['nombre'] as String),
                      subtitle: Text('Promedio: ${est['promedio']}%'),
                      onTap: () {
                        // Navegar a detalle
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade600),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '📚 Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Maestro de Matemáticas',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('📊 Mis Reportes'),
            onTap: () {
              // TODO: Navegar a reportes
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('👥 Mis Estudiantes'),
            onTap: () {
              // TODO: Navegar a estudiantes
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('📬 Retroalimentaciones'),
            onTap: () {
              // TODO: Navegar a retroalimentaciones
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() {
    // TODO: Implementar logout
  }
}
```

### DÍA 2-3: Pantallas Reportes y Estudiantes

[Similar estructura para `teacher_reportes_pantalla.dart` y `teacher_estudiantes_asignados.dart`]

### DÍA 4-5: Detalle de Estudiante

[Implementación de gráficas y historial]

### DÍA 6: Retroalimentación

[Panel de mensajes y notificaciones]

---

## 🧪 SEMANA 3: Testing y Deploy

### Testing Completo
- Tests unitarios del servicio
- Tests de widgets
- Tests de integración

### Seguridad
- Validar reglas de Firestore
- Validar permisos de acceso
- Auditoría de cambios

### Deploy
- Testing en producción
- Validación final
- Launch

---

## ✅ CHECKLIST RÁPIDO

**Semana 1**:
- [ ] Expandir teacher_service.dart
- [ ] Crear métodos de consulta
- [ ] Crear métodos de reportes
- [ ] Crear métodos de exportación
- [ ] Testing básico

**Semana 2**:
- [ ] teacher_dashboard.dart
- [ ] teacher_reportes_pantalla.dart
- [ ] teacher_estudiantes_asignados.dart
- [ ] teacher_detalle_estudiante.dart
- [ ] teacher_retroalimentacion.dart

**Semana 3**:
- [ ] Pruebas completas
- [ ] Validaciones de seguridad
- [ ] Optimizaciones
- [ ] Deploy

---

**¡Éxito en la implementación! 🚀**
