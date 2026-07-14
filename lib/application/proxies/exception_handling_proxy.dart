// Campos privados + parámetros con nombre (convención del repo, igual que
// UseCaseLoggerProxy). Dart prohíbe parámetros con nombre privados, por lo que
// `prefer_initializing_formals` no es aplicable aquí.
// ignore_for_file: prefer_initializing_formals
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';

/// AOP – Proxy de manejo centralizado de excepciones para [IApiClient].
///
/// Aspecto transversal: unifica el tratamiento de errores de red para *todas*
/// las llamadas al puerto, sin que cada caso de uso repita el `try/catch`.
///  - Errores ya tipados ([ApiError]: 401/404/409/422/500) se propagan intactos.
///  - Cualquier excepción inesperada del transporte (TimeoutException,
///    SocketException, etc.) se normaliza a [NetworkError] tipado.
///  - Reintenta *solo* fallos transitorios de transporte ([NetworkError]) hasta
///    [maxAttempts] veces; nunca reintenta errores deterministas de la API
///    (un 404 o un 422 volverían a fallar igual).
///
/// Substitución transparente (patrón Proxy): implementa [IApiClient], por lo que
/// se inyecta en `apiClientProvider` envolviendo al `HttpApiClient` real.
class ExceptionHandlingApiClientProxy implements IApiClient {
  final IApiClient _delegate;
  final int _maxAttempts;
  final Duration _retryDelay;

  ExceptionHandlingApiClientProxy({
    required IApiClient delegate,
    int maxAttempts = 2,
    Duration retryDelay = const Duration(milliseconds: 300),
  })  : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
        _delegate = delegate,
        _maxAttempts = maxAttempts,
        _retryDelay = retryDelay;

  /// Núcleo del aspecto: ejecuta [action] mapeando/reintentando de forma uniforme.
  Future<T> _guard<T>(Future<T> Function() action) async {
    ApiError? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await action();
      } on ApiError catch (e) {
        // Errores deterministas (401/404/409/422/500) no se reintentan.
        if (e is! NetworkError) rethrow;
        lastError = e;
      } catch (e) {
        // Excepciones no tipadas del transporte → NetworkError uniforme.
        lastError = NetworkError('Unhandled transport failure: $e');
      }
      if (attempt < _maxAttempts) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    throw lastError!;
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) =>
      _guard(() => _delegate.register(
            username: username,
            email: email,
            password: password,
          ));

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) =>
      _guard(() => _delegate.login(email: email, password: password));

  @override
  Future<void> logout() => _guard(() => _delegate.logout());

  @override
  Future<PlayerProgressDto> getProgress() =>
      _guard(() => _delegate.getProgress());

  @override
  Future<PlayerProgressDto> putProgress(ProgressUpdate update) =>
      _guard(() => _delegate.putProgress(update));

  @override
  Future<List<LeaderboardEntryDto>> getLeaderboard(
    String levelId, {
    int limit = 10,
  }) =>
      _guard(() => _delegate.getLeaderboard(levelId, limit: limit));

  @override
  Future<List<LevelDefinition>> getLevels() =>
      _guard(() => _delegate.getLevels());

  @override
  Future<LevelDefinition> getLevelById(String id) =>
      _guard(() => _delegate.getLevelById(id));
}
