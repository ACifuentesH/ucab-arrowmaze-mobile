import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/complete_level_test_api.dart';

void main() {
  group('CompleteLevelUseCase — puntuación y persistencia', () {
    test('should_award_three_stars_when_run_is_perfect', () async {
      final api = await CompleteLevelTestApi()
          .whenLevelIsCompleted(livesRemaining: 3);
      api
        ..thenScoreShouldBe(950) // 5×100 + 3×150
        ..thenStarsShouldBe(3)
        ..thenItShouldBeANewBest();
    });

    test('should_award_fewer_stars_when_lives_are_lost', () async {
      final api = await CompleteLevelTestApi()
          .whenLevelIsCompleted(livesRemaining: 2);
      api
        ..thenScoreShouldBe(800)
        ..thenStarsShouldBe(2);
    });

    test('should_award_one_star_when_run_barely_survives', () async {
      final api = await CompleteLevelTestApi()
          .whenLevelIsCompleted(livesRemaining: 0);
      api
        ..thenScoreShouldBe(500)
        ..thenStarsShouldBe(1);
    });

    test('should_persist_the_score_when_level_is_completed_first_time',
        () async {
      final api = await CompleteLevelTestApi()
          .whenLevelIsCompleted(livesRemaining: 3);
      await api.thenStoredBestShouldBe(950);
    });

    test('should_keep_previous_best_when_new_score_is_lower', () async {
      final api = await CompleteLevelTestApi().givenAPreviousBestOf(900);
      await api.whenLevelIsCompleted(livesRemaining: 0); // 500
      api.thenItShouldNotBeANewBest();
      await api.thenStoredBestShouldBe(900);
    });

    test('should_replace_best_when_new_score_is_higher', () async {
      final api = await CompleteLevelTestApi().givenAPreviousBestOf(400);
      await api.whenLevelIsCompleted(livesRemaining: 3); // 950
      api.thenItShouldBeANewBest();
      await api.thenStoredBestShouldBe(950);
    });

    test('should_update_stars_when_replaying_after_hydration_defaulted_to_one',
        () async {
      final api = await CompleteLevelTestApi()
          .givenHydratedProgressWithDefaultStars(bestScore: 900);
      // Mismo score máximo (950): isNewBest true → actualiza stars a 3.
      await api.whenLevelIsCompleted(livesRemaining: 3);
      api.thenItShouldBeANewBest();
      await api.thenStoredBestShouldBe(950);
      await api.thenStoredStarsShouldBe(3);
    });

    test('should_treat_missing_previous_best_as_zero_when_comparing', () async {
      final api = await CompleteLevelTestApi()
          .givenHydratedProgressWithDefaultStars(bestScore: 0);
      await api.whenLevelIsCompleted(livesRemaining: 2); // 800
      api.thenItShouldBeANewBest();
      await api.thenStoredBestShouldBe(800);
    });
  });
}
