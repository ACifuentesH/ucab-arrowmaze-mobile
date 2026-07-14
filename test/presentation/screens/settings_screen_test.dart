import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/settings_screen_test_api.dart';

void main() {
  group('SettingsScreen — mute toggle', () {
    testWidgets('should_toggle_mute_when_switch_is_tapped', (tester) async {
      final api = SettingsScreenTestApi(tester);
      await api.givenTheSettingsScreenIsOpen();

      await api.whenTheMuteSwitchIsTapped();

      api.thenSoundShouldBeMuted();
      api.dispose();
    });

    testWidgets('should_unmute_when_switch_is_tapped_twice', (tester) async {
      final api = SettingsScreenTestApi(tester);
      await api.givenTheSettingsScreenIsOpen();

      await api.whenTheMuteSwitchIsTapped();
      await api.whenTheMuteSwitchIsTapped();

      api.thenSoundShouldNotBeMuted();
      api.dispose();
    });
  });

  group('SettingsScreen — language selector', () {
    testWidgets('should_change_locale_when_language_is_selected',
        (tester) async {
      final api = SettingsScreenTestApi(tester);
      await api.givenTheSettingsScreenIsOpen();

      await api.whenEnglishIsSelected();

      api.thenActiveLanguageShouldBe('en');
      api.dispose();
    });

    testWidgets('should_relocalize_visible_text_when_language_is_selected',
        (tester) async {
      final api = SettingsScreenTestApi(tester);
      await api.givenTheSettingsScreenIsOpen();

      // Idioma inicial: español → título "Ajustes".
      api.thenVisibleTextShouldInclude('Ajustes');

      await api.whenEnglishIsSelected();

      // Tras cambiar a inglés, los textos visibles cambian.
      api.thenVisibleTextShouldInclude('Settings');
      api.dispose();
    });

    testWidgets('should_switch_back_to_spanish_when_spanish_is_selected',
        (tester) async {
      final api = SettingsScreenTestApi(tester);
      await api.givenTheSettingsScreenIsOpen();

      await api.whenEnglishIsSelected();
      await api.whenSpanishIsSelected();

      api.thenActiveLanguageShouldBe('es');
      api.dispose();
    });
  });
}
