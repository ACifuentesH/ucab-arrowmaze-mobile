import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/services/score_calculator.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';

/// Mapea el DTO remoto de progreso al modelo local [LevelProgress].
///
/// El backend no envía estrellas: se estiman a partir de [bestScores] y,
/// cuando está disponible, del catálogo (flechas / dificultad / límite).
abstract final class ProgressMapper {
  /// Convierte GET/PUT `/progress` → entradas locales.
  ///
  /// Une `completedLevels` con las claves de `bestScores` (mapa JSON
  /// `{ levelId: score }`, nunca un array).
  static List<LevelProgress> toLocalEntries(
    PlayerProgressDto dto, {
    Map<String, LevelPreview> catalogById = const {},
  }) {
    final scores = Map<String, int>.from(dto.bestScores);
    final levelIds = <String>{
      ...dto.completedLevels,
      ...scores.keys,
    };

    final now = DateTime.now();
    return levelIds.map((levelId) {
      final score = scores[levelId] ?? 0;
      return LevelProgress(
        levelId: levelId,
        bestScore: score,
        bestTimeSeconds: 0,
        starsEarned: starsFromScore(score, catalogById[levelId]),
        completedAt: now,
      );
    }).toList();
  }

  /// Estrellas 1–3 a partir del score remoto y el preview del nivel (si existe).
  static int starsFromScore(int score, LevelPreview? preview) {
    if (score <= 0) return 1;
    if (preview == null) {
      // Sin catálogo: umbrales absolutos razonables post-hidratación.
      if (score >= 800) return 3;
      if (score >= 500) return 2;
      return 1;
    }

    final maxPossible = ScoreCalculator.calculate(
      arrowCount: preview.arrowCount,
      livesRemaining: Lives.defaultCount,
      elapsedSeconds: 0,
      timeLimitSeconds: preview.timeLimitSeconds,
      difficulty: preview.difficulty,
    );
    if (maxPossible <= 0) return 1;
    return ScoreCalculator.starsFor(score, maxPossibleScore: maxPossible);
  }
}
