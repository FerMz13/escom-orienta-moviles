/// Modelos del módulo de usuarios y autenticación (RF1).
library;

/// Validaciones reutilizables de credenciales (RF2: validación en tiempo real).
abstract final class AuthValidators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  /// Devuelve `null` si es válido, o un mensaje de error para el usuario.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu correo.';
    if (!_emailRegex.hasMatch(v)) return 'Correo no válido.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña.';
    if (v.length < 8) return 'Mínimo 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Debe incluir letras y números.';
    }
    return null;
  }

  static String? notEmpty(String? value, {String field = 'Este campo'}) {
    if ((value ?? '').trim().isEmpty) return '$field es obligatorio.';
    return null;
  }

  static String? fullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu nombre.';
    if (v.length < 3) return 'Nombre demasiado corto.';
    return null;
  }
}

/// Cuenta de usuario tal como la consume la UI (sin datos sensibles).
class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarPath,
    required this.securityQuestion,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;

  /// Ruta local a la foto de avatar (cámara o galería), si existe.
  final String? avatarPath;
  final String securityQuestion;
  final DateTime createdAt;

  /// Iniciales para el avatar por defecto (p. ej. "Ana López" -> "AL").
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  UserAccount copyWith({String? fullName, String? avatarPath, bool clearAvatar = false}) =>
      UserAccount(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
        securityQuestion: securityQuestion,
        createdAt: createdAt,
      );
}

/// Resultado de una operación de autenticación.
sealed class AuthResult {
  const AuthResult();

  const factory AuthResult.success(UserAccount user) = AuthSuccess;
  const factory AuthResult.failure(String message) = AuthFailure;

  bool get isSuccess => this is AuthSuccess;
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final UserAccount user;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

/// Estado de sesión observado por la UI y el enrutador.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user});

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(UserAccount user)
      : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final UserAccount? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnknown => status == AuthStatus.unknown;
}
