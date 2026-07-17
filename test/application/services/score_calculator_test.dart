import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/services/score_calculator.dart';

void main() {
  group('ScoreCalculator', () {
    test('should_sum_arrow_and_life_bonuses_when_there_is_no_time_limit', () {
      // Arrange / Act
      final score = ScoreCalculator.calculate(
        arrowCount: 3,
        livesRemaining: 2,
        elapsedSeconds: 120,
        difficulty: Difficulty.easy,
      );
      // Assert — 3×100 + 2×150 = 600, sin bonus de tiempo.
      expect(score, equals(600));
    });

    test('should_add_time_bonus_when_seconds_remain_under_the_limit', () {
      final score = ScoreCalculator.calculate(
        arrowCount: 1,
        livesRemaining: 0,
        elapsedSeconds: 20,
        timeLimitSeconds: 60,
        difficulty: Difficulty.easy,
      );
      // 100 + (60-20)×10 = 500.
      expect(score, equals(500));
    });

    test('should_grant_no_time_bonus_when_the_limit_was_exceeded', () {
      final score = ScoreCalculator.calculate(
        arrowCount: 1,
        livesRemaining: 0,
        elapsedSeconds: 90,
        timeLimitSeconds: 60,
        difficulty: Difficulty.easy,
      );
      expect(score, equals(100));
    });

    test('should_multiply_the_score_when_difficulty_increases', () {
      int at(Difficulty d) => ScoreCalculator.calculate(
            arrowCount: 1,
            livesRemaining: 0,
            elapsedSeconds: 0,
            difficulty: d,
          );
      expect(at(Difficulty.easy), equals(100));
      expect(at(Difficulty.medium), equals(150));
      expect(at(Difficulty.hard), equals(200));
    });

    test('should_award_three_stars_when_score_is_near_the_maximum', () {
      expect(ScoreCalculator.starsFor(90, maxPossibleScore: 100), equals(3));
    });

    test('should_award_two_stars_when_score_is_above_half_the_maximum', () {
      expect(ScoreCalculator.starsFor(60, maxPossibleScore: 100), equals(2));
    });

    test('should_award_one_star_when_score_is_low', () {
      expect(ScoreCalculator.starsFor(30, maxPossibleScore: 100), equals(1));
    });
  });
}
