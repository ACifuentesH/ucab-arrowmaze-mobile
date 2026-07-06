import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';

/// STUB — feature/auth (compañera).
/// Orquesta el login contra IApiClient y expone la sesión normalizada.
/// El token queda guardado por el propio apiClient.
class LoginUseCase {
  final IApiClient _api;

  const LoginUseCase({required IApiClient api}) : _api = api;

  Future<AuthSession> execute({
    required String email,
    required String password,
  }) {
    // TODO(feature/auth): validaciones de entrada y política de reintentos.
    return _api.login(email: email, password: password);
  }
}
