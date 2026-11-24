import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/auth_models.dart';
import '../../domain/auth/auth_repository.dart';
import '../providers.dart';

/// Controla el estado de sesión y expone las operaciones de autenticación a la
/// UI. Al construirse intenta restaurar la sesión guardada (token seguro).
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    _restore();
    return const AuthState.unknown();
  }

  Future<void> _restore() async {
    try {
      final user = await _repo.currentUser();
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final result = await _repo.login(email: email, password: password);
    if (result case AuthSuccess(:final user)) state = AuthState.authenticated(user);
    return result;
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final result = await _repo.register(
      email: email,
      password: password,
      fullName: fullName,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
    if (result case AuthSuccess(:final user)) state = AuthState.authenticated(user);
    return result;
  }

  Future<AuthResult> updateProfile({
    String? fullName,
    String? avatarPath,
    bool clearAvatar = false,
  }) async {
    final result = await _repo.updateProfile(
      fullName: fullName,
      avatarPath: avatarPath,
      clearAvatar: clearAvatar,
    );
    if (result case AuthSuccess(:final user)) state = AuthState.authenticated(user);
    return result;
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repo.changePassword(currentPassword: currentPassword, newPassword: newPassword);

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
