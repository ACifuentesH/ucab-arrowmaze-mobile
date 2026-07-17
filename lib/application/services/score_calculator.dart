import 'package:arrow_maze/application/enums/difficulty.dart';

/// Fórmula de puntuación pura (sin estado, sin dependencias externas).
///
/// Score = (arrows×100 + lives_remaining×150 + time_bonus) × difficulty_multiplier
/// time_bonus = seconds_remaining × 10  (solo cuando hay límite de tiempo)
abstract final class ScoreCalculator {
  static const int _basePerArrow = 100;
  static const int _lifeBonus = 150;
  static const int _secondBonus = 10;

  static int calculate({
    required int arrowCount,
    required int livesRemaining,
    required int elapsedSeconds,
    required Difficulty difficulty,
    int? timeLimitSeconds,
  }) {
    int score = arrowCount * _basePerArrow + livesRemaining * _lifeBonus;

    if (timeLimitSeconds != null) {
      final remaining = (timeLimitSeconds - elapsedSeconds).clamp(0, timeLimitSeconds);
      score += remaining * _secondBonus;
    }

    final multiplier = switch (difficulty) {
      Difficulty.easy => 1.0,
      Difficulty.medium => 1.5,
      Difficulty.hard => 2.0,
    };

    return (score * multiplier).round();
  }

  /// Convierte una puntuación en estrellas (1–3).
  static int starsFor(int score, {required int maxPossibleScore}) {
    final ratio = score / maxPossibleScore;
    if (ratio >= 0.85) return 3;
    if (ratio >= 0.55) return 2;
    return 1;
  }
}
