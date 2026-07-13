import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_leaderboard_repository.dart';
import 'package:arrow_maze/application/ports/i_progress_repository.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

class ProgressRepositoryImpl implements IProgressRepository {
  final IApiClient _api;
  final ILocalStorage _storage;

  const ProgressRepositoryImpl({
    required IApiClient api,
    required ILocalStorage storage,
  })  : _api = api,
        _storage = storage;

  @override
  Future<PlayerProgressDto> getProgress() async {
    await requireStoredToken(_storage);
    final data = await _api.get('/progress');
    return PlayerProgressDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PlayerProgressDto> putProgress(ProgressUpdate update) async {
    await requireStoredToken(_storage);
    final data = await _api.put('/progress', body: update.toJson());
    return PlayerProgressDto.fromJson(data as Map<String, dynamic>);
  }
}

class LeaderboardRepositoryImpl implements ILeaderboardRepository {
  final IApiClient _api;

  const LeaderboardRepositoryImpl({required IApiClient api}) : _api = api;

  @override
  Future<List<LeaderboardEntryDto>> getLeaderboard(
    String levelId, {
    int limit = 10,
  }) async {
    final data = await _api.get(
      '/leaderboard/$levelId',
      queryParameters: {'limit': limit},
    );
    return (data as List<dynamic>)
        .map((e) => LeaderboardEntryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Repositorio remoto de niveles del backend (contrato `/levels`).
class LevelsRemoteRepository {
  final IApiClient _api;

  const LevelsRemoteRepository({required IApiClient api}) : _api = api;

  Future<List<LevelDefinition>> getLevels() async {
    final data = await _api.get('/levels');
    return (data as List<dynamic>)
        .map((e) => LevelDefinition.fromBackendJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LevelDefinition> getLevelById(String id) async {
    final data = await _api.get('/levels/$id');
    return LevelDefinition.fromBackendJson(data as Map<String, dynamic>);
  }
}

/// Lanza [UnauthorizedError] si no hay JWT almacenado (rutas protegidas).
Future<void> requireStoredToken(ILocalStorage storage) async {
  final token = await storage.readToken();
  if (token == null || token.isEmpty) {
    throw const UnauthorizedError('No stored session token');
  }
}
