import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';

/// STUB — feature/leaderboard (compañera).
/// El backend ya devuelve las entries ordenadas (mayor score primero).
class GetLeaderboardUseCase {
  final IApiClient _api;

  const GetLeaderboardUseCase({required IApiClient api}) : _api = api;

  Future<List<LeaderboardEntryDto>> execute(
    String levelId, {
    int limit = 10,
  }) {
    // TODO(feature/leaderboard): cache local / estados empty-error-loading.
    return _api.getLeaderboard(levelId, limit: limit);
  }
}
