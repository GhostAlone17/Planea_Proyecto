# 🎓 ESPECIFICACIONES TÉCNICAS - MÓDULO DEL MAESTRO

**Proyecto**: Preparación para PLANEA (Matemáticas)  
**Módulo**: Teacher Dashboard (Maestro)  
**Prioridad**: 🔴 CRÍTICA  
**Estimación**: 1-2 semanas  

---

## 📋 VISIÓN DEL MÓDULO

El maestro debe poder:
1. **Ver sus reportes** de estudiantes asignados
2. **Filtrar por categoría y grado** 
3. **Exportar reportes** en Excel/PDF personalizados
4. **Enviar retroalimentación** a estudiantes
5. **Monitorear progreso** en tiempo real

---

## 🏗️ ARQUITECTURA PROPUESTA

```
lib/src/screens/teacher/
├── teacher_dashboard.dart                 (ACTUALIZAR)
├── teacher_reportes_pantalla.dart         (NUEVO)
├── teacher_estudiantes_asignados.dart     (NUEVO)
├── teacher_detalle_estudiante.dart        (NUEVO)
└── teacher_retroalimentacion.dart         (NUEVO)

lib/src/services/
└── teacher_service.dart                   (EXPANDIR)
```

---

## 1️⃣ SERVICIO DEL MAESTRO (teacher_service.dart)

### Métodos Necesarios

```dart
class TeacherService {
  
  // ==================== DATOS BÁSICOS ====================
  
  /// Obtiene información del maestro actual
  Future<Map<String, dynamic>> obtenerDatosMaestro() async {
    // Retorna: nombre, email, categorías asignadas, estudiantes totales
  }

  /// Obtiene grados asignados al maestro
  Future<List<String>> obtenerGradosAsignados() async {
    // Retorna: ['3S', '3P', '12EMS'] etc
  }

  /// Obtiene categorías que el maestro puede enseñar
  Future<List<CategoryModel>> obtenerCategorías() async {
    // Retorna todas las categorías (el maestro puede ver todas)
    // pero enfoque en las de su grado
  }

  // ==================== ESTUDIANTES ====================

  /// Obtiene estudiantes asignados (filtrados por grado del maestro)
  Future<List<Map<String, dynamic>>> obtenerEstudiantesAsignados({
    String? gradoFiltro,
    String? busqueda,
  }) async {
    // Retorna:
    // {
    //   'id': 'studentId',
    //   'nombre': 'Juan',
    //   'email': 'juan@email.com',
    //   'grado': '3S',
    //   'totalTests': 5,
    //   'promedio': 75.5,
    //   'ultimoTest': DateTime,
    //   'desempenoPorCategoria': {...}
    // }
  }

  /// Obtiene detalle completo de un estudiante
  Future<Map<String, dynamic>> obtenerDetalleEstudiante(String studentId) async {
    // Información completa del estudiante:
    // - Datos personales
    // - Historial de tests
    // - Desempeño por categoría
    // - Progreso en cada categoría (con gráficas)
    // - Preguntas donde falló
  }

  // ==================== REPORTES ====================

  /// Obtiene reporte consolidado de estudiantes del maestro
  Future<Map<String, dynamic>> obtenerReporteGrupal({
    String? gradoFiltro,
    String? categoriaFiltro,
    DateTimeRange? rango,
  }) async {
    // Retorna:
    // {
    //   'totalEstudiantes': 30,
    //   'promedioGrupal': 72.3,
    //   'mejoresEstudiantes': [...],
    //   'estudianteConNecesidad': [...],
    //   'desempenoPorCategoria': {...},
    //   'tendencia': {...}
    // }
  }

  /// Obtiene datos para gráfica de progreso
  Future<List<Map<String, dynamic>>> obtenerProgresoPorFecha({
    String? studentId,
    String? categoriaId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    // Para gráficas de línea (progreso en tiempo)
  }

  /// Obtiene preguntas donde los estudiantes fallan más
  Future<List<Map<String, dynamic>>> obtenerPreguntasDifficultosas({
    String? categoriaFiltro,
  }) async {
    // Retorna las 10 preguntas con más errores
  }

  // ==================== EXPORTACIÓN ====================

  /// Exporta reporte grupal a Excel
  Future<Uint8List> exportarReporteExcel({
    String? gradoFiltro,
    String? categoriaFiltro,
  }) async {
    // Similar a generarExcelPorEstudiante en ReportsService
    // Pero filtrado por estudiantes del maestro
  }

  /// Exporta reporte de un estudiante a PDF
  Future<Uint8List> exportarReportePDF(String studentId) async {
    // Detalle completo del estudiante en PDF
  }

  // ==================== RETROALIMENTACIÓN ====================

  /// Guarda comentario/retroalimentación para un estudiante
  Future<void> guardarRetroalimentacion({
    required String studentId,
    required String categoriaId,
    required String mensaje,
    DateTime? fechaVencimiento,
  }) async {
    // Guarda en: /maestros/{maestroId}/retroalimentaciones/{studentId}
  }

  /// Obtiene retroalimentaciones pendientes del maestro
  Future<List<Map<String, dynamic>>> obtenerRetroalimentacionesPendientes() async {
    // Retorna retroalimentaciones enviadas pero no leídas por estudiante
  }

  /// Marca retroalimentación como leída
  Future<void> marcarRetroalimentacionLeida(String feedbackId) async {}

  // ==================== NOTIFICACIONES ====================

  /// Obtiene notificaciones del maestro
  Future<List<Map<String, dynamic>>> obtenerNotificaciones({int limit = 20}) async {
    // "Nuevo estudiante se unió"
    // "Estudiante terminó test en Álgebra"
    // "Bajo desempeño detectado"
  }

  /// Suscribirse a actualizaciones de estudiantes
  Stream<Map<String, dynamic>> monitorearProgreso(String studentId) async* {
    // Stream que emite cuando el estudiante resuelve un test
  }
}
```

---

## 2️⃣ PANTALLA PRINCIPAL DEL MAESTRO

### `teacher_dashboard.dart` (ACTUALIZAR)

```dart
class TeacherDashboard extends StatefulWidget {
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  // =========== UI SECTIONS ===========
  
  // Sección Superior: Tarjetas KPI
  // ┌─────────────────────────────────────┐
  // │ 📚 Categorías  │ 👥 Estudiantes │ 📊 Promedio │
  // │    5           │     48         │   74.3%     │
  // └─────────────────────────────────────┘
  
  // Menú de Navegación
  // ┌─────────────────────────────────────┐
  // │ 📊 Mis Reportes                     │
  // │ 👥 Mis Estudiantes                  │
  // │ 📬 Retroalimentaciones Pendientes    │
  // │ 📈 Análisis de Desempeño            │
  // │ ⚙️  Configuración                    │
  // └─────────────────────────────────────┘
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard del Maestro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _mostrarNotificaciones,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _mostrarPerfil,
          ),
        ],
      ),
      body: _construirCuerpo(),
      drawer: _construirDrawer(),
    );
  }

  Widget _construirCuerpo() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // KPI Cards
          _construirKPICards(),
          
          // Section: Últimos Tests
          _construirUltimosTests(),
          
          // Section: Estudiantes con Bajo Desempeño
          _construirEstudiantesConAlerta(),
        ],
      ),
    );
  }

  Widget _construirKPICards() {
    // Mostrar:
    // - Total de estudiantes
    // - Promedio del grupo
    // - Tests realizados hoy
    // - Categorías con más actividad
  }

  Widget _construirDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('📚 Mi Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text('Maestro de Matemáticas',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('📊 Mis Reportes'),
            onTap: () => _navegarA('/teacher/reportes'),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('👥 Mis Estudiantes'),
            onTap: () => _navegarA('/teacher/estudiantes'),
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('📬 Retroalimentaciones'),
            onTap: () => _navegarA('/teacher/retroalimentacion'),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('📈 Análisis'),
            onTap: () => _navegarA('/teacher/analisis'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('⚙️ Configuración'),
            onTap: () => _navegarA('/teacher/configuracion'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }
}
```

---

## 3️⃣ PANTALLA DE REPORTES

### `teacher_reportes_pantalla.dart` (NUEVO)

```dart
class TeacherReportesScreen extends StatefulWidget {
  @override
  State<TeacherReportesScreen> createState() => _TeacherReportesScreenState();
}

class _TeacherReportesScreenState extends State<TeacherReportesScreen> {
  
  String _tipoReporte = 'grupal'; // grupal, individual, categoria
  String? _gradoFiltro;
  String? _categoriaFiltro;
  DateTimeRange? _rango;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 Mis Reportes')),
      body: Column(
        children: [
          // Filtros
          _construirFiltros(),
          
          // Botones de acción
          _construirBotonesAccion(),
          
          // Tabla de resultados
          Expanded(
            child: _construirTablaReportes(),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltros() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de tipo de reporte
          Row(
            children: [
              _construirRadioBoton('Grupal'),
              _construirRadioBoton('Individual'),
              _construirRadioBoton('Por Categoría'),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filtro por grado
          _construirFiltroGrado(),
          
          // Filtro por categoría
          _construirFiltroCategoria(),
          
          // Selector de rango de fechas
          _construirFiltroFechas(),
        ],
      ),
    );
  }

  Widget _construirBotonesAccion() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.file_download),
            label: const Text('📥 Excel'),
            onPressed: _exportarExcel,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('📄 PDF'),
            onPressed: _exportarPDF,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('🔄 Actualizar'),
            onPressed: _recargar,
          ),
        ],
      ),
    );
  }

  Widget _construirTablaReportes() {
    // DataTable con:
    // - Nombre estudiante
    // - Grado
    // - Tests realizados
    // - Aciertos
    // - Promedio %
    // - Última actividad
    // - Acción (ver detalle)
  }
}
```

---

## 4️⃣ PANTALLA DE ESTUDIANTES ASIGNADOS

### `teacher_estudiantes_asignados.dart` (NUEVO)

```dart
class TeacherEstudiantesAsignados extends StatefulWidget {
  @override
  State<TeacherEstudiantesAsignados> createState() => 
      _TeacherEstudiantesAsignadosState();
}

class _TeacherEstudiantesAsignadosState 
    extends State<TeacherEstudiantesAsignados> {
  
  String _busqueda = '';
  String? _gradoFiltro;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👥 Mis Estudiantes')),
      body: Column(
        children: [
          // Búsqueda y filtros
          _construirBarraBusqueda(),
          
          // Lista de estudiantes con tarjetas
          Expanded(
            child: _construirListaEstudiantes(),
          ),
        ],
      ),
    );
  }

  Widget _construirBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // SearchBar
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar estudiante...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _busqueda = value);
            },
          ),
          const SizedBox(height: 12),
          
          // Filtro por grado
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _gradoFiltro == null,
                onSelected: (_) => setState(() => _gradoFiltro = null),
              ),
              FilterChip(
                label: const Text('3° Secundaria'),
                selected: _gradoFiltro == '3S',
                onSelected: (_) => setState(() => _gradoFiltro = '3S'),
              ),
              FilterChip(
                label: const Text('3° Preparatoria'),
                selected: _gradoFiltro == '12EMS',
                onSelected: (_) => setState(() => _gradoFiltro = '12EMS'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirListaEstudiantes() {
    // Cada tarjeta de estudiante muestra:
    // ┌────────────────────────────────┐
    // │ 👤 Juan Pérez                  │
    // │ 📧 juan@email.com              │
    // │ 📚 3° Secundaria               │
    // │ 📊 Promedio: 75.5% ▯▯▯▯◯        │
    // │ 🧮 Tests: 5   ✓ Aciertos: 378  │
    // │ ┌──────────────┬──────────────┐│
    // │ │📈 Ver detalle│📧 Enviar msg.││
    // │ └──────────────┴──────────────┘│
    // └────────────────────────────────┘
  }
}
```

---

## 5️⃣ DETALLE DEL ESTUDIANTE

### `teacher_detalle_estudiante.dart` (NUEVO)

```dart
class TeacherDetalleEstudianteScreen extends StatefulWidget {
  final String studentId;
  
  const TeacherDetalleEstudianteScreen({
    required this.studentId,
  });

  @override
  State<TeacherDetalleEstudianteScreen> createState() => 
      _TeacherDetalleEstudianteScreenState();
}

class _TeacherDetalleEstudianteScreenState 
    extends State<TeacherDetalleEstudianteScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 Detalle del Estudiante')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tarjeta de info del estudiante
            _construirInfoEstudiante(),
            
            // Estadísticas generales
            _construirEstadisticasGenerales(),
            
            // Desempeño por categoría (gráfica)
            _construirDesempenoPorCategoria(),
            
            // Historial de intentos
            _construirHistorialIntentos(),
            
            // Preguntas donde falló
            _construirPreguntasConError(),
            
            // Enviar retroalimentación
            _construirSeccionRetroalimentacion(),
          ],
        ),
      ),
    );
  }

  Widget _construirInfoEstudiante() {
    // Mostrar foto, nombre, email, grado, última actividad
  }

  Widget _construirEstadisticasGenerales() {
    // Cards con:
    // - Total Tests
    // - Aciertos
    // - Intentos
    // - Promedio %
    // - Nivel de logro (Excelente, Bueno, Regular, Necesita Mejorar)
  }

  Widget _construirDesempenoPorCategoria() {
    // Gráfica de barras horizontal con desempeño por categoría
    // Ej:
    // Álgebra       ▯▯▯▯▯▯▯▯○○ 80%
    // Geometría     ▯▯▯▯▯▯▯○○○ 70%
    // Trigonometría ▯▯▯▯▯▯▯▯▯▯ 100%
  }

  Widget _construirHistorialIntentos() {
    // Tabla con últimos 10 intentos:
    // - Fecha
    // - Categoría
    // - Aciertos/Intentos
    // - Porcentaje
    // - Duración
  }

  Widget _construirPreguntasConError() {
    // Top 5 preguntas donde el estudiante falló
    // Mostrar la pregunta, sus intentos incorrectos, respuesta correcta
  }

  Widget _construirSeccionRetroalimentacion() {
    // TextArea para escribir comentario
    // Selector de prioridad
    // Botón enviar
  }
}
```

---

## 6️⃣ RETROALIMENTACIÓN

### `teacher_retroalimentacion.dart` (NUEVO)

```dart
class TeacherRetroalimentacionScreen extends StatefulWidget {
  @override
  State<TeacherRetroalimentacionScreen> createState() => 
      _TeacherRetroalimentacionScreenState();
}

class _TeacherRetroalimentacionScreenState 
    extends State<TeacherRetroalimentacionScreen> {
  
  String _filtro = 'pendientes'; // pendientes, leidas, todas
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📬 Retroalimentaciones')),
      body: Column(
        children: [
          // Filtros
          _construirFiltros(),
          
          // Lista de retroalimentaciones
          Expanded(
            child: _construirListaRetroalimentaciones(),
          ),
        ],
      ),
    );
  }

  Widget _construirListaRetroalimentaciones() {
    // Cada tarjeta:
    // ┌──────────────────────────────┐
    // │ 📧 Juan Pérez (3S)           │
    // │ Categoría: Álgebra           │
    // │ Enviado: 2 Nov 2025 10:30    │
    // │ Estado: ❌ No leído (pendiente) │
    // │                              │
    // │ "Necesitas practicar más las │
    // │  ecuaciones cuadráticas"     │
    // │                              │
    // │ [Visto] [Resend] [Delete]   │
    // └──────────────────────────────┘
  }
}
```

---

## 7️⃣ CAMBIOS REQUERIDOS EN FIRESTORE

### Colección Nueva: `/maestros/{maestroId}/retroalimentaciones`

```json
{
  "studentId": "student123",
  "categoriaId": "algebra",
  "mensaje": "Necesitas practicar más ecuaciones",
  "fechaEnviada": "2025-11-02T10:30:00Z",
  "leida": false,
  "prioridad": "normal", // low, normal, high
  "fechaVencimiento": "2025-11-09T23:59:59Z"
}
```

### Campo Nuevo en `/usuarios/{maestroId}`

```json
{
  "categoriasAsignadas": ["1", "2", "3"],
  "gradosAsignados": ["3S", "12EMS"],
  "notificacionesHabilitadas": true
}
```

---

## 8️⃣ REGLAS DE FIRESTORE

```javascript
// Maestro solo ve estudiantes de su grado
match /reportes_estudiantes/{studentId} {
  allow read: if isTeacherOfStudent();
  allow write: if isAdmin();
}

// Maestro puede crear retroalimentaciones para sus estudiantes
match /maestros/{maestroId}/retroalimentaciones/{feedbackId} {
  allow read, write: if request.auth.uid == maestroId;
}

// Estudiante puede leer sus retroalimentaciones
match /estudiantes/{studentId}/retroalimentaciones/{feedbackId} {
  allow read: if request.auth.uid == studentId;
}
```

---

## 9️⃣ CRONOGRAMA DE IMPLEMENTACIÓN

### Semana 1
- [ ] Expandir `teacher_service.dart` con métodos básicos
- [ ] Actualizar `teacher_dashboard.dart`
- [ ] Crear `teacher_reportes_pantalla.dart`

### Semana 2
- [ ] Crear `teacher_estudiantes_asignados.dart`
- [ ] Crear `teacher_detalle_estudiante.dart`
- [ ] Crear `teacher_retroalimentacion.dart`
- [ ] Implementar gráficas (usar `charts_flutter`)

### Semana 3
- [ ] Testing completo
- [ ] Validaciones de seguridad
- [ ] Optimización de queries

---

## 🔟 DEPENDENCIAS NECESARIAS

En `pubspec.yaml`:

```yaml
dependencies:
  # Gráficas
  fl_chart: ^0.65.0
  charts_flutter: ^0.12.0
  
  # Exportación
  intl: ^0.19.0
  
  # Utilidades
  table_calendar: ^3.1.0  # Para selector de fechas
```

---

## 1️⃣1️⃣ PRÓXIMOS PASOS

1. ✅ Revisar este documento
2. ✅ Crear estructura base de directorios
3. ✅ Implementar `teacher_service.dart`
4. ✅ Crear pantallas una por una
5. ✅ Testing y debugging
6. ✅ Deploy

**Comenzar por**: `teacher_service.dart` (métodos base)
