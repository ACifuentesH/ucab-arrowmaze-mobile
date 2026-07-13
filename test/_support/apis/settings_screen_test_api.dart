import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_state.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';

import '../fakes/fake_audio_service.dart';

/// Testing API (nivel medio): oculta el fake de audio, el `ProviderScope` y la
/// localización tras una interfaz encadenable given/when/then. Los `test(...)`
/// hablan solo el lenguaje de negocio de los ajustes.
class SettingsScreenTestApi {
  final WidgetTester _tester;
  final FakeAudioService _audio = FakeAudioService();
  late final ProviderContainer _container;

  SettingsScreenTestApi(this._tester);

  // ── Given ──────────────────────────────────────────────────────────────────

  Future<SettingsScreenTestApi> givenTheSettingsScreenIsOpen() async {
    _container = ProviderContainer(
      overrides: [audioServiceProvider.overrideWithValue(_audio)],
    );
    await _tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: const _LocalizedSettingsHarness(),
      ),
    );
    await _tester.pumpAndSettle();
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<SettingsScreenTestApi> whenTheMuteSwitchIsTapped() async {
    await _tester.tap(find.byKey(SettingsScreen.muteSwitchKey));
    await _tester.pumpAndSettle();
    return this;
  }

  Future<SettingsScreenTestApi> whenEnglishIsSelected() async {
    await _tester.tap(find.byKey(SettingsScreen.englishOptionKey));
    await _tester.pumpAndSettle();
    return this;
  }

  Future<SettingsScreenTestApi> whenSpanishIsSelected() async {
    await _tester.tap(find.byKey(SettingsScreen.spanishOptionKey));
    await _tester.pumpAndSettle();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  SettingsState get _state => _container.read(settingsViewModelProvider);

  void thenSoundShouldBeMuted() {
    expect(_state.isMuted, isTrue);
    expect(_audio.isMuted, isTrue);
  }

  void thenSoundShouldNotBeMuted() {
    expect(_state.isMuted, isFalse);
    expect(_audio.isMuted, isFalse);
  }

  void thenActiveLanguageShouldBe(String languageCode) =>
      expect(_state.locale.languageCode, equals(languageCode));

  void thenVisibleTextShouldInclude(String text) =>
      expect(find.text(text), findsWidgets);

  void dispose() => _container.dispose();
}

/// Envuelve la `SettingsScreen` en una `MaterialApp` que observa el idioma del
/// `SettingsViewModel` — reproduce el cableado real de `main.dart` para que un
/// cambio de idioma relocalice de verdad los textos visibles.
class _LocalizedSettingsHarness extends ConsumerWidget {
  const _LocalizedSettingsHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(
      settingsViewModelProvider.select((SettingsState s) => s.locale),
    );
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );
  }
}
