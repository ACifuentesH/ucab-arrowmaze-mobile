import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/home_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';

import '../fakes/fake_audio_service.dart';
import '../fakes/fake_level_catalog_service.dart';
import '../fakes/fake_player_progress_repository.dart';

/// Testing API (nivel medio) para las pruebas de render y navegación de la Home.
/// Oculta el `ProviderScope`, los fakes (audio, catálogo, progreso) y la
/// localización tras una interfaz encadenable given/when/then. Los `test(...)`
/// hablan solo el lenguaje de negocio de la pantalla de inicio.
class HomeScreenTestApi {
  final WidgetTester _tester;
  final FakeAudioService _audio = FakeAudioService();
  final FakeLevelCatalogService _catalog = FakeLevelCatalogService();
  final FakePlayerProgressRepository _progress = FakePlayerProgressRepository();

  HomeScreenTestApi(this._tester);

  Future<HomeScreenTestApi> givenTheHomeScreenIsOpen() async {
    await _tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(_audio),
          // La pantalla de selección (destino de "JUGAR") carga el catálogo al
          // abrirse; con catálogo vacío se pinta sin depender de assets/SharedPrefs.
          levelCatalogServiceProvider.overrideWithValue(_catalog),
          playerProgressRepositoryProvider.overrideWithValue(_progress),
        ],
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

  Future<HomeScreenTestApi> whenThePlayButtonIsTapped() async {
    await _tester.tap(find.byKey(HomeScreen.playButtonKey));
    await _tester.pumpAndSettle();
    return this;
  }

  void thenTheSettingsScreenShouldBeShown() =>
      expect(find.byType(SettingsScreen), findsOneWidget);

  void thenTheLevelSelectScreenShouldBeShown() =>
      expect(find.byType(LevelSelectScreen), findsOneWidget);

  void thenTheHomeScreenShouldBeShown() =>
      expect(find.byType(HomeScreen), findsOneWidget);

  void thenTheTitleAndPlayButtonShouldBeShown() {
    expect(find.text('Arrow\nEscape'), findsOneWidget);
    expect(find.text('JUGAR'), findsOneWidget);
  }
}
