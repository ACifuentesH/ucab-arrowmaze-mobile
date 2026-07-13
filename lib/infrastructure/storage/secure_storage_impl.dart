import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Persistencia segura del JWT vía [FlutterSecureStorage].
class SecureStorageImpl implements ILocalStorage {
  static const _tokenKey = 'auth_jwt';

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
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
