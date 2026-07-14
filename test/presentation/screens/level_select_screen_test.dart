import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/level_select_screen_test_api.dart';

void main() {
  group('LevelSelectScreen — render', () {
    testWidgets('should_render_lock_icon_when_a_campaign_level_is_locked',
        (tester) async {
      final api = LevelSelectScreenTestApi(tester);
      api
        ..givenACampaignLevel('level_1')
        ..givenACampaignLevel('level_2');
      await api.givenTheLevelSelectScreenIsOpen();

      // level_1 desbloqueado (primero de la campaña), level_2 bloqueado
      // porque level_1 aún no se completó.
      api.thenLockIconsShouldBeShown(count: 1);
    });

    testWidgets('should_render_filled_stars_when_a_level_is_completed',
        (tester) async {
      final api = LevelSelectScreenTestApi(tester);
      api.givenACampaignLevel('level_1');
      await api.givenLevelIsCompleted('level_1', stars: 3);
      await api.givenTheLevelSelectScreenIsOpen();

      api.thenFilledStarsShouldBeShown(count: 3);
    });
  });

  group('LevelSelectScreen — interaction', () {
    testWidgets(
        'should_not_navigate_when_a_locked_level_is_tapped', (tester) async {
      final api = LevelSelectScreenTestApi(tester);
      api
        ..givenACampaignLevel('level_1')
        ..givenACampaignLevel('level_2');
      await api.givenTheLevelSelectScreenIsOpen();

      await api.whenCampaignTileIsTapped(2);

      api.thenTheLevelSelectScreenShouldBeShown();
    });
  });

  group('LevelSelectScreen — navigation', () {
    testWidgets(
        'should_navigate_to_game_screen_when_unlocked_level_is_tapped',
        (tester) async {
      final api = LevelSelectScreenTestApi(tester);
      api.givenACampaignLevel('level_1');
      await api.givenTheLevelSelectScreenIsOpen();

      await api.whenCampaignTileIsTapped(1);

      api.thenTheGameScreenShouldBeShown();
    });
  });
}
