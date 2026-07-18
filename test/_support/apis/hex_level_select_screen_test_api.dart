import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';
import 'package:arrow_maze/presentation/views/screens/hex_level_select_screen.dart';

import '../fakes/fake_audio_service.dart';
import '../fakes/fake_level_catalog_service.dart';
import '../fakes/fake_level_repository.dart';
import '../fakes/fake_player_progress_repository.dart';
import '../fakes/fake_time_service.dart';
import '../mothers/level_definition_mother.dart';
import '../mothers/level_preview_mother.dart';
import '../mothers/progress_mother.dart';

/// Testing API (nivel medio) para [HexLevelSelectScreen]: oculta el
/// `ProviderScope`, los fakes del catálogo HEX/progreso/repositorio/audio/reloj
/// y la localización tras una interfaz encadenable given/when/then. Espejo de
/// `LevelSelectScreenTestApi` pero sobre `hexLevelCatalogServiceProvider`.
class HexLevelSelectScreenTestApi {
  final WidgetTester _tester;
  final FakeAudioService _audio = FakeAudioService();
  final FakeLevelCatalogService _hexCatalog = FakeLevelCatalogService();
  final FakePlayerProgressRepository _progress =
      FakePlayerProgressRepository();
  final FakeLevelRepository _levelRepository = FakeLevelRepository();
  final FakeTimeService _time = FakeTimeService();

  HexLevelSelectScreenTestApi(this._tester);

  // ── Given ──────────────────────────────────────────────────────────────────

  /// Nivel hex del catálogo; también se siembra en el repositorio que carga el
  /// tablero jugable (mismo id) para que la navegación a GameScreen funcione.
  HexLevelSelectScreenTestApi givenAHexLevel(String id) {
    _hexCatalog.seed(LevelPreviewMother.asset(id: id));
    _levelRepository.seed(LevelDefinitionMother.withEscapableArrow(id: id));
    return this;
  }

  Future<HexLevelSelectScreenTestApi> givenHexLevelIsCompleted(
    String id, {
    int stars = 3,
  }) async {
    await _progress
        .save(ProgressMother.completedLevel(levelId: id, stars: stars));
    return this;
  }

  Future<HexLevelSelectScreenTestApi> givenTheHexScreenIsOpen() async {
    // Tocar un tile jugable navega a GameScreen, que observa el
    // gameViewModelProvider real (incluye IProgressSyncCoordinator) → necesita
    // sharedPreferencesProvider para tokenStorage/apiClient. Sin token guardado
    // no se dispara ninguna llamada de red.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(_audio),
          hexLevelCatalogServiceProvider.overrideWithValue(_hexCatalog),
          playerProgressRepositoryProvider.overrideWithValue(_progress),
          levelRepositoryProvider.overrideWithValue(_levelRepository),
          timeServiceProvider.overrideWithValue(_time),
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HexLevelSelectScreen(),
        ),
      ),
    );
    await _tester.pumpAndSettle();
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<HexLevelSelectScreenTestApi> whenHexTileIsTapped(int number) async {
    final finder = find.byKey(HexLevelSelectScreen.hexTileKey(number));
    // Los nodos bajos del sendero pueden quedar fuera del viewport de test.
    await _tester.ensureVisible(finder);
    await _tester.pumpAndSettle();
    await _tester.tap(finder, warnIfMissed: false);
    await _tester.pumpAndSettle();
    return this;
  }

  Future<HexLevelSelectScreenTestApi> whenComingSoonNodeIsTapped() async {
    final finder = find.byKey(HexLevelSelectScreen.comingSoonTileKey);
    await _tester.ensureVisible(finder);
    await _tester.pumpAndSettle();
    await _tester.tap(finder, warnIfMissed: false);
    await _tester.pumpAndSettle();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenTheGameScreenShouldBeShown() =>
      expect(find.byType(GameScreen), findsOneWidget);

  void thenTheHexScreenShouldBeShown() =>
      expect(find.byType(HexLevelSelectScreen), findsOneWidget);

  void thenLockIconsShouldBeShown({required int count}) =>
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(count));

  void thenHexTileShouldExist(int number) => expect(
        find.byKey(HexLevelSelectScreen.hexTileKey(number)),
        findsOneWidget,
      );

  /// El nodo teaser "en construcción" al final del sendero.
  void thenTheComingSoonNodeShouldBeShown() {
    expect(find.byKey(HexLevelSelectScreen.comingSoonTileKey), findsOneWidget);
    expect(find.byIcon(Icons.construction), findsOneWidget);
  }
}
