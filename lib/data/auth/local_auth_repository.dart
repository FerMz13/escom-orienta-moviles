import 'dart:math';

import '../../domain/auth/auth_models.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/password_hasher.dart';
import 'user_local_data_source.dart';

/// Implementación 100% local de [AuthRepository]: usuarios en archivo JSON
/// privado, contraseñas y respuestas de seguridad hasheadas (SHA-256 + sal) y
/// token de sesión en almacenamiento seguro del sistema (Keystore/Keychain).
///
/// No hay red ni backend: coherente con el diseño offline de la app y suficiente
/// para cubrir RF1 (registro/login/sesión/recuperación) y los criterios de
/// seguridad de RNF2 (hash de datos sensibles, sin credenciales en código duro).
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._users, this._session);

  final UserLocalDataSource _users;
  final SessionStore _session;

  UserAccount _toAccount(StoredUser u) => UserAccount(
        id: u.id,
        email: u.email,
        fullName: u.fullName,
        avatarPath: u.avatarPath,
        securityQuestion: u.securityQuestion,
        createdAt: u.createdAt,
      );

  String _newId() {
    final random = Random.secure();
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rand = random.nextInt(1 << 32).toRadixString(16);
    return 'u_${stamp}_$rand';
  }

  @override
  Future<UserAccount?> currentUser() async {
    final id = await _session.readUserId();
    if (id == null) return null;
    final user = await _users.findById(id);
    if (user == null) {
      // Sesión apuntando a un usuario inexistente: se limpia.
      await _session.clear();
      return null;
    }
    return _toAccount(user);
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final emailError = AuthValidators.email(normalizedEmail);
    if (emailError != null) return AuthResult.failure(emailError);
    final passwordError = AuthValidators.password(password);
    if (passwordError != null) return AuthResult.failure(passwordError);
    if (AuthValidators.fullName(fullName) case final e?) return AuthResult.failure(e);
    if (securityQuestion.trim().isEmpty || securityAnswer.trim().isEmpty) {
      return const AuthResult.failure('Configura una pregunta y respuesta de seguridad.');
    }

    if (await _users.findByEmail(normalizedEmail) != null) {
      return const AuthResult.failure('Ya existe una cuenta con ese correo.');
    }

    final salt = PasswordHasher.generateSalt();
    final answerSalt = PasswordHasher.generateSalt();
    final user = StoredUser(
      id: _newId(),
      email: normalizedEmail,
      fullName: fullName.trim(),
      salt: salt,
      passwordHash: PasswordHasher.hash(password, salt),
      securityQuestion: securityQuestion.trim(),
      answerSalt: answerSalt,
      securityAnswerHash:
          PasswordHasher.hash(PasswordHasher.normalizeAnswer(securityAnswer), answerSalt),
      createdAt: DateTime.now(),
    );
    await _users.upsert(user);
    await _session.writeUserId(user.id);
    await _session.writeGuest(false);
    return AuthResult.success(_toAccount(user));
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    final user = await _users.findByEmail(email);
    // Mensaje genérico para no revelar si el correo existe.
    const invalid = AuthResult.failure('Correo o contraseña incorrectos.');
    if (user == null) return invalid;
    if (!PasswordHasher.verify(password, user.salt, user.passwordHash)) return invalid;
    await _session.writeUserId(user.id);
    await _session.writeGuest(false);
    return AuthResult.success(_toAccount(user));
  }

  @override
  Future<void> logout() => _session.clear();

  @override
  Future<bool> isGuestSession() => _session.readGuest();

  @override
  Future<void> continueAsGuest() => _session.writeGuest(true);

  @override
  Future<AuthResult> updateProfile({
    String? fullName,
    String? avatarPath,
    bool clearAvatar = false,
  }) async {
    final id = await _session.readUserId();
    if (id == null) return const AuthResult.failure('No hay sesión activa.');
    final user = await _users.findById(id);
    if (user == null) return const AuthResult.failure('Usuario no encontrado.');

    if (fullName != null) {
      if (AuthValidators.fullName(fullName) case final e?) return AuthResult.failure(e);
      user.fullName = fullName.trim();
    }
    if (clearAvatar) {
      user.avatarPath = null;
    } else if (avatarPath != null) {
      user.avatarPath = avatarPath;
    }
    await _users.upsert(user);
    return AuthResult.success(_toAccount(user));
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final id = await _session.readUserId();
    if (id == null) return const AuthResult.failure('No hay sesión activa.');
    final user = await _users.findById(id);
    if (user == null) return const AuthResult.failure('Usuario no encontrado.');
    if (!PasswordHasher.verify(currentPassword, user.salt, user.passwordHash)) {
      return const AuthResult.failure('La contraseña actual no es correcta.');
    }
    if (AuthValidators.password(newPassword) case final e?) return AuthResult.failure(e);
    if (newPassword == currentPassword) {
      return const AuthResult.failure('La nueva contraseña debe ser distinta.');
    }

    // Sal nueva solo para la contraseña. La respuesta de seguridad conserva su
    // propia sal (`answerSalt`), así que la recuperación sigue funcionando.
    final newSalt = PasswordHasher.generateSalt();
    user.salt = newSalt;
    user.passwordHash = PasswordHasher.hash(newPassword, newSalt);
    await _users.upsert(user);
    return AuthResult.success(_toAccount(user));
  }

  @override
  Future<String?> securityQuestionFor(String email) async {
    final user = await _users.findByEmail(email);
    return user?.securityQuestion;
  }

  @override
  Future<AuthResult> recoverPassword({
    required String email,
    required String securityAnswer,
    required String newPassword,
  }) async {
    final user = await _users.findByEmail(email);
    if (user == null) return const AuthResult.failure('No existe una cuenta con ese correo.');
    final normalized = PasswordHasher.normalizeAnswer(securityAnswer);
    if (!PasswordHasher.verify(normalized, user.answerSalt, user.securityAnswerHash)) {
      return const AuthResult.failure('La respuesta de seguridad no coincide.');
    }
    if (AuthValidators.password(newPassword) case final e?) return AuthResult.failure(e);

    // Rehashea la contraseña con una sal nueva. La respuesta mantiene su sal.
    final newSalt = PasswordHasher.generateSalt();
    user.salt = newSalt;
    user.passwordHash = PasswordHasher.hash(newPassword, newSalt);
    await _users.upsert(user);
    return AuthResult.success(_toAccount(user));
  }
}
