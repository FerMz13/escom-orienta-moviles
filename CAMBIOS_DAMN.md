# Cumplimiento de Requerimientos DAMN-20271 — ESCOM Orienta Móviles

Documento de verificación del proyecto contra la rúbrica **DAMN-20271** (Requerimientos
Funcionales, No Funcionales y matriz de evaluación). Resume lo que ya cumplía el proyecto,
lo que se implementó en esta revisión y las notas de verificación.

> **Enfoque de autenticación:** la app es **100% offline** por diseño, por lo que RF1 se
> implementó con **autenticación local**: usuarios en almacenamiento privado del dispositivo,
> contraseñas y respuestas de seguridad con **hash SHA-256 + sal**, y **token de sesión en el
> almacenamiento seguro del sistema** (Android Keystore / iOS Keychain vía `flutter_secure_storage`).
> No se usa backend ni red, coherente con el resto de la aplicación.

---

## 1. Requerimientos Funcionales

### RF1 · Usuarios y Autenticación — **Implementado en esta revisión**
| Capacidad | Estado | Dónde |
| :-- | :-- | :-- |
| Registro e Ingreso (credenciales locales) | ✅ Nuevo | `ui/auth/register_screen.dart`, `login_screen.dart` |
| Gestión de Perfil (datos, avatar, preferencias) | ✅ Nuevo | `ui/profile/profile_screen.dart` |
| Control de Sesión (token seguro, cierre, recuperación) | ✅ Nuevo | `data/auth/`, `ui/auth/recover_password_screen.dart` |

- Alta de usuario con **validación en tiempo real** (correo, fuerza de contraseña, confirmación).
- Avatar con **cámara o galería** (`image_picker`), guardado en almacenamiento privado.
- **Recuperación de contraseña** mediante pregunta de seguridad (respuesta hasheada con sal propia).
- **Cierre de sesión seguro** con confirmación; la sesión se restaura al reabrir la app.
- Guardia de navegación: sin sesión solo se accede a Login/Registro/Recuperación (`navigation/app_router.dart`).

### RF2 · Gestión de Datos (CRUD) — **Ya cumplía**
- CRUD completo del **Horario** (crear/editar/eliminar sesiones) con validación de conflictos en
  tiempo real y borrado con confirmación — `ui/schedule/`, `data/schedule/schedule_repository.dart`.
- **Búsqueda, filtros y detalle** en Trámites/Servicios/Becas y buscador de lugares tolerante a
  acentos en el Mapa — `ui/procedures/`, `ui/map/place_search_delegate.dart`.

### RF3 · UI, Sensores y Notificaciones — **Parcial → Completado**
| Capacidad | Antes | Ahora |
| :-- | :-- | :-- |
| Navegación (bottom bar) | ✅ | ✅ `navigation/app_shell.dart` |
| Persistencia offline (SQLite/Drift) | ✅ | ✅ `data/database/` |
| **Notificaciones locales** | ⚠️ dependencia sin usar | ✅ `data/notifications/notification_service.dart` |
| **Cámara / galería** | ❌ | ✅ `data/device/avatar_image_service.dart` |
| **GPS (opcional)** | ❌ | ✅ `data/device/location_service.dart` |

- Las notificaciones reprograman recordatorios de clase al cambiar el horario o las preferencias
  (`ui/providers.dart` → `notificationSyncProvider`), usando `timezone` (por defecto `America/Mexico_City`).

---

## 2. Requerimientos No Funcionales

### RNF1 · Rendimiento y Experiencia (UX) — **Ya cumplía**
- Estados de carga (spinners / `AsyncValueView`), mensajes de error al usuario, diseño responsivo
  (Grid/Wrap/ConstrainedBox), Material 3, navegación de pocos toques.

### RNF2 · Seguridad, Estabilidad y Código — **Reforzado**
| Atributo | Estado | Nota |
| :-- | :-- | :-- |
| Seguridad (hash de datos sensibles, sin credenciales en código duro) | ✅ Nuevo | SHA-256+sal (`domain/auth/password_hasher.dart`), token en Keystore/Keychain |
| Confiabilidad (manejo **global** de excepciones) | ✅ Nuevo | `main.dart`: `runZonedGuarded`, `FlutterError.onError`, `ErrorWidget.builder` |
| Mantenibilidad (Clean Architecture, Git) | ✅ | Arquitectura limpia existente + **repositorio Git inicializado con commits por módulo** |
| Eficiencia de recursos (< 180 MB RAM) | ⚠️ Pendiente de medición | Sin estructuras pesadas nuevas; medir con DevTools en la demo |

---

## 3. Lo nuevo implementado (resumen técnico)

**Capa de dominio (`lib/domain/auth/`)**
- `password_hasher.dart` — hash SHA-256 + sal, verificación en tiempo constante, normalización de respuestas.
- `auth_models.dart` — `UserAccount`, `AuthResult`, `AuthState`, validadores reutilizables.
- `auth_repository.dart` — contrato de autenticación.

**Capa de datos (`lib/data/`)**
- `auth/user_local_data_source.dart` — usuarios en JSON privado + `SessionStore` (secure storage).
- `auth/local_auth_repository.dart` — registro/login/perfil/cambio/recuperación.
- `notifications/notification_service.dart` — recordatorios de clase con `flutter_local_notifications` + `timezone`.
- `device/avatar_image_service.dart` — cámara/galería.
- `device/location_service.dart` — ubicación GPS.

**Capa de UI (`lib/ui/`)**
- `auth/` (login, registro, recuperación, splash, controlador de sesión), `profile/profile_screen.dart`.
- Guardia de sesión en `navigation/app_router.dart` + `router_provider.dart`; manejo global de errores en `main.dart`.

**Pruebas (`test/`)**
- `domain/password_hasher_test.dart`, `data/auth_repository_test.dart` (registro, login, duplicados,
  contraseñas débiles, cambio y recuperación de contraseña).

**Plataforma**
- Permisos Android (`POST_NOTIFICATIONS`, alarmas exactas, ubicación, cámara) e iOS (`NSCamera…`, `NSLocation…`).
- Dependencias nuevas: `crypto`, `flutter_secure_storage`, `image_picker`, `geolocator`.

---

## 4. Pendiente / para la defensa
- **Medir RAM** (< 180 MB) con Flutter DevTools durante la demo (RNF2 · Eficiencia).
- Diagramas UML: ver [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).
- (Opcional) OAuth real con Google/Firebase si se exige autenticación en la nube; hoy es local por diseño offline.

---

## 5. Verificación en tu entorno
Este cambio se escribió sin un SDK de Flutter disponible en la máquina de edición, por lo que **debe
compilarse y probarse** así:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift (sin cambios de esquema, pero regenera si hace falta)
flutter analyze
flutter test
flutter run
```

Historial Git (commits por módulo): `git log --oneline`.
