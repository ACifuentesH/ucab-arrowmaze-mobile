import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/use_cases/save_progress_use_case.dart';

import '../fakes/fake_player_progress_repository.dart';
import '../mothers/progress_mother.dart';

/// Testing API: guardado local de progreso vía IPlayerProgressRepository (fake).
class SaveProgressTestApi {
  final FakePlayerProgressRepository _repository =
      FakePlayerProgressRepository();

  Future<SaveProgressTestApi> whenACompletedLevelIsSaved({
    String levelId = 'level_1',
    int bestScore = 900,
  }) async {
    await SaveProgressUseCase(repository: _repository).execute(
      ProgressMother.completedLevel(levelId: levelId, bestScore: bestScore),
    );
    return this;
  }

  Future<void> thenProgressShouldBeStored(
    String levelId, {
    required int bestScore,
  }) async {
    final stored = await _repository.find(levelId);
    expect(stored, isNotNull);
    expect(stored!.bestScore, equals(bestScore));
  }

  Future<void> thenStoredLevelsShouldBe(int count) async =>
      expect(await _repository.findAll(), hasLength(count));
}
