import 'auth_models.dart';

/// Contrato del módulo de autenticación (RF1). La implementación local vive en
/// `data/auth/local_auth_repository.dart`; se expone como interfaz para poder
/// sustituirla en pruebas con `ProviderScope(overrides: [...])`.
abstract interface class AuthRepository {
  /// Usuario de la sesión guardada, o `null` si no hay sesión activa.
  Future<UserAccount?> currentUser();

  /// Alta de un nuevo usuario. Falla si el correo ya existe.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String securityQuestion,
    required String securityAnswer,
  });

  /// Autenticación con credenciales locales.
  Future<AuthResult> login({required String email, required String password});

  /// Cierra la sesión activa (borra el token seguro).
  Future<void> logout();

  /// Actualiza nombre y/o avatar del usuario de la sesión.
  Future<AuthResult> updateProfile({String? fullName, String? avatarPath, bool clearAvatar = false});

  /// Cambia la contraseña verificando la actual.
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Pregunta de seguridad asociada a un correo (para el flujo de recuperación).
  Future<String?> securityQuestionFor(String email);

  /// Restablece la contraseña validando la respuesta de seguridad.
  Future<AuthResult> recoverPassword({
    required String email,
    required String securityAnswer,
    required String newPassword,
  });
}
