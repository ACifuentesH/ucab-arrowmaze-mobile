import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/application/use_cases/get_hex_level_selection_use_case.dart';

import '../../_support/fakes/fake_level_catalog_service.dart';
import '../../_support/fakes/fake_player_progress_repository.dart';
import '../../_support/mothers/level_preview_mother.dart';
import '../../_support/mothers/progress_mother.dart';

/// Progresión del MODO HEXAGONAL: misma regla secuencial que la campaña
/// cuadrada, pero sobre el catálogo hex aislado.
void main() {
  Future<List<LevelSelectEntry>> run({
    required List<String> catalog,
    List<String> completed = const [],
  }) async {
    final catalogService = FakeLevelCatalogService();
    for (final id in catalog) {
      catalogService.seed(LevelPreviewMother.asset(id: id));
    }
    final progress = FakePlayerProgressRepository();
    for (final id in completed) {
      await progress.save(ProgressMother.completedLevel(levelId: id));
    }
    return GetHexLevelSelectionUseCase(
      catalog: catalogService,
      progress: progress,
    ).execute();
  }

  LevelStatus statusOf(List<LevelSelectEntry> entries, String id) =>
      entries.singleWhere((e) => e.preview.id == id).status;

  group('GetHexLevelSelectionUseCase — progresión hex', () {
    test('should_lock_hex_2_when_there_is_no_progress', () async {
      final entries = await run(catalog: ['hex_1', 'hex_2']);
      expect(statusOf(entries, 'hex_1'), equals(LevelStatus.unlocked));
      expect(statusOf(entries, 'hex_2'), equals(LevelStatus.locked));
    });

    test('should_unlock_hex_2_when_hex_1_is_completed', () async {
      final entries =
          await run(catalog: ['hex_1', 'hex_2'], completed: ['hex_1']);
      expect(statusOf(entries, 'hex_1'), equals(LevelStatus.completed));
      expect(statusOf(entries, 'hex_2'), equals(LevelStatus.unlocked));
    });

    test('should_mark_both_completed_when_both_have_progress', () async {
      final entries = await run(
        catalog: ['hex_1', 'hex_2'],
        completed: ['hex_1', 'hex_2'],
      );
      expect(statusOf(entries, 'hex_1'), equals(LevelStatus.completed));
      expect(statusOf(entries, 'hex_2'), equals(LevelStatus.completed));
    });
  });
}
