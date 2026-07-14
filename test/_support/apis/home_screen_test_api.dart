import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/home_screen.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';

import '../fakes/fake_audio_service.dart';

/// Testing API (nivel medio) para las pruebas de navegación de la Home.
/// Oculta el `ProviderScope`, el fake de audio y la localización.
class HomeScreenTestApi {
  final WidgetTester _tester;
  final FakeAudioService _audio = FakeAudioService();

  HomeScreenTestApi(this._tester);

  Future<HomeScreenTestApi> givenTheHomeScreenIsOpen() async {
    await _tester.pumpWidget(
      ProviderScope(
        overrides: [audioServiceProvider.overrideWithValue(_audio)],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );
    await _tester.pumpAndSettle();
    return this;
  }

  Future<HomeScreenTestApi> whenTheSettingsButtonIsTapped() async {
    await _tester.tap(find.byKey(HomeScreen.settingsButtonKey));
    await _tester.pumpAndSettle();
    return this;
  }

  void thenTheSettingsScreenShouldBeShown() =>
      expect(find.byType(SettingsScreen), findsOneWidget);

  void thenTheHomeScreenShouldBeShown() =>
      expect(find.byType(HomeScreen), findsOneWidget);
}
