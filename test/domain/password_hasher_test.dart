import 'package:escom_orienta_moviles/domain/auth/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordHasher', () {
    test('un mismo valor con sales distintas produce hashes distintos', () {
      final s1 = PasswordHasher.generateSalt();
      final s2 = PasswordHasher.generateSalt();
      expect(s1, isNot(equals(s2)));
      expect(PasswordHasher.hash('Secreta123', s1),
          isNot(equals(PasswordHasher.hash('Secreta123', s2))));
    });

    test('verify acepta la contraseña correcta y rechaza la incorrecta', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('Secreta123', salt);
      expect(PasswordHasher.verify('Secreta123', salt, hash), isTrue);
      expect(PasswordHasher.verify('otra', salt, hash), isFalse);
    });

    test('la contraseña en claro nunca aparece en el hash', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('Secreta123', salt);
      expect(hash.contains('Secreta123'), isFalse);
    });

    test('normalizeAnswer ignora mayúsculas y espacios extra', () {
      expect(PasswordHasher.normalizeAnswer('  Mi  Perro '),
          equals(PasswordHasher.normalizeAnswer('mi perro')));
    });
  });
}
