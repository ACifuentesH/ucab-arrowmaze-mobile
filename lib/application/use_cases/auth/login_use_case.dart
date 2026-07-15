import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';

/// Orquesta el login contra [IApiClient] y persiste la sesión local.
class LoginUseCase {
  final IApiClient _api;
  final IUserStorage _userStorage;

  const LoginUseCase({
    required IApiClient api,
    required IUserStorage userStorage,
  })  : _api = api,
        _userStorage = userStorage;

  Future<AuthUser> execute({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(email: email, password: password);
    await _userStorage.save(session.user);
    return session.user;
  }
}
