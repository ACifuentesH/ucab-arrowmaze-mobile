import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/game_session_test_api.dart';

void main() {
  group('GameViewModel — campaña y puntuación', () {
    late GameSessionTestApi api;

    setUp(() => api = GameSessionTestApi());
    tearDown(() => api.dispose());

    test('should_expose_the_level_result_when_board_is_cleared', () async {
      api.givenACampaignWithLevels(['level_1', 'level_2']);
      await api.whenCampaignStarts();
      await api.whenTheOnlyArrowIsTapped();
      api.thenLevelResultShouldBeAvailable();
    });

    test('should_save_local_progress_when_level_is_completed', () async {
      api.givenACampaignWithLevels(['level_1']);
      await api.whenCampaignStarts();
      await api.whenTheOnlyArrowIsTapped();
      await api.thenProgressShouldBeSavedFor('level_1');
    });

    test('should_offer_the_next_level_when_campaign_has_more', () async {
      api.givenACampaignWithLevels(['level_1', 'level_2']);
      await api.whenCampaignStarts();
      await api.whenTheOnlyArrowIsTapped();
      api.thenNextLevelShouldBeOffered();
    });

    test('should_not_offer_next_level_when_campaign_ends', () async {
      api.givenACampaignWithLevels(['level_1']);
      await api.whenCampaignStarts();
      await api.whenTheOnlyArrowIsTapped();
      api.thenNoNextLevelShouldBeOffered();
    });

    test('should_load_the_next_level_when_requested_after_victory', () async {
      api.givenACampaignWithLevels(['level_1', 'level_2']);
      await api.whenCampaignStarts();
      await api.whenTheOnlyArrowIsTapped();
      await api.whenNextLevelIsRequested();
      api
        ..thenCurrentLevelShouldBe('level_2')
        ..thenResultShouldBeClearedForTheNewLevel();
    });
  });
}
