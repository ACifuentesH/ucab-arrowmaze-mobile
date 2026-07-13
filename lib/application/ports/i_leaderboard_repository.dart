import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';

/// Puerto remoto del ranking por nivel.
abstract interface class ILeaderboardRepository {
  Future<List<LeaderboardEntryDto>> getLeaderboard(
    String levelId, {
    int limit = 10,
  });
}
