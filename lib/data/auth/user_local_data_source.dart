import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Registro de usuario tal como se persiste en disco (incluye datos sensibles
/// hasheados). No se expone a la UI; la capa de dominio usa `UserAccount`.
class StoredUser {
  StoredUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarPath,
    required this.salt,
    required this.passwordHash,
    required this.securityQuestion,
    required this.answerSalt,
    required this.securityAnswerHash,
    required this.createdAt,
  });

  final String id;
  final String email;
  String fullName;
  String? avatarPath;

  /// Sal de la contraseña (cambia al cambiar/recuperar contraseña).
  String salt;
  String passwordHash;
  String securityQuestion;

  /// Sal independiente de la respuesta de seguridad, para que rehashear la
  /// contraseña no invalide la recuperación.
  String answerSalt;
  String securityAnswerHash;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'avatarPath': avatarPath,
        'salt': salt,
        'passwordHash': passwordHash,
        'securityQuestion': securityQuestion,
        'answerSalt': answerSalt,
        'securityAnswerHash': securityAnswerHash,
        'createdAt': createdAt.toIso8601String(),
      };

  static StoredUser fromJson(Map<String, dynamic> json) => StoredUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        avatarPath: json['avatarPath'] as String?,
        salt: json['salt'] as String,
        passwordHash: json['passwordHash'] as String,
        securityQuestion: json['securityQuestion'] as String? ?? '',
        answerSalt: json['answerSalt'] as String? ?? json['salt'] as String,
        securityAnswerHash: json['securityAnswerHash'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Abstracción mínima del almacenamiento seguro del token de sesión, para
/// poder inyectar un doble en pruebas sin `FlutterSecureStorage`.
abstract interface class SessionStore {
  Future<String?> readUserId();
  Future<void> writeUserId(String userId);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  static const _key = 'escom_session_user_id';

  @override
  Future<String?> readUserId() => _storage.read(key: _key);

  @override
  Future<void> writeUserId(String userId) => _storage.write(key: _key, value: userId);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Carga y guarda usuarios en un archivo JSON dentro del almacenamiento privado
/// de la app (offline, sin red). El [fileProvider] es inyectable para pruebas.
typedef UserFileProvider = Future<File> Function();

class UserLocalDataSource {
  UserLocalDataSource({UserFileProvider? fileProvider})
      : _fileProvider = fileProvider ?? _defaultFile;

  final UserFileProvider _fileProvider;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'escom_users.json'));
  }

  Future<List<StoredUser>> readAll() async {
    final file = await _fileProvider();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => StoredUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Archivo corrupto: se trata como vacío en vez de tirar la app.
      return [];
    }
  }

  Future<void> writeAll(List<StoredUser> users) async {
    final file = await _fileProvider();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final encoded = const JsonEncoder.withIndent('  ')
        .convert(users.map((u) => u.toJson()).toList());
    await file.writeAsString(encoded, flush: true);
  }

  Future<StoredUser?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = await readAll();
    for (final user in users) {
      if (user.email.toLowerCase() == normalized) return user;
    }
    return null;
  }

  Future<StoredUser?> findById(String id) async {
    final users = await readAll();
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  /// Inserta o reemplaza por `id` y persiste.
  Future<void> upsert(StoredUser user) async {
    final users = await readAll();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await writeAll(users);
  }
}
