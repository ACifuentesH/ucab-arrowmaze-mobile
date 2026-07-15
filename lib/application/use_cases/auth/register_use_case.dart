import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';

class RegisterUseCase {
  final IApiClient _api;
  final IUserStorage _userStorage;

  const RegisterUseCase({
    required IApiClient api,
    required IUserStorage userStorage,
  })  : _api = api,
        _userStorage = userStorage;

  Future<AuthUser> execute({
    required String username,
    required String email,
    required String password,
  }) async {
    final session = await _api.register(
      username: username,
      email: email,
      password: password,
    );
    await _userStorage.save(session.user);
    return session.user;
  }
}
