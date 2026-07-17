import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';

/// Object Mother: entries de leaderboard válidas.
class LeaderboardEntryMother {
  static LeaderboardEntryDto entry({
    String username = 'alice',
    String levelId = 'level_1',
    int score = 950,
  }) =>
      LeaderboardEntryDto(
        userId: 'u-1',
        username: username,
        levelId: levelId,
        score: score,
        moves: 8,
        timeSeconds: 45,
        rankedAt: DateTime.utc(2026, 7, 1),
      );
}
