import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:arrow_maze/domain/entities/user.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Persistencia segura del JWT vía [FlutterSecureStorage].
class SecureStorageImpl implements ILocalStorage {
  static const _tokenKey = 'auth_jwt';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  SecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  @override
  Future<void> saveUser(User user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  @override
  Future<User?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
