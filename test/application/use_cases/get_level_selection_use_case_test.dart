import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/enums/level_status.dart';

import '../../_support/apis/level_selection_test_api.dart';

void main() {
  group('GetLevelSelectionUseCase — progresión de la campaña', () {
    test('should_unlock_only_the_first_level_when_there_is_no_progress',
        () async {
      final api = await LevelSelectionTestApi()
          .givenACampaignOf(['level_1', 'level_2', 'level_3'])
          .whenSelectionIsRequested();
      api
        ..thenLevelShouldBe('level_1', LevelStatus.unlocked)
        ..thenLevelShouldBe('level_2', LevelStatus.locked)
        ..thenLevelShouldBe('level_3', LevelStatus.locked);
    });

    test('should_unlock_the_next_level_when_the_previous_one_is_completed',
        () async {
      final api = LevelSelectionTestApi()
          .givenACampaignOf(['level_1', 'level_2', 'level_3']);
      await api.givenCompletedLevels(['level_1']);
      await api.whenSelectionIsRequested();
      api
        ..thenLevelShouldBe('level_1', LevelStatus.completed)
        ..thenLevelShouldBe('level_2', LevelStatus.unlocked)
        ..thenLevelShouldBe('level_3', LevelStatus.locked);
    });

    test('should_show_earned_stars_when_a_level_was_completed', () async {
      final api = LevelSelectionTestApi().givenACampaignOf(['level_1']);
      await api.givenCompletedLevels(['level_1'], stars: 2);
      await api.whenSelectionIsRequested();
      api.thenStarsOfLevelShouldBe('level_1', 2);
    });

    test('should_never_lock_generated_levels_when_campaign_is_incomplete',
        () async {
      final api = await LevelSelectionTestApi()
          .givenACampaignOf(['level_1', 'level_2'])
          .givenAGeneratedLevel('generated_1')
          .whenSelectionIsRequested();
      api
        ..thenLevelShouldBe('level_2', LevelStatus.locked)
        ..thenLevelShouldBe('generated_1', LevelStatus.unlocked);
    });

    test('should_preserve_catalog_order_when_listing_entries', () async {
      final api = await LevelSelectionTestApi()
          .givenACampaignOf(['level_1', 'level_2'])
          .givenAGeneratedLevel('generated_1')
          .whenSelectionIsRequested();
      api.thenEntriesShouldBe(['level_1', 'level_2', 'generated_1']);
    });
  });
}
