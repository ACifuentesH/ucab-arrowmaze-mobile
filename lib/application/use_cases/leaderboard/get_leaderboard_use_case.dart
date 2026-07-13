import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/ports/i_leaderboard_repository.dart';

/// El backend devuelve las entries ordenadas (mayor score primero).
class GetLeaderboardUseCase {
  final ILeaderboardRepository _leaderboard;

  const GetLeaderboardUseCase({required ILeaderboardRepository leaderboard})
      : _leaderboard = leaderboard;

  Future<List<LeaderboardEntryDto>> execute(
    String levelId, {
    int limit = 10,
  }) {
    return _leaderboard.getLeaderboard(levelId, limit: limit);
  }
}
