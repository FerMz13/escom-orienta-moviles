# Arquitectura y Diagramas UML — ESCOM Orienta Móviles

Diagramas de apoyo para la documentación y defensa (DAMN-20271). Se renderizan en GitHub (Mermaid).

## 1. Arquitectura por capas (Clean Architecture)

```mermaid
flowchart TB
    subgraph UI["UI (Flutter + Riverpod)"]
        Auth["auth/ (login, registro, recuperación)"]
        Profile["profile/"]
        Home["home / map / schedule / procedures"]
        Router["navigation/ (go_router + guard de sesión)"]
    end
    subgraph Domain["Domain (Dart puro)"]
        AuthM["auth/ (modelos, hasher, repo abstracto)"]
        Nav["navigation/ (A*)"]
        Sched["schedule/ (validadores)"]
    end
    subgraph Data["Data"]
        AuthData["auth/ (repo local, JSON privado, secure storage)"]
        Notif["notifications/"]
        Device["device/ (cámara, GPS)"]
        DB["database/ (Drift · SQLite)"]
        MapData["map/ · institutional/ · schedule/pdf/"]
    end
    UI --> Domain
    UI --> Data
    Data --> Domain
    AuthData -->|hash SHA-256+sal| AuthM
    AuthData -->|token| Keystore[(Keystore / Keychain)]
    DB --> SQLite[(SQLite)]
```

## 2. Diagrama de clases — módulo de Autenticación (RF1)

```mermaid
classDiagram
    class AuthRepository {
        <<interface>>
        +currentUser() UserAccount?
        +register(...) AuthResult
        +login(email, password) AuthResult
        +logout()
        +updateProfile(...) AuthResult
        +changePassword(...) AuthResult
        +securityQuestionFor(email) String?
        +recoverPassword(...) AuthResult
    }
    class LocalAuthRepository {
        -UserLocalDataSource users
        -SessionStore session
    }
    class UserLocalDataSource {
        +readAll() List~StoredUser~
        +upsert(StoredUser)
        +findByEmail(email) StoredUser?
    }
    class SessionStore {
        <<interface>>
        +readUserId() String?
        +writeUserId(id)
        +clear()
    }
    class SecureSessionStore
    class PasswordHasher {
        <<utility>>
        +generateSalt() String
        +hash(value, salt) String
        +verify(value, salt, hash) bool
    }
    class UserAccount {
        +id, email, fullName
        +avatarPath, securityQuestion
    }
    class AuthResult {
        <<sealed>>
    }
    AuthRepository <|.. LocalAuthRepository
    SessionStore <|.. SecureSessionStore
    LocalAuthRepository --> UserLocalDataSource
    LocalAuthRepository --> SessionStore
    LocalAuthRepository ..> PasswordHasher
    LocalAuthRepository ..> UserAccount
    LocalAuthRepository ..> AuthResult
```

## 3. Secuencia — Inicio de sesión y guardia de navegación

```mermaid
sequenceDiagram
    actor U as Usuario
    participant L as LoginScreen
    participant C as AuthController
    participant R as LocalAuthRepository
    participant S as SecureSessionStore
    participant G as GoRouter (redirect)

    U->>L: correo + contraseña
    L->>C: login(email, password)
    C->>R: login(email, password)
    R->>R: verify(password, salt, hash)
    alt credenciales válidas
        R->>S: writeUserId(id)
        R-->>C: AuthSuccess(user)
        C-->>G: estado = authenticated (refreshListenable)
        G-->>U: redirige a /inicio
    else inválidas
        R-->>C: AuthFailure(msg)
        C-->>L: muestra error
    end
```

## 4. Secuencia — Recordatorios de clase (RF3)

```mermaid
sequenceDiagram
    participant P as providers (notificationSyncProvider)
    participant N as NotificationService
    participant OS as Sistema

    Note over P: cambia el horario activo o las preferencias
    P->>N: syncClassReminders(horario, settings)
    N->>N: cancelAll()
    loop por cada clase
        N->>OS: zonedSchedule(inicio - X min, semanal)
    end
```
