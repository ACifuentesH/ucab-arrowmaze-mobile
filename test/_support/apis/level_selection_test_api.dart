import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/application/use_cases/get_level_selection_use_case.dart';

import '../fakes/fake_level_catalog_service.dart';
import '../fakes/fake_player_progress_repository.dart';
import '../mothers/level_preview_mother.dart';
import '../mothers/progress_mother.dart';

/// Testing API: progresión de la campaña (bloqueado/desbloqueado/completado).
class LevelSelectionTestApi {
  final FakeLevelCatalogService _catalog = FakeLevelCatalogService();
  final FakePlayerProgressRepository _progress =
      FakePlayerProgressRepository();
  List<LevelSelectEntry>? _entries;

  LevelSelectionTestApi givenACampaignOf(List<String> ids) {
    for (final id in ids) {
      _catalog.seed(LevelPreviewMother.asset(id: id));
    }
    return this;
  }

  LevelSelectionTestApi givenAGeneratedLevel(String id) {
    _catalog.seed(LevelPreviewMother.generated(id: id));
    return this;
  }

  Future<LevelSelectionTestApi> givenCompletedLevels(
    List<String> ids, {
    int stars = 3,
  }) async {
    for (final id in ids) {
      await _progress
          .save(ProgressMother.completedLevel(levelId: id, stars: stars));
    }
    return this;
  }

  Future<LevelSelectionTestApi> whenSelectionIsRequested() async {
    _entries = await GetLevelSelectionUseCase(
      catalog: _catalog,
      progress: _progress,
    ).execute();
    return this;
  }

  LevelSelectEntry _entry(String id) =>
      _entries!.singleWhere((e) => e.preview.id == id);

  void thenLevelShouldBe(String id, LevelStatus status) =>
      expect(_entry(id).status, equals(status),
          reason: 'estado de $id');

  void thenStarsOfLevelShouldBe(String id, int stars) =>
      expect(_entry(id).stars, equals(stars));

  void thenEntriesShouldBe(List<String> ids) =>
      expect(_entries!.map((e) => e.preview.id).toList(), equals(ids));
}
