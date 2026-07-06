import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';

/// STUB — feature/auth (compañera).
class RegisterUseCase {
  final IApiClient _api;

  const RegisterUseCase({required IApiClient api}) : _api = api;

  Future<AuthSession> execute({
    required String username,
    required String email,
    required String password,
  }) {
    // TODO(feature/auth): validaciones locales (username 3-30, password >= 6).
    return _api.register(username: username, email: email, password: password);
  }
}
