# 📱 App del Plantel - Proyecto Flutter

Sistema de comunicación para instituciones educativas que conecta a alumnos, padres de familia y docentes.

## 📋 Descripción del Proyecto

Esta aplicación permite la socialización de noticias e información importante del plantel mediante:
- **Módulo Web**: Panel de administración para gestionar usuarios, noticias y mensajes
- **Módulo Móvil**: App para recibir información, noticias y comunicarse con la administración

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada de la aplicación
└── src/
    ├── config/                        # Configuraciones generales
    │   ├── app_constants.dart         # Constantes de la app
    │   └── app_theme.dart             # Tema y estilos
    │
    ├── models/                        # Modelos de datos
    │   ├── user_model.dart            # Modelo de Usuario
    │   ├── noticia_model.dart         # Modelo de Noticia
    │   └── mensaje_model.dart         # Modelo de Mensaje
    │
    ├── services/                      # Servicios y lógica de negocio
    │   └── (Próxima etapa)
    │
    ├── screens/                       # Pantallas de la aplicación
    │   └── (Próxima etapa)
    │
    ├── widgets/                       # Widgets reutilizables
    │   └── (Próxima etapa)
    │
    └── utils/                         # Utilidades y helpers
        ├── date_formatter.dart        # Formateo de fechas
        ├── validators.dart            # Validaciones de formularios
        └── dialog_helper.dart         # Diálogos y mensajes
```

## 📦 Modelos de Datos

### UserModel
Representa a los usuarios del sistema:
- **Tipos**: Alumno, Padre de Familia, Docente
- **Campos**: id, nombre, email, tipo, foto, token de notificaciones, etc.

### NoticiaModel
Representa las noticias del plantel:
- **Tipos**: General, Beca, Suspensión, Evento, Académica
- **Destinatarios**: Todos, Alumnos, Padres, Docentes, Específicos
- **Campos**: título, contenido, imagen, prioridad, etc.

### MensajeModel
Representa mensajes entre usuarios:
- **Tipos**: Solicitud, Respuesta, General
- **Campos**: remitente, destinatario, asunto, contenido, archivos adjuntos

## 🎨 Configuración Visual

### Colores Principales
- **Primario**: `#2C5F4F` (Verde oscuro)
- **Secundario**: `#4A8B73` (Verde medio)
- **Acento**: `#FFB84D` (Naranja/Amarillo)

### Utilidades Disponibles

#### DateFormatter
- `formatoCompleto()`: "20 de Octubre de 2025"
- `formatoCorto()`: "20/10/2025"
- `formatoHora()`: "14:30"
- `tiempoRelativo()`: "Hace 2 horas"

#### Validators
- `required()`: Valida campos obligatorios
- `email()`: Valida correos electrónicos
- `password()`: Valida contraseñas
- `phone()`: Valida teléfonos

#### DialogHelper
- `showSuccess()`: Muestra mensaje de éxito
- `showError()`: Muestra mensaje de error
- `showConfirmDialog()`: Diálogo de confirmación
- `showLoadingDialog()`: Diálogo de carga

## 🚀 Plan de Desarrollo (5 Etapas)

### ✅ ETAPA 1: Estructura Base y Modelos (COMPLETADA)
- [x] Estructura de carpetas
- [x] Modelos de datos (Usuario, Noticia, Mensaje)
- [x] Constantes y configuraciones
- [x] Utilidades (formateo, validación, diálogos)
- [x] Tema personalizado

### 📋 ETAPA 2: Autenticación y Gestión de Estado
- [ ] Sistema de login/registro
- [ ] Manejo de estado (Provider/Riverpod)
- [ ] Servicios de autenticación
- [ ] Pantalla de login

### 📋 ETAPA 3: Pantalla Principal y Navegación
- [ ] Home screen con lista de noticias
- [ ] Sistema de navegación
- [ ] Drawer/menú lateral
- [ ] Pantalla de perfil

### 📋 ETAPA 4: Gestión de Noticias y Notificaciones
- [ ] CRUD de noticias
- [ ] Sistema de notificaciones push
- [ ] Filtrado por tipo de usuario
- [ ] Integración con Facebook

### 📋 ETAPA 5: Interfaz Web Admin
- [ ] Dashboard administrativo
- [ ] Gestión de usuarios
- [ ] Publicación de noticias
- [ ] Sistema de mensajes

## 🛠️ Tecnologías

- **Flutter**: Framework principal
- **Dart**: Lenguaje de programación
- **Material Design 3**: Sistema de diseño

## 📝 Dependencias Actuales

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.19.0  # Para formateo de fechas en español
```

## 👨‍💻 Instalación

```bash
# Clonar el repositorio
git clone [url-del-repositorio]

# Entrar al directorio
cd proyeto

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

## 📱 Características Principales

1. **Comunicación Bidireccional**: Entre administración y usuarios
2. **Noticias Segmentadas**: Por tipo de usuario
3. **Notificaciones Push**: Para información urgente
4. **Integración Social**: Conexión con Facebook
5. **Gestión Web**: Panel administrativo completo

## 🎯 Tipos de Usuario

- **Alumno**: Recibe noticias generales y específicas
- **Padre de Familia**: Recibe información de sus hijos
- **Docente**: Recibe información académica y general
- **Admin** (solo web): Gestiona todo el sistema

---

**Versión**: 1.0.0 - ETAPA 1  
**Última actualización**: Octubre 2025
