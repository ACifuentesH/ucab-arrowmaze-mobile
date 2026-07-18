import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/application/use_cases/get_hex_level_selection_use_case.dart';
import 'package:arrow_maze/presentation/view_models/hex_level_select_view_model.dart';

import '../../_support/fakes/fake_level_catalog_service.dart';
import '../../_support/fakes/fake_player_progress_repository.dart';
import '../../_support/mothers/level_preview_mother.dart';
import '../../_support/mothers/progress_mother.dart';

void main() {
  HexLevelSelectViewModel build({List<String> completed = const []}) {
    final catalog = FakeLevelCatalogService()
      ..seed(LevelPreviewMother.asset(id: 'hex_1'))
      ..seed(LevelPreviewMother.asset(id: 'hex_2'));
    final progress = FakePlayerProgressRepository();
    for (final id in completed) {
      progress.save(ProgressMother.completedLevel(levelId: id));
    }
    return HexLevelSelectViewModel(
      getSelection: GetHexLevelSelectionUseCase(
        catalog: catalog,
        progress: progress,
      ),
    );
  }

  group('HexLevelSelectViewModel', () {
    test('should_expose_hex_entries_with_progression_when_load_is_called',
        () async {
      final vm = build();

      await vm.load();

      expect(vm.state.isLoading, isFalse);
      expect(vm.state.errorMessage, isNull);
      expect(vm.state.entries.map((e) => e.preview.id).toList(),
          equals(['hex_1', 'hex_2']));
      expect(vm.state.entries.first.status, equals(LevelStatus.unlocked));
      expect(vm.state.entries.last.status, equals(LevelStatus.locked));
    });
  });
}
