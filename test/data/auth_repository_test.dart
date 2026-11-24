import 'dart:io';

import 'package:escom_orienta_moviles/data/auth/local_auth_repository.dart';
import 'package:escom_orienta_moviles/data/auth/user_local_data_source.dart';
import 'package:escom_orienta_moviles/domain/auth/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sesión en memoria (sin almacenamiento seguro del sistema).
class _MemSession implements SessionStore {
  String? _id;
  @override
  Future<String?> readUserId() async => _id;
  @override
  Future<void> writeUserId(String userId) async => _id = userId;
  @override
  Future<void> clear() async => _id = null;
}

void main() {
  late Directory tempDir;
  late LocalAuthRepository repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('escom_auth_test');
    final file = File('${tempDir.path}/users.json');
    final dataSource = UserLocalDataSource(fileProvider: () async => file);
    repo = LocalAuthRepository(dataSource, _MemSession());
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<AuthResult> register() => repo.register(
        email: 'alumno@ipn.mx',
        password: 'Secreta123',
        fullName: 'Ana López',
        securityQuestion: '¿Mascota?',
        securityAnswer: 'Firulais',
      );

  test('registro crea la cuenta e inicia sesión', () async {
    final result = await register();
    expect(result, isA<AuthSuccess>());
    final current = await repo.currentUser();
    expect(current?.email, 'alumno@ipn.mx');
    expect(current?.fullName, 'Ana López');
  });

  test('no permite correos duplicados', () async {
    await register();
    final again = await register();
    expect(again, isA<AuthFailure>());
  });

  test('rechaza contraseñas débiles', () async {
    final weak = await repo.register(
      email: 'x@ipn.mx',
      password: '123',
      fullName: 'X Y',
      securityQuestion: 'q',
      securityAnswer: 'a',
    );
    expect(weak, isA<AuthFailure>());
  });

  test('login válido e inválido', () async {
    await register();
    await repo.logout();
    expect(await repo.currentUser(), isNull);

    final bad = await repo.login(email: 'alumno@ipn.mx', password: 'incorrecta');
    expect(bad, isA<AuthFailure>());

    final ok = await repo.login(email: 'alumno@ipn.mx', password: 'Secreta123');
    expect(ok, isA<AuthSuccess>());
  });

  test('cambio de contraseña: la nueva funciona y la vieja no', () async {
    await register();
    final changed =
        await repo.changePassword(currentPassword: 'Secreta123', newPassword: 'NuevaClave9');
    expect(changed, isA<AuthSuccess>());
    await repo.logout();
    expect(await repo.login(email: 'alumno@ipn.mx', password: 'Secreta123'), isA<AuthFailure>());
    expect(await repo.login(email: 'alumno@ipn.mx', password: 'NuevaClave9'), isA<AuthSuccess>());
  });

  test('recuperación por respuesta de seguridad', () async {
    await register();
    final wrong = await repo.recoverPassword(
      email: 'alumno@ipn.mx',
      securityAnswer: 'otra',
      newPassword: 'Reset12345',
    );
    expect(wrong, isA<AuthFailure>());

    final ok = await repo.recoverPassword(
      email: 'alumno@ipn.mx',
      securityAnswer: 'firulais', // insensible a mayúsculas
      newPassword: 'Reset12345',
    );
    expect(ok, isA<AuthSuccess>());
    await repo.logout();
    expect(await repo.login(email: 'alumno@ipn.mx', password: 'Reset12345'), isA<AuthSuccess>());
  });

  test('la respuesta de seguridad sigue sirviendo tras cambiar contraseña', () async {
    await register();
    await repo.changePassword(currentPassword: 'Secreta123', newPassword: 'NuevaClave9');
    final recovered = await repo.recoverPassword(
      email: 'alumno@ipn.mx',
      securityAnswer: 'Firulais',
      newPassword: 'OtraClave88',
    );
    expect(recovered, isA<AuthSuccess>());
  });
}
