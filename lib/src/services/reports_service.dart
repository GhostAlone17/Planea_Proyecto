import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'dart:html' as html;
import 'dart:typed_data';

/// Servicio para generar reportes en PDF y Excel
/// Solo accesible por Maestro y Admin
class ReportsService {
  final _firestore = FirebaseFirestore.instance;

  // ==================== MÉTODOS AUXILIARES ====================

  /// Obtiene lista de grados únicos desde la colección de usuarios
  Future<List<String>> obtenerGradosDisponibles() async {
    try {
      print('🔍 DEBUG - Consultando todos los alumnos...');
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'alumno')
          .get();
      
      print('🔍 DEBUG - Total de alumnos encontrados: ${snapshot.docs.length}');

      final gradosSet = <String>{};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          var grado = data['gradoNombre'] as String?;
          final gradoId = data['gradoId'] as String?;
          final nombre = data['nombre'] as String? ?? 'Sin nombre';
          
          // Si no tiene gradoNombre, inferir del gradoId
          if (grado == null || grado.isEmpty) {
            if (gradoId != null && gradoId.isNotEmpty) {
              if (gradoId.endsWith('P') && gradoId != 'Prep' && !gradoId.contains('EMS')) {
                grado = 'Primaria';
              } else if (gradoId.endsWith('S') && !gradoId.contains('EMS')) {
                grado = 'Secundaria';
              } else if (gradoId.contains('Prep') || gradoId.contains('EMS')) {
                grado = 'Preparatoria';
              }
            }
          }
          
          print('   📄 Alumno: $nombre, gradoNombre: "${grado ?? "NULL"}", gradoId: "${gradoId ?? "NULL"}"');
          
          if (grado != null && grado.isNotEmpty) {
            gradosSet.add(grado);
          }
        } catch (e) {
          // Ignorar documentos sin gradoNombre
          print('   ⚠️ Documento ${doc.id} no tiene gradoNombre: $e');
        }
      }

      final gradosList = gradosSet.toList()..sort();
      print('🔍 DEBUG - Grados únicos encontrados: $gradosList');
      return gradosList.isEmpty ? ['Sin grado asignado'] : gradosList;
    } catch (e) {
      print('❌ Error obteniendo grados disponibles: $e');
      return ['Sin grado asignado'];
    }
  }

  // ==================== REPORTE GENERAL ====================

  /// Obtiene datos generales consolidados de un grado
  Future<Map<String, dynamic>> obtenerReporteGeneral({
    required String gradoNombre,
  }) async {
    try {
      print('🔍 DEBUG - Buscando estudiantes para grado: "$gradoNombre"');
      final estudiantes = await obtenerEstudiantesPorGrado(gradoNombre: gradoNombre);
      print('🔍 DEBUG - Estudiantes encontrados: ${estudiantes.length}');
      final desempenoPorCategoria = await obtenerDesempenoPorCategoria(gradoNombre: gradoNombre);

      int totalTests = 0;
      int totalAciertos = 0;
      int totalIntentos = 0;
      double promedioGeneral = 0.0;

      for (var est in estudiantes) {
        totalTests += est['totalTests'] as int;
        totalAciertos += est['aciertos'] as int;
        totalIntentos += est['total'] as int;
        promedioGeneral += est['porcentaje'] as double;
      }

      if (estudiantes.isNotEmpty) {
        promedioGeneral /= estudiantes.length;
      }

      return {
        'grado': gradoNombre,
        'totalEstudiantes': estudiantes.length,
        'totalTests': totalTests,
        'totalAciertos': totalAciertos,
        'totalIntentos': totalIntentos,
        'promedioGeneral': promedioGeneral,
        'categorias': desempenoPorCategoria.length,
        'estudiantes': estudiantes,
        'desempenoPorCategoria': desempenoPorCategoria,
      };
    } catch (e) {
      print('❌ Error obteniendo reporte general: $e');
      return {};
    }
  }

  /// Obtiene reporte consolidado de TODOS los grados
  Future<Map<String, dynamic>> obtenerReporteTodosGrados() async {
    try {
      // ✅ FIJO: Incluir TODOS los grados SIEMPRE, aunque no tengan estudiantes
      final grados = ['Primaria', 'Secundaria', 'Preparatoria'];
      final reportesPorGrado = <String, Map<String, dynamic>>{};
      
      int totalEstudiantesGlobal = 0;
      int totalTestsGlobal = 0;
      int totalAciertosGlobal = 0;
      int totalIntentosGlobal = 0;

      print('🔍 DEBUG CONSOLIDADO - Generando reporte para todos los grados: $grados');

      for (var grado in grados) {
        final reporte = await obtenerReporteGeneral(gradoNombre: grado);
        reportesPorGrado[grado] = reporte;
        
        print('   📊 Grado: $grado - Estudiantes: ${reporte['totalEstudiantes'] ?? 0}');
        
        if (reporte.isNotEmpty) {
          totalEstudiantesGlobal += reporte['totalEstudiantes'] as int;
          totalTestsGlobal += reporte['totalTests'] as int;
          totalAciertosGlobal += reporte['totalAciertos'] as int;
          totalIntentosGlobal += reporte['totalIntentos'] as int;
        }
      }

      final promedioGlobal = totalIntentosGlobal > 0 
          ? (totalAciertosGlobal / totalIntentosGlobal * 100) 
          : 0.0;

      return {
        'totalEstudiantes': totalEstudiantesGlobal,
        'totalTests': totalTestsGlobal,
        'totalAciertos': totalAciertosGlobal,
        'totalIntentos': totalIntentosGlobal,
        'promedioGeneral': promedioGlobal,
        'reportesPorGrado': reportesPorGrado,
      };
    } catch (e) {
      print('❌ Error obteniendo reporte de todos los grados: $e');
      return {};
    }
  }

  /// Genera reporte de desempeño por categoría
  /// 🔄 AHORA DINÁMICO: Obtiene categorías de Firestore sin hardcoding
  Future<Map<String, dynamic>> obtenerDesempenoPorCategoria({
    required String gradoNombre,
  }) async {
    try {
      // Obtener todas las categorías desde Firestore (dinámico)
      final categoriasSnapshot = await _firestore
          .collection('categorias')
          .orderBy('orden', descending: false)
          .get();

      final reporteData = <String, dynamic>{};

      // Primero, obtener estudiantes del grado
      print('🔍 DEBUG CATEGORIAS - Buscando estudiantes para grado: "$gradoNombre"');
      var estudiantesSnapshot = await _firestore
          .collection('usuarios')
          .where('gradoNombre', isEqualTo: gradoNombre)
          .where('tipoUsuario', isEqualTo: 'alumno')
          .get();
      
      print('🔍 DEBUG CATEGORIAS - Estudiantes encontrados con gradoNombre: ${estudiantesSnapshot.docs.length}');
      
      // Si no encuentra, intentar con gradoId (respaldo legacy)
      if (estudiantesSnapshot.docs.isEmpty) {
        print('⚠️ No se encontraron estudiantes con gradoNombre, intentando con gradoId...');
        
        List<String> gradoIds = [];
        if (gradoNombre.toLowerCase() == 'primaria') {
          gradoIds = ['1P', '2P', '3P', '4P', '5P', '6P'];
        } else if (gradoNombre.toLowerCase() == 'secundaria') {
          gradoIds = ['1S', '2S', '3S'];
        } else if (gradoNombre.toLowerCase() == 'preparatoria') {
          gradoIds = ['1Prep', '2Prep', '3Prep', '10EMS', '11EMS', '12EMS'];
        }
        
        if (gradoIds.isNotEmpty) {
          estudiantesSnapshot = await _firestore
              .collection('usuarios')
              .where('tipoUsuario', isEqualTo: 'alumno')
              .where('gradoId', whereIn: gradoIds)
              .get();
          
          print('🔍 DEBUG CATEGORIAS - Estudiantes encontrados con gradoId: ${estudiantesSnapshot.docs.length}');
        }
      }

      for (var doc in categoriasSnapshot.docs) {
        final categoriaId = doc.id;
        final nombreCategoria = doc['nombre'] ?? 'Sin nombre';

        int totalAciertos = 0;
        int totalIntentos = 0;
        final estudiantesInfo = <String, Map<String, dynamic>>{};

        // ✅ NUEVO: Iterar sobre estudiantes del grado y obtener su desempeño por categoría
        int estudiantesConDatos = 0;
        int estudiantesSinDatos = 0;
        
        for (var estudianteDoc in estudiantesSnapshot.docs) {
          final nombreEstudiante = estudianteDoc.data()['nombre'] as String? ?? 'Sin nombre';
          final estudianteId = estudianteDoc.id;
          
          final reporteRef = await _firestore
              .collection('reportes_estudiantes')
              .doc(estudianteId)
              .get();

          if (reporteRef.exists) {
            final reporteData = reporteRef.data() ?? {};
            final desempenoPorCategoria = reporteData['desempenoPorCategoria'] as Map<String, dynamic>? ?? {};
            
            if (desempenoPorCategoria.containsKey(categoriaId)) {
              final categoryPerformance = desempenoPorCategoria[categoriaId] as Map<String, dynamic>? ?? {};
              final aciertos = categoryPerformance['aciertos'] as int? ?? 0;
              final intentos = categoryPerformance['intentos'] as int? ?? 0;

              totalAciertos += aciertos;
              totalIntentos += intentos;

              // Usar ID en lugar del nombre para evitar duplicados cuando hay nombres iguales
              estudiantesInfo[estudianteId] = {
                'nombre': nombreEstudiante,
                'aciertos': aciertos,
                'intentos': intentos,
                'porcentaje': intentos > 0 ? (aciertos / intentos * 100) : 0.0,
              };
              estudiantesConDatos++;
            } else {
              estudiantesSinDatos++;
            }
          } else {
            estudiantesSinDatos++;
          }
        }
        
        // Log informativo
        if (estudiantesConDatos > 0 || estudiantesSinDatos > 0) {
          print('   📊 Categoría "$nombreCategoria": $estudiantesConDatos con datos, $estudiantesSinDatos sin datos');
        }

        if (estudiantesInfo.isNotEmpty) {
          reporteData[nombreCategoria] = {
            'categoryId': categoriaId,
            'totalAciertos': totalAciertos,
            'totalIntentos': totalIntentos,
            'porcentajeGeneral': totalIntentos > 0 ? (totalAciertos / totalIntentos * 100) : 0.0,
            'estudiantes': estudiantesInfo,
            'totalEstudiantes': estudiantesInfo.length,
          };
        }
      }

      return reporteData;
    } catch (e) {
      print('❌ Error obteniendo desempeño por categoría: $e');
      return {};
    }
  }

  // ==================== REPORTES POR ESTUDIANTE ====================

  /// Obtiene datos de estudiantes para reporte
  Future<List<Map<String, dynamic>>> obtenerEstudiantesPorGrado({
    required String gradoNombre,
  }) async {
    try {
      print('🔍 DEBUG - Query: gradoNombre == "$gradoNombre" AND tipoUsuario == "alumno"');
      
      // Primero intentar buscar por gradoNombre
      var snapshot = await _firestore
          .collection('usuarios')
          .where('gradoNombre', isEqualTo: gradoNombre)
          .where('tipoUsuario', isEqualTo: 'alumno')
          .get();
      
      print('🔍 DEBUG - Documentos encontrados con gradoNombre: ${snapshot.docs.length}');
      
      // Si no encuentra, intentar con gradoId (mapeo de legacy)
      if (snapshot.docs.isEmpty) {
        print('⚠️ No se encontraron estudiantes con gradoNombre, intentando con gradoId...');
        
        // Mapeo de gradoNombre a gradoId posibles
        List<String> gradoIds = [];
        if (gradoNombre.toLowerCase() == 'primaria') {
          gradoIds = ['1P', '2P', '3P', '4P', '5P', '6P'];
        } else if (gradoNombre.toLowerCase() == 'secundaria') {
          gradoIds = ['1S', '2S', '3S'];
        } else if (gradoNombre.toLowerCase() == 'preparatoria') {
          gradoIds = ['1Prep', '2Prep', '3Prep', '10EMS', '11EMS', '12EMS'];
        }
        
        if (gradoIds.isNotEmpty) {
          snapshot = await _firestore
              .collection('usuarios')
              .where('tipoUsuario', isEqualTo: 'alumno')
              .where('gradoId', whereIn: gradoIds)
              .get();
          
          print('🔍 DEBUG - Documentos encontrados con gradoId (${gradoIds.join(", ")}): ${snapshot.docs.length}');
        }
      }
      
      // Log de muestra de los primeros documentos
      for (var i = 0; i < snapshot.docs.length && i < 3; i++) {
        final doc = snapshot.docs[i];
        print('   📄 Estudiante ${i + 1}: ${doc.data()['nombre']} - gradoNombre: "${doc.data()['gradoNombre']}", gradoId: "${doc.data()['gradoId']}"');
      }

      final estudiantes = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final nombre = doc['nombre'] as String? ?? 'Sin nombre';
        final email = doc['email'] as String? ?? '';

        // ✅ NUEVO: Obtener datos del reporte del estudiante (estructura actualizada)
        final reporteDoc = await _firestore
            .collection('reportes_estudiantes')
            .doc(doc.id)
            .get();

        int totalAciertos = 0;
        int totalIntentos = 0;
        int totalTests = 0;
        double porcentaje = 0.0;

        if (reporteDoc.exists) {
          final data = reporteDoc.data() ?? {};
          totalAciertos = data['totalAciertos'] as int? ?? 0;
          totalIntentos = data['totalIntentos'] as int? ?? 0;
          totalTests = data['totalTestsRealizados'] as int? ?? 0;
          porcentaje = data['promedioGeneral'] as double? ?? 0.0;
          print('   ✅ Reporte encontrado para $nombre: $totalTests tests, $totalAciertos aciertos, ${porcentaje.toStringAsFixed(1)}%');
        } else {
          print('   ℹ️ $nombre aún no ha realizado tests (sin datos de reporte)');
        }

        // ✅ INCLUIR estudiante incluso si no tiene reporte (mostrará 0 tests)
        estudiantes.add({
          'id': doc.id,
          'nombre': nombre,
          'email': email,
          'totalTests': totalTests,
          'aciertos': totalAciertos,
          'total': totalIntentos,
          'porcentaje': porcentaje,
        });
      }

      return estudiantes;
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  // ==================== GENERACIÓN DE PDF ====================

  /// Genera PDF de reporte general consolidado
  Future<Uint8List> generarPdfReporteGeneral({
    required String gradoNombre,
    required String nombreInstitucion,
  }) async {
    final pdf = pw.Document();
    final reporteData = await obtenerReporteGeneral(gradoNombre: gradoNombre);

    if (reporteData.isEmpty) {
      return pdf.save();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Reporte General PLANEA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$nombreInstitucion - Grado: $gradoNombre',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado: ${DateTime.now().toLocal().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Resumen General',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue800),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text('Métrica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total de Estudiantes')),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${reporteData['totalEstudiantes']}')),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Tests Realizados')),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${reporteData['totalTests']}')),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total Aciertos')),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${reporteData['totalAciertos']}')),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total Intentos')),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${reporteData['totalIntentos']}')),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Promedio General')),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text('${(reporteData['promedioGeneral'] as double).toStringAsFixed(2)}%'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Genera PDF de todos los grados consolidados
  Future<Uint8List> generarPdfTodosGrados({
    required String nombreInstitucion,
  }) async {
    final pdf = pw.Document();
    final reporteData = await obtenerReporteTodosGrados();

    if (reporteData.isEmpty) {
      return pdf.save();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Reporte Consolidado PLANEA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$nombreInstitucion - Todos los Grados',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado: ${DateTime.now().toLocal().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Resumen Global',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue800),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text('Métrica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total de Estudiantes')),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${reporteData['totalEstudiantes']}')),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Tests Realizados')),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${reporteData['totalTests']}')),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Promedio Global')),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text('${(reporteData['promedioGeneral'] as double).toStringAsFixed(2)}%'),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Por Grado',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Grado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Estudiantes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Tests', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Promedio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...(reporteData['reportesPorGrado'] as Map<String, Map<String, dynamic>>)
                  .entries
                  .map((e) => pw.TableRow(
                        children: [
                          pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(e.key)),
                          pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${e.value['totalEstudiantes']}')),
                          pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('${e.value['totalTests']}')),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('${(e.value['promedioGeneral'] as double).toStringAsFixed(2)}%'),
                          ),
                        ],
                      ))
                  .toList(),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Genera PDF de desempeño por categoría
  Future<Uint8List> generarPdfPorCategoria({
    required String gradoNombre,
    required String nombreInstitucion,
  }) async {
    final pdf = pw.Document();
    final reporteData = await obtenerDesempenoPorCategoria(gradoNombre: gradoNombre);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Reporte de Desempeño PLANEA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$nombreInstitucion - Grado: $gradoNombre',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado: ${DateTime.now().toLocal().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          ...reporteData.entries.map((entry) {
            final nombreCat = entry.key;
            final data = entry.value as Map<String, dynamic>;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.blue800,
                  padding: pw.EdgeInsets.all(8),
                  child: pw.Text(
                    nombreCat,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Desempeño General: ${(data['porcentajeGeneral'] as double).toStringAsFixed(2)}% (${data['totalAciertos']} / ${data['totalIntentos']} aciertos)',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Desempeño por Estudiante:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Estudiante', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Aciertos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Porcentaje', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...(data['estudiantes'] as Map<String, Map<String, dynamic>>)
                        .entries
                        .map((e) => pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(e.value['nombre'] ?? e.key), // Usar el nombre del value, no la key (ID)
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text('${e.value['aciertos']}/${e.value['intentos']}'),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text('${(e.value['porcentaje'] as double).toStringAsFixed(2)}%'),
                                ),
                              ],
                            ))
                        .toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Genera PDF de desempeño por estudiante
  Future<Uint8List> generarPdfPorEstudiante({
    required String gradoNombre,
    required String nombreInstitucion,
  }) async {
    final pdf = pw.Document();
    final estudiantes = await obtenerEstudiantesPorGrado(gradoNombre: gradoNombre);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Reporte de Estudiantes PLANEA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$nombreInstitucion - Grado: $gradoNombre',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado: ${DateTime.now().toLocal().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Resumen General',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue800),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Estudiante', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Tests', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Aciertos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Promedio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                ],
              ),
              ...estudiantes
                  .map((est) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(est['nombre'] as String),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text((est['totalTests'] as int).toString()),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text((est['aciertos'] as int).toString()),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text((est['total'] as int).toString()),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text('${(est['porcentaje'] as double).toStringAsFixed(2)}%'),
                          ),
                        ],
                      ))
                  .toList(),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ==================== GENERACIÓN DE EXCEL ====================

  /// Genera Excel de desempeño por categoría (con formato profesional)
  Future<Uint8List> generarExcelPorCategoria({
    required String gradoNombre,
    String? usuarioNombre,
    String? usuarioRol,
  }) async {
    final reporteData = await obtenerDesempenoPorCategoria(gradoNombre: gradoNombre);

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Por Categoría';

    // Configurar anchos de columna - usar rango extenso para aplicar a toda la columna
    sheet.getRangeByName('A1:A1000').columnWidth = 70.33;  // Columna A: 70.33 píxeles
    sheet.getRangeByName('B1:B1000').columnWidth = 19.89;  // Columna B: 19.89 píxeles
    sheet.getRangeByName('C1:C1000').columnWidth = 19.89;  // Columna C: 19.89 píxeles
    sheet.getRangeByName('D1:D1000').columnWidth = 19.89;  // Columna D: 19.89 píxeles
    sheet.getRangeByName('E1:E1000').columnWidth = 19.89;  // Columna E: 19.89 píxeles

    int row = 1;

    // Título
    sheet.getRangeByIndex(row, 1).setText('REPORTE POR CATEGORÍA PLANEA');
    var titleStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    titleStyle.fontSize = 22;
    titleStyle.bold = true;
    titleStyle.backColor = '#1F4E78';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.hAlign = HAlignType.center;
    titleStyle.vAlign = VAlignType.center;
    sheet.getRangeByIndex(row, 1).rowHeight = 35;
    row++;

    // Separador vacío
    row++;

    // Info: Grado del reporte generado
    sheet.getRangeByIndex(row, 1).setText('Grado del reporte generado: $gradoNombre');
    var labelStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    labelStyle.fontSize = 11;
    labelStyle.bold = true;
    labelStyle.fontColor = '#1F4E78';
    labelStyle.hAlign = HAlignType.left;
    row++;

    // Info: Generado por
    final nombreUsuario = usuarioNombre ?? 'Sistema';
    final rolUsuario = usuarioRol ?? 'Administrador';
    sheet.getRangeByIndex(row, 1).setText('Generado por: $nombreUsuario ($rolUsuario)');
    var genStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    genStyle.fontSize = 11;
    genStyle.bold = true;
    genStyle.fontColor = '#1F4E78';
    genStyle.hAlign = HAlignType.left;
    row++;

    // Info: Fecha
    final fecha = DateTime.now().toLocal().toString().split('.')[0];
    sheet.getRangeByIndex(row, 1).setText('Fecha: $fecha');
    var fechaStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    fechaStyle.fontSize = 11;
    fechaStyle.bold = true;
    fechaStyle.fontColor = '#1F4E78';
    fechaStyle.hAlign = HAlignType.left;
    row += 2;

    // Encabezados
    sheet.getRangeByIndex(row, 1).setText('Categoría');
    sheet.getRangeByIndex(row, 2).setText('Aciertos');
    sheet.getRangeByIndex(row, 3).setText('Intentos');
    sheet.getRangeByIndex(row, 4).setText('Porcentaje (%)');
    sheet.getRangeByIndex(row, 5).setText('Estudiantes');
    
    for (int col = 1; col <= 5; col++) {
      var headerStyle = sheet.getRangeByIndex(row, col).cellStyle;
      headerStyle.bold = true;
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = HAlignType.center;
      headerStyle.fontSize = 11;
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';
    }
    row++;

    // Datos
    bool alternate = false;
    for (var entry in reporteData.entries) {
      final data = entry.value as Map<String, dynamic>;
      sheet.getRangeByIndex(row, 1).setText(entry.key);
      sheet.getRangeByIndex(row, 2).setText(data['totalAciertos'].toString());
      sheet.getRangeByIndex(row, 3).setText(data['totalIntentos'].toString());
      sheet.getRangeByIndex(row, 4).setText((data['porcentajeGeneral'] as double).toStringAsFixed(2));
      sheet.getRangeByIndex(row, 5).setText(data['totalEstudiantes'].toString());

      if (alternate) {
        for (int col = 1; col <= 5; col++) {
          sheet.getRangeByIndex(row, col).cellStyle.backColor = '#F2F2F2';
        }
      }

      // Añadir bordes a todas las celdas
      for (int col = 1; col <= 5; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.lineStyle = LineStyle.thin;
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.color = '#000000';
        // Centrar todas las columnas
        sheet.getRangeByIndex(row, col).cellStyle.hAlign = HAlignType.center;
      }

      row++;
      alternate = !alternate;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Genera Excel de desempeño por estudiante (con formato profesional)
  Future<Uint8List> generarExcelPorEstudiante({
    required String gradoNombre,
    String? usuarioNombre,
    String? usuarioRol,
  }) async {
    final estudiantes = await obtenerEstudiantesPorGrado(gradoNombre: gradoNombre);

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Por Estudiante';

    // Configurar anchos de columna - usar rango extenso para aplicar a toda la columna
    sheet.getRangeByName('A1:A1000').columnWidth = 70.33;  // Columna A: 70.33 píxeles
    sheet.getRangeByName('B1:B1000').columnWidth = 40.00;  // Columna B: 40 píxeles
    sheet.getRangeByName('C1:C1000').columnWidth = 19.89;  // Columna C: 19.89 píxeles
    sheet.getRangeByName('D1:D1000').columnWidth = 19.89;  // Columna D: 19.89 píxeles
    sheet.getRangeByName('E1:E1000').columnWidth = 19.89;  // Columna E: 19.89 píxeles
    sheet.getRangeByName('F1:F1000').columnWidth = 19.89;  // Columna F: 19.89 píxeles

    int row = 1;

    // Título
    sheet.getRangeByIndex(row, 1).setText('REPORTE POR ESTUDIANTE PLANEA');
    var titleStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    titleStyle.fontSize = 22;
    titleStyle.bold = true;
    titleStyle.backColor = '#1F4E78';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.hAlign = HAlignType.center;
    titleStyle.vAlign = VAlignType.center;
    sheet.getRangeByIndex(row, 1).rowHeight = 35;
    row++;

    // Separador vacío
    row++;

    // Info: Grado del reporte generado
    sheet.getRangeByIndex(row, 1).setText('Grado del reporte generado: $gradoNombre');
    var labelStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    labelStyle.fontSize = 11;
    labelStyle.bold = true;
    labelStyle.fontColor = '#1F4E78';
    labelStyle.hAlign = HAlignType.left;
    row++;

    // Info: Generado por
    final nombreUsuario = usuarioNombre ?? 'Sistema';
    final rolUsuario = usuarioRol ?? 'Administrador';
    sheet.getRangeByIndex(row, 1).setText('Generado por: $nombreUsuario ($rolUsuario)');
    var genStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    genStyle.fontSize = 11;
    genStyle.bold = true;
    genStyle.fontColor = '#1F4E78';
    genStyle.hAlign = HAlignType.left;
    row++;

    // Info: Fecha
    final fecha = DateTime.now().toLocal().toString().split('.')[0];
    sheet.getRangeByIndex(row, 1).setText('Fecha: $fecha');
    var fechaStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    fechaStyle.fontSize = 11;
    fechaStyle.bold = true;
    fechaStyle.fontColor = '#1F4E78';
    fechaStyle.hAlign = HAlignType.left;
    row += 2;

    // Encabezados
    sheet.getRangeByIndex(row, 1).setText('Estudiante');
    sheet.getRangeByIndex(row, 2).setText('Email');
    sheet.getRangeByIndex(row, 3).setText('Tests');
    sheet.getRangeByIndex(row, 4).setText('Aciertos');
    sheet.getRangeByIndex(row, 5).setText('Preguntas');
    sheet.getRangeByIndex(row, 6).setText('Promedio (%)');
    
    for (int col = 1; col <= 6; col++) {
      var headerStyle = sheet.getRangeByIndex(row, col).cellStyle;
      headerStyle.bold = true;
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = HAlignType.center;
      headerStyle.fontSize = 11;
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';
    }
    row++;

    // Datos
    bool alternate = false;
    for (var est in estudiantes) {
      sheet.getRangeByIndex(row, 1).setText(est['nombre'] as String);
      sheet.getRangeByIndex(row, 2).setText(est['email'] as String);
      sheet.getRangeByIndex(row, 3).setText((est['totalTests'] as int? ?? 0).toString());
      sheet.getRangeByIndex(row, 4).setText((est['aciertos'] as int? ?? 0).toString());
      sheet.getRangeByIndex(row, 5).setText((est['total'] as int? ?? 0).toString());
      sheet.getRangeByIndex(row, 6).setText(((est['porcentaje'] as double? ?? 0.0)).toStringAsFixed(2));

      if (alternate) {
        for (int col = 1; col <= 6; col++) {
          sheet.getRangeByIndex(row, col).cellStyle.backColor = '#F2F2F2';
        }
      }

      // Añadir bordes a todas las celdas
      for (int col = 1; col <= 6; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.lineStyle = LineStyle.thin;
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.color = '#000000';
        // Centrar todas las columnas
        sheet.getRangeByIndex(row, col).cellStyle.hAlign = HAlignType.center;
      }

      row++;
      alternate = !alternate;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Genera Excel de reporte general consolidado (con formato profesional)
  Future<Uint8List> generarExcelReporteGeneral({
    required String gradoNombre,
    String? usuarioNombre,
    String? usuarioRol,
  }) async {
    final reporteData = await obtenerReporteGeneral(gradoNombre: gradoNombre);

    if (reporteData.isEmpty) {
      return Uint8List.fromList([]);
    }

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Reporte General';

    // Configurar anchos de columna - usar rango extenso para aplicar a toda la columna
    sheet.getRangeByName('A1:A1000').columnWidth = 55.22;
    sheet.getRangeByName('B1:B1000').columnWidth = 28.89;

    int row = 1;

    // Título principal - GRANDE (fusionado A1:B1)
    sheet.getRangeByIndex(row, 1).setText('REPORTE GENERAL PLANEA');
    var titleStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    titleStyle.fontSize = 22;
    titleStyle.bold = true;
    titleStyle.backColor = '#1F4E78';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.hAlign = HAlignType.center;
    titleStyle.vAlign = VAlignType.center;
    sheet.getRangeByIndex(row, 1).rowHeight = 35;
    row++;

    // Separador vacío
    row++;

    // Info: Grado del reporte generado
    sheet.getRangeByIndex(row, 1).setText('Grado del reporte generado: $gradoNombre');
    var labelStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    labelStyle.fontSize = 11;
    labelStyle.bold = true;
    labelStyle.fontColor = '#1F4E78';
    labelStyle.hAlign = HAlignType.left;
    row++;

    // Info: Generado por
    final nombreUsuario = usuarioNombre ?? 'Sistema';
    final rolUsuario = usuarioRol ?? 'Administrador';
    sheet.getRangeByIndex(row, 1).setText('Generado por: $nombreUsuario ($rolUsuario)');
    var genStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    genStyle.fontSize = 11;
    genStyle.bold = true;
    genStyle.fontColor = '#1F4E78';
    genStyle.hAlign = HAlignType.left;
    row++;

    // Info: Fecha
    final fecha = DateTime.now().toLocal().toString().split('.')[0];
    sheet.getRangeByIndex(row, 1).setText('Fecha: $fecha');
    var fechaStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    fechaStyle.fontSize = 11;
    fechaStyle.bold = true;
    fechaStyle.fontColor = '#1F4E78';
    fechaStyle.hAlign = HAlignType.left;
    row += 2;

    // Encabezados de tabla
    sheet.getRangeByIndex(row, 1).setText('Métrica');
    sheet.getRangeByIndex(row, 2).setText('Valor');
    
    for (int col = 1; col <= 2; col++) {
      var header = sheet.getRangeByIndex(row, col).cellStyle;
      header.fontSize = 12;
      header.bold = true;
      header.backColor = '#4472C4';
      header.fontColor = '#FFFFFF';
      header.hAlign = HAlignType.center;
      header.vAlign = VAlignType.center;
      sheet.getRangeByIndex(row, col).rowHeight = 25;
      // Añadir bordes
      header.borders.all.lineStyle = LineStyle.thin;
      header.borders.all.color = '#000000';
    }
    row++;

    // Datos con alternancia de colores
    final datos = [
      ['Total de Estudiantes', reporteData['totalEstudiantes']],
      ['Tests Realizados', reporteData['totalTests']],
      ['Total Aciertos', reporteData['totalAciertos']],
      ['Total Intentos', reporteData['totalIntentos']],
      ['Promedio General (%)', (reporteData['promedioGeneral'] as double).toStringAsFixed(2)],
    ];

    bool alternate = false;
    for (final dato in datos) {
      sheet.getRangeByIndex(row, 1).setText(dato[0].toString());
      sheet.getRangeByIndex(row, 2).setText(dato[1].toString());

      var cell1 = sheet.getRangeByIndex(row, 1).cellStyle;
      var cell2 = sheet.getRangeByIndex(row, 2).cellStyle;

      cell1.fontSize = 11;
      cell2.fontSize = 11;
      cell1.hAlign = HAlignType.left;
      cell2.hAlign = HAlignType.center; // Centrar los valores

      if (alternate) {
        cell1.backColor = '#F2F2F2';
        cell2.backColor = '#F2F2F2';
      }
      
      // Añadir bordes a las celdas de datos
      cell1.borders.all.lineStyle = LineStyle.thin;
      cell1.borders.all.color = '#000000';
      cell2.borders.all.lineStyle = LineStyle.thin;
      cell2.borders.all.color = '#000000';
      
      sheet.getRangeByIndex(row, 1).rowHeight = 22;
      row++;
      alternate = !alternate;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Genera Excel de todos los grados consolidados (con formato profesional)
  Future<Uint8List> generarExcelTodosGrados({
    String? usuarioNombre,
    String? usuarioRol,
  }) async {
    final reporteData = await obtenerReporteTodosGrados();

    if (reporteData.isEmpty) {
      return Uint8List.fromList([]);
    }

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Todos los Grados';

    // Configurar anchos de columna - usar rango extenso para aplicar a toda la columna
    sheet.getRangeByName('A1:A1000').columnWidth = 60.00;  // Columna A: 60 píxeles
    sheet.getRangeByName('B1:B1000').columnWidth = 35.00;  // Columna B: 35 píxeles
    sheet.getRangeByName('C1:C1000').columnWidth = 18.00;  // Columna C: 18 píxeles
    sheet.getRangeByName('D1:D1000').columnWidth = 18.00;  // Columna D: 18 píxeles

    int row = 1;

    // Título principal
    sheet.getRangeByIndex(row, 1).setText('REPORTE CONSOLIDADO PLANEA');
    var titleStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    titleStyle.fontSize = 22;
    titleStyle.bold = true;
    titleStyle.backColor = '#1F4E78';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.hAlign = HAlignType.center;
    titleStyle.vAlign = VAlignType.center;
    sheet.getRangeByIndex(row, 1).rowHeight = 35;
    row++;

    // Separador vacío
    row++;

    // Info: Alcance del reporte
    sheet.getRangeByIndex(row, 1).setText('Alcance del reporte: Todos los Grados');
    var labelStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    labelStyle.fontSize = 11;
    labelStyle.bold = true;
    labelStyle.fontColor = '#1F4E78';
    labelStyle.hAlign = HAlignType.left;
    row++;

    // Info: Generado por
    final nombreUsuario = usuarioNombre ?? 'Sistema';
    final rolUsuario = usuarioRol ?? 'Administrador';
    sheet.getRangeByIndex(row, 1).setText('Generado por: $nombreUsuario ($rolUsuario)');
    var genStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    genStyle.fontSize = 11;
    genStyle.bold = true;
    genStyle.fontColor = '#1F4E78';
    genStyle.hAlign = HAlignType.left;
    row++;

    // Info: Fecha
    final fecha = DateTime.now().toLocal().toString().split('.')[0];
    sheet.getRangeByIndex(row, 1).setText('Fecha: $fecha');
    var fechaStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    fechaStyle.fontSize = 11;
    fechaStyle.bold = true;
    fechaStyle.fontColor = '#1F4E78';
    fechaStyle.hAlign = HAlignType.left;
    row += 2;

    // RESUMEN GLOBAL - Título de sección
    sheet.getRangeByIndex(row, 1).setText('RESUMEN GLOBAL');
    var sectionStyle = sheet.getRangeByIndex(row, 1).cellStyle;
    sectionStyle.fontSize = 13;
    sectionStyle.bold = true;
    sectionStyle.backColor = '#D9E1F2';
    sectionStyle.fontColor = '#1F4E78';
    row++;

    // Encabezados Resumen
    sheet.getRangeByIndex(row, 1).setText('Métrica');
    sheet.getRangeByIndex(row, 2).setText('Valor');
    for (int col = 1; col <= 2; col++) {
      var h = sheet.getRangeByIndex(row, col).cellStyle;
      h.bold = true;
      h.backColor = '#4472C4';
      h.fontColor = '#FFFFFF';
      h.hAlign = HAlignType.center;
      h.fontSize = 11;
      h.borders.all.lineStyle = LineStyle.thin;
      h.borders.all.color = '#000000';
    }
    row++;

    // Datos Resumen
    sheet.getRangeByIndex(row, 1).setText('Total de Estudiantes');
    final totalEstudiantes = reporteData['totalEstudiantes'] ?? 0;
    sheet.getRangeByIndex(row, 2).setText(totalEstudiantes.toString());
    var cellStyle1 = sheet.getRangeByIndex(row, 2).cellStyle;
    cellStyle1.hAlign = HAlignType.center;
    cellStyle1.borders.all.lineStyle = LineStyle.thin;
    cellStyle1.borders.all.color = '#000000';
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.lineStyle = LineStyle.thin;
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.color = '#000000';
    row++;
    
    sheet.getRangeByIndex(row, 1).setText('Tests Realizados');
    final totalTests = reporteData['totalTests'] ?? 0;
    sheet.getRangeByIndex(row, 2).setText(totalTests.toString());
    var cellStyle2 = sheet.getRangeByIndex(row, 2).cellStyle;
    cellStyle2.hAlign = HAlignType.center;
    cellStyle2.borders.all.lineStyle = LineStyle.thin;
    cellStyle2.borders.all.color = '#000000';
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.lineStyle = LineStyle.thin;
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.color = '#000000';
    row++;
    
    sheet.getRangeByIndex(row, 1).setText('Promedio Global (%)');
    final promedioGeneral = (reporteData['promedioGeneral'] as double?) ?? 0.0;
    sheet.getRangeByIndex(row, 2).setText(promedioGeneral.toStringAsFixed(2));
    var cellStyle3 = sheet.getRangeByIndex(row, 2).cellStyle;
    cellStyle3.hAlign = HAlignType.center;
    cellStyle3.borders.all.lineStyle = LineStyle.thin;
    cellStyle3.borders.all.color = '#000000';
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.lineStyle = LineStyle.thin;
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.color = '#000000';
    row += 2;

    // DESEMPEÑO POR GRADO - Título de sección
    sheet.getRangeByIndex(row, 1).setText('DESEMPEÑO POR GRADO');
    var sectionStyle2 = sheet.getRangeByIndex(row, 1).cellStyle;
    sectionStyle2.fontSize = 13;
    sectionStyle2.bold = true;
    sectionStyle2.backColor = '#D9E1F2';
    sectionStyle2.fontColor = '#1F4E78';
    row++;

    // Encabezados tabla
    sheet.getRangeByIndex(row, 1).setText('Grado');
    sheet.getRangeByIndex(row, 2).setText('Estudiantes');
    sheet.getRangeByIndex(row, 3).setText('Tests');
    sheet.getRangeByIndex(row, 4).setText('Promedio (%)');
    
    for (int col = 1; col <= 4; col++) {
      var h = sheet.getRangeByIndex(row, col).cellStyle;
      h.bold = true;
      h.backColor = '#4472C4';
      h.fontColor = '#FFFFFF';
      h.hAlign = HAlignType.center;
      h.fontSize = 11;
      h.borders.all.lineStyle = LineStyle.thin;
      h.borders.all.color = '#000000';
    }
    row++;

    // Datos tabla
    final reportesPorGrado = reporteData['reportesPorGrado'] as Map<String, Map<String, dynamic>>? ?? {};
    bool alternate = false;
    for (final entry in reportesPorGrado.entries) {
      sheet.getRangeByIndex(row, 1).setText(entry.key);
      final totalEst = entry.value['totalEstudiantes'] ?? 0;
      final totalTst = entry.value['totalTests'] ?? 0;
      final promGeneral = (entry.value['promedioGeneral'] as double?) ?? 0.0;
      
      sheet.getRangeByIndex(row, 2).setText(totalEst.toString());
      sheet.getRangeByIndex(row, 3).setText(totalTst.toString());
      sheet.getRangeByIndex(row, 4).setText(promGeneral.toStringAsFixed(2));

      if (alternate) {
        for (int col = 1; col <= 4; col++) {
          sheet.getRangeByIndex(row, col).cellStyle.backColor = '#F2F2F2';
        }
      }

      // Añadir bordes a todas las celdas y centrar B, C, D
      for (int col = 1; col <= 4; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.lineStyle = LineStyle.thin;
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.color = '#000000';
        // Centrar todas las columnas
        sheet.getRangeByIndex(row, col).cellStyle.hAlign = HAlignType.center;
      }

      row++;
      alternate = !alternate;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  // ==================== DESCARGA ====================

  /// Descarga archivo (PDF o Excel)
  void descargarArchivo({
    required Uint8List bytes,
    required String nombreArchivo,
  }) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', nombreArchivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
