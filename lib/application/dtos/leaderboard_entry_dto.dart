/// Entrada de GET /leaderboard/:levelId.
class LeaderboardEntryDto {
  final String userId;
  final String username;
  final String levelId;
  final int score;
  final int moves;
  final int timeSeconds;
  final DateTime rankedAt;

  const LeaderboardEntryDto({
    required this.userId,
    required this.username,
    required this.levelId,
    required this.score,
    required this.moves,
    required this.timeSeconds,
    required this.rankedAt,
  });

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryDto(
        userId: json['userId'] as String,
        username: json['username'] as String,
        levelId: json['levelId'] as String,
        score: (json['score'] as num).toInt(),
        moves: (json['moves'] as num).toInt(),
        timeSeconds: (json['timeSeconds'] as num).toInt(),
        rankedAt: DateTime.parse(json['rankedAt'] as String),
      );
}
