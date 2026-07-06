/// Payload de PUT /progress.
///
/// Los campos `last*` solo se envían al terminar un nivel: el backend crea
/// entrada de leaderboard únicamente si vienen [lastLevelId] y [lastScore].
class ProgressUpdate {
  final List<String> completedLevels;
  final Map<String, int> bestScores;
  final String currentLevelId;
  final String? lastLevelId;
  final int? lastScore;
  final int? lastMoves;
  final int? lastTimeSeconds;

  const ProgressUpdate({
    required this.completedLevels,
    required this.bestScores,
    required this.currentLevelId,
    this.lastLevelId,
    this.lastScore,
    this.lastMoves,
    this.lastTimeSeconds,
  });

  Map<String, dynamic> toJson() => {
        'completedLevels': completedLevels,
        'bestScores': bestScores,
        'currentLevelId': currentLevelId,
        if (lastLevelId != null) 'lastLevelId': lastLevelId,
        if (lastScore != null) 'lastScore': lastScore,
        if (lastMoves != null) 'lastMoves': lastMoves,
        if (lastTimeSeconds != null) 'lastTimeSeconds': lastTimeSeconds,
      };
}
