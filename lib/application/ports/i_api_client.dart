import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';

/// Puerto del cliente HTTP hacia ucab-arrowmaze-api (DIP).
///
/// Contratos (ver docs/backend-context.md):
///  - Envelope `{ success, data, message }` ya resuelto: los métodos
///    devuelven el `data` tipado o lanzan un ApiError.
///  - register/login guardan el token; getProgress/putProgress lo adjuntan
///    como `Authorization: Bearer <token>`.
///  - Errores 401/404/409/422/500 → subclases de ApiError.
abstract interface class IApiClient {
  /// POST /auth/register — guarda el token al tener éxito.
  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  });

  /// POST /auth/login — guarda el token al tener éxito.
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Borra el token local (logout de sesión).
  Future<void> logout();

  /// GET /progress (JWT). Lanza NotFoundError para usuario nuevo sin progreso.
  Future<PlayerProgressDto> getProgress();

  /// PUT /progress (JWT). Devuelve el progreso resultante.
  Future<PlayerProgressDto> putProgress(ProgressUpdate update);

  /// GET /leaderboard/:levelId?limit=n (público).
  Future<List<LeaderboardEntryDto>> getLeaderboard(
    String levelId, {
    int limit = 10,
  });

  /// GET /levels (público).
  Future<List<LevelDefinition>> getLevels();

  /// GET /levels/:id (público). Lanza NotFoundError si no existe.
  Future<LevelDefinition> getLevelById(String id);
}
