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

    testWidgets('should_hide_the_account_button_when_logged_out',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();

      api.thenTheAccountButtonShouldNotBeShown();
    });

    testWidgets('should_show_the_account_button_when_authenticated',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpenWhileAuthenticated();

      api.thenTheAccountButtonShouldBeShown();
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

    testWidgets(
        'should_navigate_directly_to_level_select_when_play_is_tapped_while_authenticated',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpenWhileAuthenticated();

      await api.whenThePlayButtonIsTapped();

      api.thenTheLevelSelectScreenShouldBeShown();
      api.thenTheLoginPromptShouldNotBeShown();
    });
  });

  group('HomeScreen — login prompt at game start', () {
    testWidgets('should_show_login_prompt_when_play_is_tapped_while_logged_out',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();

      await api.whenThePlayButtonIsTapped();

      api.thenTheLoginPromptShouldBeShown();
    });

    testWidgets(
        'should_navigate_to_level_select_when_continue_as_guest_is_tapped',
        (tester) async {
      final api = HomeScreenTestApi(tester);
      await api.givenTheHomeScreenIsOpen();
      await api.whenThePlayButtonIsTapped();

      await api.whenTheContinueAsGuestOptionIsTapped();

      api.thenTheLevelSelectScreenShouldBeShown();
    });
  });
}
