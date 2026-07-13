import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/domain/entities/user.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Implementación de autenticación: API remota + persistencia segura del JWT.
class AuthRepositoryImpl implements IAuthRepository {
  final IApiClient _api;
  final ILocalStorage _storage;

  const AuthRepositoryImpl({
    required IApiClient api,
    required ILocalStorage storage,
  })  : _api = api,
        _storage = storage;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    return _persistSession(data);
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    return _persistSession(data);
  }

  @override
  Future<void> logout() => _storage.deleteToken();

  @override
  Future<User?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    final user = await _storage.readUser();
    if (user == null) {
      await _storage.deleteToken();
      return null;
    }

    return user;
  }

  Future<User> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveToken(token);
    await _storage.saveUser(user);
    return user;
  }
}
