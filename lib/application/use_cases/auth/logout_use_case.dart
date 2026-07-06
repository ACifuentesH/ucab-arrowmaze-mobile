import 'package:arrow_maze/application/ports/i_api_client.dart';

/// STUB — feature/auth (compañera). Borra la sesión local.
class LogoutUseCase {
  final IApiClient _api;

  const LogoutUseCase({required IApiClient api}) : _api = api;

  Future<void> execute() => _api.logout();
}
