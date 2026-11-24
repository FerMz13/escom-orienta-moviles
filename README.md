# ESCOM Orienta Móviles (Versión Flutter / Dart)

Aplicación móvil multiplataforma diseñada para la comunidad estudiantil y académica de la Escuela Superior de Cómputo (**ESCOM - IPN**). Centraliza la navegación interna dentro de los edificios mediante un mapa interactivo con cálculo de rutas óptimas, la gestión personalizada del horario escolar a partir del PDF oficial del SAES y la consulta rápida de trámites, servicios y becas institucionales.

Proyecto académico migrado íntegramente a **Flutter y Dart** bajo los principios de **Clean Architecture**, manteniendo la paridad funcional con el proyecto original **sin módulo de chatbot ni dependencias de IA**.

---

## Tabla de Contenidos
1. [Características y Funcionalidades](#características-y-funcionalidades)
2. [Arquitectura y Tecnologías](#arquitectura-y-tecnologías)
3. [Organización y Estructura del Proyecto](#organización-y-estructura-del-proyecto)
4. [Requisitos del Entorno y cómo instalarlos](#requisitos-del-entorno-y-cómo-instalarlos)
5. [Instalación y Ejecución Local](#instalación-y-ejecución-local)
6. [Compilación y Pruebas de Calidad](#compilación-y-pruebas-de-calidad)
7. [Notas Técnicas de Compilación (Android / Gradle)](#notas-técnicas-de-compilación-android--gradle)
8. [Trabajo en Equipo y Colaboración](#trabajo-en-equipo-y-colaboración)

---

## Características y Funcionalidades

La navegación principal se organiza mediante una barra inferior de 4 pestañas (**Inicio, Mapa, Horario y Trámites**) que conservan su estado al cambiar entre secciones:

### 1. Inicio (Dashboard)
* **Resumen dinámico de clases:** Saludo personalizado y tarjeta inteligente que detecta la hora y el día actual para mostrar la clase en curso o la siguiente materia programada.
* **Navegación directa al salón:** Botón *"Cómo llegar"* integrado en cada tarjeta de clase que redirige automáticamente a la pestaña de Mapa y traza la ruta hacia el salón correspondiente.
* **Accesos rápidos:** Atajos directos hacia las secciones más consultadas y ubicaciones frecuentes dentro del plantel.

### 2. Mapa Interactivo y Enrutamiento Espacial (A*)
* **Navegación multinivel:** Visualización interactiva con gestos de zoom y desplazamiento fluido (`InteractiveViewer` y `CustomPainter`) para las tres plantas de la escuela: Planta Baja (`pb`), Primer Piso (`p1`) y Segundo Piso (`p2`).
* **Cálculo de rutas óptimas:** Implementación del algoritmo de búsqueda **A\* (A-Star)** en Dart puro sobre grafos espaciales para calcular la ruta más corta entre cualquier origen y destino, incluyendo transiciones por escaleras entre niveles.
* **Accesibilidad y métricas:** Opción configurable para *"Evitar escaleras"*, cálculo de distancia estimada en metros y tiempo aproximado de caminata.
* **Buscador tolerante a acentos:** Búsqueda instantánea de salones, laboratorios, cubículos y áreas administrativas sin importar mayúsculas o tildes.

### 3. Gestión de Horario Escolar (Lector PDF SAES)
* **Importación automática desde PDF:** Selección del archivo oficial descargado del SAES (`file_picker`) y procesamiento local en segundo plano mediante **Syncfusion Flutter PDF**.
* **Vista previa y validación:** Antes de guardar en la base de datos, presenta un resumen con el total de materias detectadas, alertas de traslapes de horario, salones pendientes por asignar y la opción de conservar u omitir los nombres de los profesores.
* **Edición y control local:** Vista organizada por día de la semana, captura o edición manual de sesiones con validación de conflictos en tiempo real, y borrado granular (por sesión individual, por materia o reinicio completo del horario).

### 4. Catálogo de Trámites y Servicios
* **Información estructurada offline:** Lectura local desde `manifest.json` con filtros por categoría (**Trámites**, **Servicios**, **Becas**) y buscador en tiempo real.
* **Ficha detallada por recurso:** Presenta descripción, requisitos, documentos solicitados, pasos a seguir, canales de atención, costos/pagos, preguntas frecuentes y enlaces oficiales externos mediante `url_launcher`.
* **Ubicación en mapa:** Enlace directo a la ventanilla o departamento correspondiente dentro de ESCOM (o aviso explícito cuando el trámite se realiza en una instancia externa).

---

## Arquitectura y Tecnologías

El código fuente está desarrollado íntegramente en **Dart** utilizando el framework **Flutter** bajo **Clean Architecture**, desacoplando la lógica de negocio de la interfaz visual y de la capa de datos:

| Capa / Módulo | Tecnología / Paquete | Responsabilidad |
| :--- | :--- | :--- |
| **Framework UI** | Flutter (Material 3) | Renderizado de interfaces, gestos táctiles y componentes visuales. |
| **Lenguaje** | Dart | Lógica de negocio, entidades, parsers, validadores y algoritmos. |
| **Navegación** | `go_router` | Enrutamiento declarativo con preservación de estado entre pestañas y soporte para parámetros internos (ej. `/mapa?lugar=biblioteca&ruta=1`). |
| **Base de Datos** | **Drift** (SQLite reactivo) | Persistencia local en el dispositivo para horarios, sesiones de clase y preferencias de usuario. |
| **Enrutamiento** | Algoritmo **A\*** | Búsqueda de caminos óptimos sobre grafos calibrados por piso. |
| **Lector PDF** | `syncfusion_flutter_pdf` + `file_picker` | Extracción de texto y estructuración de horarios del SAES 100% offline. |
| **Enlaces Externos** | `url_launcher` | Apertura de portales institucionales en el navegador del sistema. |

---

## Organización y Estructura del Proyecto

```text
escom_orienta_moviles/
├── android/                  # Configuración nativa de Android y scripts de compilación Gradle (.kts)
├── assets/                   # Mapas de plantas (pb, p1, p2), grafos de rutas y catálogo manifest.json
├── lib/
│   ├── data/                 # Repositorios, tablas/DAOs de Drift, parser de PDF y fuentes locales
│   ├── domain/               # Entidades puras, casos de uso, algoritmo A* y validadores de horarios
│   ├── navigation/           # Configuración centralizada de rutas y destinos con go_router
│   ├── ui/                   # Pantallas principales (Inicio, Mapa, Horario, Trámites) y widgets
│   └── main.dart             # Punto de entrada de la aplicación e inicialización de dependencias
├── test/                     # Suite de 72 pruebas automatizadas (unitarias y de widgets)
└── pubspec.yaml              # Declaración de paquetes, versión del SDK y registro de assets

## Requisitos del Entorno y cómo instalarlos

Para clonar, compilar y ejecutar este proyecto en cualquier computadora desde cero, debes seguir estos pasos detallados para instalar las herramientas necesarias:

### 1. Instalar Git
* **Qué es:** El sistema de control de versiones para descargar el repositorio.
* **Cómo instalarlo:** Descárgalo e instálalo desde [git-scm.com](https://git-scm.com/) seleccionando las opciones recomendadas por defecto.

### 2. Instalar el SDK de Flutter (y Dart)
* **Qué es:** El framework multiplataforma y el lenguaje de programación en el que está construida la app.
* **Cómo instalarlo:** 
  1. Entra a [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) y descarga el instalador correspondiente a tu sistema operativo.
  2. Extrae el archivo comprimido en una ruta fija de tu disco (por ejemplo, `C:\src\flutter`).
  3. Agrega la ruta completa de la carpeta `bin` de Flutter (ej. `C:\src\flutter\bin`) a las **Variables de Entorno (PATH)** de tu sistema operativo.

### 3. Instalar Android Studio y el Android SDK
* **Qué es:** El entorno de desarrollo que incluye las herramientas de compilación de Android y los emuladores virtuales.
* **Cómo instalarlo:**
  1. Descarga e instala Android Studio desde [developer.android.com/studio](https://developer.android.com/studio).
  2. Abre Android Studio, ve a **Tools > SDK Manager** (o *Settings > Languages & Frameworks > Android SDK*).
  3. Asegúrate de instalar y marcar las siguientes herramientas:
     * **Android SDK Platform 37** (para cumplir con `compileSdk = 37`).
     * **Android SDK Build-Tools** y **Platform-Tools**.
  4. En la pestaña **Device Manager** de Android Studio, crea un dispositivo virtual (Emulador) con **Android 10 (API 29)** o superior.

### 4. Verificar la instalación del entorno
Abre tu terminal (PowerShell o CMD) y ejecuta el siguiente comando para verificar que todo esté configurado correctamente:
```bash
flutter doctor
```

---

## Cuenta de usuario y cumplimiento DAMN-20271

Desde la revisión DAMN-20271 la app incluye **autenticación local** (registro, inicio de sesión,
perfil con avatar por cámara/galería, recuperación por pregunta de seguridad y cierre de sesión),
**notificaciones locales** de recordatorio de clase y **ubicación GPS** opcional. Todo funciona
**sin conexión**: las contraseñas se guardan con hash SHA-256 + sal y el token de sesión en el
almacenamiento seguro del sistema.

- Resumen de cumplimiento por requerimiento: [`CAMBIOS_DAMN.md`](CAMBIOS_DAMN.md)
- Diagramas UML (arquitectura, clases, secuencia): [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md)

> Tras clonar, ejecuta `flutter pub get` para instalar las dependencias nuevas
> (`crypto`, `flutter_secure_storage`, `image_picker`, `geolocator`).
