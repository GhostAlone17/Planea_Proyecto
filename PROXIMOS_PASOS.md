# 🚀 PRÓXIMOS PASOS INMEDIATOS - Estudiante & Maestro

## ¿QUÉ FALTA?

Basado en tu proyecto "Preparación para el PLANEA", el 60% de la infraestructura está lista, pero **FALTAN las perspectivas clave del estudiante y maestro**. Aquí está el desglose:

---

## 📊 ESTADO ACTUAL DEL PROYECTO

### ✅ YA EXISTE (Etapa 1 - Infraestructura)
- Sistema de autenticación con Firebase
- Gestión de usuarios (Admin/Docente/Estudiante)
- Modelos de datos para preguntas y categorías
- Servicios base de Firebase y Firestore
- Dashboard de admin (crear estudiantes, preguntas, categorías)
- Estructura de reportes de desempeño

### ❌ FALTA (Etapas 2-3 - Core Funcional)
La aplicación NO funciona sin esto:

1. **Pantalla del Quiz/Test (CRÍTICA)**
   - Mostrar preguntas una por una
   - Mostrar respuestas en orden aleatorio
   - Guardar cada respuesta automáticamente
   - Permitir pausar/reanudar sin reiniciar

2. **Gestión de Sesiones de Quiz**
   - Crear nueva sesión
   - Guardar progreso
   - Recuperar sesión incompleta
   - Marcar como completa al final

3. **Pantalla de Resultados**
   - Calificación en porcentaje
   - Desempeño por categoría
   - Nivel de logro
   - Opción de revisar respuestas

4. **Perspectiva del Maestro**
   - Dashboard diferente del admin
   - Ver solo sus alumnos
   - Ver reportes del grupo
   - Asignar categorías específicas

---

## 📋 TAREAS ESPECÍFICAS POR HACER

### **TAREA 1: Modelos Nuevos** (30 minutos)
```
Crear estos archivos en lib/src/models/:

1. quiz_session_model.dart
   - ID de sesión
   - ID del estudiante
   - Categoría del test
   - Preguntas a responder (shuffled)
   - Respuestas dadas
   - Estado (en_progreso, completado, abandonado)
   - Fecha de inicio/fin
   - Tiempo total

2. quiz_answer_model.dart
   - ID de pregunta
   - Respuesta seleccionada (índice)
   - ¿Es correcta?
   - Tiempo empleado
   - Número de intento (1, 2, 3...)

3. student_stats_model.dart
   - Total de tests realizados
   - Total de aciertos
   - Porcentaje promedio
   - Mejor desempeño (categoría y %)
   - Peor desempeño (categoría y %)
   - Categorías completadas
```

### **TAREA 2: Servicio de Quiz** (1-2 horas)
```
Completar/crear lib/src/services/quiz_service.dart

Funciones necesarias:
1. iniciarTest(categoriId: String) → QuizSessionModel
   - Obtener todas las preguntas de la categoría
   - Randomizar preguntas
   - Randomizar opciones de cada pregunta
   - Crear sesión en Firestore

2. guardarRespuesta(sessionId, preguntaIndex, respuestaIndex)
   - Verificar si es correcta
   - Guardar en Firestore
   - Actualizar sesión

3. finalizarTest(sessionId) → StudentReportModel
   - Calcular calificación
   - Calcular desempeño por categoría
   - Guardar en reportes
   - Marcar sesión como completa

4. obtenerSesionActual(userId) → QuizSessionModel?
   - Para recuperar test incompleto

5. obtenerHistorialTests(userId) → List<QuizSessionModel>
   - Todos los tests completados del usuario
```

### **TAREA 3: Pantalla de Quiz** (2-3 horas)
```
Crear lib/src/screens/quiz_screen.dart (MEJORADA)

Elementos visuales:
- Header: Categoría | Pregunta X de Y | Tiempo
- Tarjeta principal: Pregunta (grande y legible)
- 4 botones para respuestas (aleatorias)
- Indicador visual: ¿Respondida o no?
- Botones: "Anterior" (deshabilitado), "Siguiente", "Terminar"

Funcionalidad:
- Al entrar: obtener o crear sesión
- Al responder: guardar automáticamente
- Permitir navegación dentro del test
- Bloquear ir al siguiente sin responder
- Al último reactivo: mostrar "Terminar" en lugar de "Siguiente"
- Al terminar: ir a resultados
```

### **TAREA 4: Pantalla de Resultados** (1-2 horas)
```
Mejorar/crear lib/src/screens/results_screen.dart

Mostrar:
1. Calificación grande en grande (ej: 75%)
2. Nivel de logro (Excelente / Bueno / Regular / Necesita Mejorar)
3. Tabla con desempeño por categoría:
   - Nombre categoría
   - Aciertos / Total
   - Porcentaje
   - Icono de nivel (🟢🟡🔴)

4. Botones:
   - "Ver respuestas"
   - "Intentar de nuevo"
   - "Inicio"

5. (Opcional) Gráfico de comparación categorías
```

### **TAREA 5: Pantalla Principal Estudiante** (1 hora)
```
Crear lib/src/screens/student/student_dashboard_screen.dart

Mostrar:
1. Saludo al estudiante
2. Categorías disponibles con botón "Comenzar Test"
3. Últimas pruebas realizadas (últimas 5)
4. Promedio general
5. Recomendaciones basadas en bajo desempeño
```

### **TAREA 6: Navegación Actualizada** (30 minutos)
```
Actualizar lib/main.dart

Al login, distinguir entre:
- Admin → AdminDashboard (YA existe)
- Docente → TeacherDashboard (CREAR)
- Estudiante → StudentDashboard (CREAR)
```

### **TAREA 7: Módulo Maestro** (3-4 horas)
```
Crear en lib/src/screens/teacher/:

1. teacher_dashboard_screen.dart
   - Mostrar alumnos del maestro
   - Promedio general del grupo
   - Categorías con bajo desempeño

2. teacher_students_screen.dart
   - Lista de alumnos asignados
   - Filtros
   - Acceso a reportes individual

3. teacher_student_detail_screen.dart
   - Desempeño del alumno
   - Progreso por categoría
   - Historial de intentos

Crear lib/src/services/teacher_service.dart:
   - getAlumnosDelMaestro(teacherId)
   - getReporteMaestro(teacherId)
   - obtenerDesempenoGrupo(teacherId)
```

---

## 🎯 PRIORIDAD DE IMPLEMENTACIÓN

### **SEMANA 1** (MVP Funcional)
1. ✅ Modelos de Quiz (Tarea 1)
2. ✅ Servicio de Quiz (Tarea 2)
3. ✅ Pantalla de Quiz (Tarea 3)
4. ✅ Pantalla de Resultados (Tarea 4)
5. ✅ Navegación actualizada (Tarea 6)

**RESULTADO**: App totalmente funcional para estudiantes

### **SEMANA 2** (Complementos)
1. ✅ Pantalla Principal Estudiante (Tarea 5)
2. ✅ Historial de Tests
3. ✅ Bug fixes y UI polish

**RESULTADO**: Experiencia completa del estudiante

### **SEMANA 3** (Maestro)
1. ✅ Módulo Maestro completo (Tarea 7)
2. ✅ Servicios del maestro
3. ✅ Reportes de grupo

**RESULTADO**: Perspectiva del maestro funcional

---

## 🔍 VALIDACIONES CRÍTICAS

**Estas restricciones DEBEN estar en el código:**

```dart
// En QuizScreen:
- ✅ No permitir avanzar sin responder pregunta actual
- ✅ NO permitir navegar hacia adelante (solo actual y anterior)
- ✅ Guardar automáticamente cada respuesta
- ✅ Al llegar a la última pregunta, cambiar "Siguiente" por "Terminar"
- ✅ Solo permitir terminar en la última pregunta

// En QuizService:
- ✅ Randomizar PREGUNTAS
- ✅ Randomizar OPCIONES de cada pregunta
- ✅ Guardar estructura original para verificar respuestas
- ✅ Sincronizar con Firestore en tiempo real
- ✅ Recuperar sesión incompleta al entrar
```

---

## 📁 ESTRUCTURA DE CARPETAS FINAL

```
lib/src/
├── models/
│   ├── quiz_session_model.dart          ← CREAR
│   ├── quiz_answer_model.dart           ← CREAR
│   ├── student_stats_model.dart         ← CREAR
│   └── ... (existentes)
│
├── services/
│   ├── quiz_service.dart                ← COMPLETAR/MEJORAR
│   ├── teacher_service.dart             ← CREAR
│   └── ... (existentes)
│
├── screens/
│   ├── student/                          ← CREAR CARPETA
│   │   └── student_dashboard_screen.dart
│   ├── teacher/                          ← CREAR CARPETA
│   │   ├── teacher_dashboard_screen.dart
│   │   ├── teacher_students_screen.dart
│   │   └── teacher_student_detail_screen.dart
│   ├── quiz_screen.dart                 ← MEJORAR
│   ├── results_screen.dart              ← MEJORAR
│   └── ... (existentes)
└── ...
```

---

## 💾 ESTRUCTURA FIREBASE NECESARIA

```json
{
  "quizSessions": {
    "user123/session456": {
      "id": "session456",
      "userId": "user123",
      "categoryId": "algebra",
      "questionIds": ["q1", "q2", "q3", ...],    // Orden shuffled
      "answers": {
        "q1": { "selectedIndex": 2, "correct": true, "time": 45 },
        "q2": { "selectedIndex": 1, "correct": false, "time": 32 }
      },
      "status": "en_progreso",  // o "completado"
      "startDate": "2025-01-15T10:30:00Z",
      "endDate": null,
      "score": null
    }
  },
  
  "reportes": {
    "user123": {
      "totalTests": 5,
      "totalHits": 18,
      "averageScore": 72.5,
      "categoryPerformance": {
        "algebra": { "hits": 8, "total": 10, "percentage": 80 },
        "geometry": { "hits": 10, "total": 15, "percentage": 66.7 }
      },
      "lastUpdate": "2025-01-15T10:45:00Z"
    }
  }
}
```

---

## ✨ BONUS: Características Avanzadas (Post-MVP)

- [ ] Contador de tiempo por pregunta
- [ ] Modo "Retadora" (responder todas sin ver categoría)
- [ ] Comparativa anónima con otros estudiantes
- [ ] Sistema de insignias por logros
- [ ] Exportar reporte en PDF

---

## 📞 PREGUNTAS A ACLARAR

1. **¿El test debe ser de una sola categoría o mixto?**
   - Recomendado: Una categoría a la vez

2. **¿Cuántas preguntas por test?**
   - Sugerencia: 10-15 preguntas

3. **¿Se pueden pausar/reanudar tests incompletos?**
   - Sí, esto es CRÍTICO según los requisitos

4. **¿El tiempo es un factor en la calificación?**
   - ¿Solo contador o afecta puntuación?

5. **¿Los maestros pueden crear sus propios tests?**
   - O solo usan los creados por admin

