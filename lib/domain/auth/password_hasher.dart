import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashing de contraseñas y respuestas de seguridad.
///
/// Se usa SHA-256 con una sal aleatoria por usuario (`salt:valor`). Las
/// contraseñas en claro NUNCA se guardan ni se registran en logs; solo se
/// persiste `salt` + `hash`. Cumple el criterio RNF2 de "almacenamiento con
/// Hash para datos sensibles" sin exponer credenciales en código duro.
abstract final class PasswordHasher {
  /// Genera una sal aleatoria criptográficamente segura (base64url).
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash determinista de [value] con la [salt] dada.
  static String hash(String value, String salt) =>
      sha256.convert(utf8.encode('$salt:$value')).toString();

  /// Comparación en tiempo (casi) constante para evitar fugas por temporización.
  static bool verify(String value, String salt, String expectedHash) {
    final actual = hash(value, salt);
    if (actual.length != expectedHash.length) return false;
    var mismatch = 0;
    for (var i = 0; i < actual.length; i++) {
      mismatch |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return mismatch == 0;
  }

  /// Normaliza la respuesta de seguridad (minúsculas, sin espacios extra) para
  /// que la verificación no dependa de mayúsculas ni espacios.
  static String normalizeAnswer(String answer) =>
      answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
