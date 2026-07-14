import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';

import '../fakes/fake_audio_service.dart';
import '../fakes/fake_level_catalog_service.dart';
import '../fakes/fake_level_repository.dart';
import '../fakes/fake_player_progress_repository.dart';
import '../fakes/fake_time_service.dart';
import '../mothers/level_definition_mother.dart';
import '../mothers/level_preview_mother.dart';
import '../mothers/progress_mother.dart';

/// Testing API (nivel medio) para LevelSelectScreen: oculta el
/// `ProviderScope`, los fakes de catálogo/progreso/repositorio/audio/reloj y
/// la localización tras una interfaz encadenable given/when/then.
class LevelSelectScreenTestApi {
  final WidgetTester _tester;
  final FakeAudioService _audio = FakeAudioService();
  final FakeLevelCatalogService _catalog = FakeLevelCatalogService();
  final FakePlayerProgressRepository _progress =
      FakePlayerProgressRepository();
  final FakeLevelRepository _levelRepository = FakeLevelRepository();
  final FakeTimeService _time = FakeTimeService();

  LevelSelectScreenTestApi(this._tester);

  // ── Given ──────────────────────────────────────────────────────────────────

  /// Nivel de campaña; también se siembra en el repositorio que carga el
  /// tablero jugable (mismo id) para que la navegación a GameScreen funcione.
  LevelSelectScreenTestApi givenACampaignLevel(String id) {
    _catalog.seed(LevelPreviewMother.asset(id: id));
    _levelRepository.seed(LevelDefinitionMother.withEscapableArrow(id: id));
    return this;
  }

  Future<LevelSelectScreenTestApi> givenLevelIsCompleted(
    String id, {
    int stars = 3,
  }) async {
    await _progress
        .save(ProgressMother.completedLevel(levelId: id, stars: stars));
    return this;
  }

  Future<LevelSelectScreenTestApi> givenTheLevelSelectScreenIsOpen() async {
    await _tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(_audio),
          levelCatalogServiceProvider.overrideWithValue(_catalog),
          playerProgressRepositoryProvider.overrideWithValue(_progress),
          levelRepositoryProvider.overrideWithValue(_levelRepository),
          timeServiceProvider.overrideWithValue(_time),
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LevelSelectScreen(),
        ),
      ),
    );
    await _tester.pumpAndSettle();
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<LevelSelectScreenTestApi> whenCampaignTileIsTapped(int number) async {
    await _tester.tap(find.byKey(LevelSelectScreen.campaignTileKey(number)));
    await _tester.pumpAndSettle();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenTheGameScreenShouldBeShown() =>
      expect(find.byType(GameScreen), findsOneWidget);

  void thenTheLevelSelectScreenShouldBeShown() =>
      expect(find.byType(LevelSelectScreen), findsOneWidget);

  void thenLockIconsShouldBeShown({required int count}) =>
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(count));

  void thenFilledStarsShouldBeShown({required int count}) =>
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(count));
}
