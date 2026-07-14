import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/home_screen_test_api.dart';

void main() {
  group('HomeScreen — render', () {
    testWidgets('should_render_the_home_screen_when_opened', (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();

      api.thenTheHomeScreenShouldBeShown();
    });

    testWidgets('should_show_title_and_play_button_when_opened',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();

      api.thenTheTitleAndPlayButtonShouldBeShown();
    });
  });

  group('HomeScreen — navigation', () {
    testWidgets('should_navigate_to_settings_screen_when_settings_is_tapped',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();

      await api.whenTheSettingsButtonIsTapped();

      api.thenTheSettingsScreenShouldBeShown();
    });

    testWidgets('should_navigate_to_level_select_when_play_is_tapped',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();

      await api.whenThePlayButtonIsTapped();

      api.thenTheLevelSelectScreenShouldBeShown();
    });
  });
}
