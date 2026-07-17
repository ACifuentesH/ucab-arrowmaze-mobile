import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';

/// Object Mother: DTOs de progreso válidos.
class ProgressMother {
  static LevelProgress completedLevel({
    String levelId = 'level_1',
    int bestScore = 900,
    int stars = 3,
  }) =>
      LevelProgress(
        levelId: levelId,
        bestScore: bestScore,
        bestTimeSeconds: 45,
        starsEarned: stars,
        completedAt: DateTime.utc(2026, 7, 1),
      );

  /// Update mínimo: sin campos last* (no genera leaderboard).
  static ProgressUpdate minimalUpdate() => const ProgressUpdate(
        completedLevels: ['level_1'],
        bestScores: {'level_1': 900},
        currentLevelId: 'level_2',
      );

  /// Update de fin de nivel: incluye last* para registrar leaderboard.
  static ProgressUpdate levelCompletedUpdate() => const ProgressUpdate(
        completedLevels: ['level_1'],
        bestScores: {'level_1': 950},
        currentLevelId: 'level_2',
        lastLevelId: 'level_1',
        lastScore: 950,
        lastMoves: 8,
        lastTimeSeconds: 45,
      );
}
