import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_progress_repository.dart';
import 'package:arrow_maze/application/use_cases/progress/hydrate_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';

import '../fakes/fake_player_progress_repository.dart';

class _MockProgressRepository extends Mock implements IProgressRepository {}

/// Testing API: hidratación de progreso remoto → local.
class HydrateProgressTestApi {
  final _MockProgressRepository _progress = _MockProgressRepository();
  final FakePlayerProgressRepository _local = FakePlayerProgressRepository();

  late final HydrateProgressUseCase _useCase = HydrateProgressUseCase(
    sync: SyncProgressUseCase(progress: _progress),
    local: _local,
  );

  Object? _error;

  Future<HydrateProgressTestApi> givenStaleLocalProgress() async {
    await _local.save(
      LevelProgress(
        levelId: 'level_old',
        bestScore: 100,
        bestTimeSeconds: 10,
        starsEarned: 1,
        completedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    return this;
  }

  HydrateProgressTestApi givenRemoteProgressExists() {
    when(() => _progress.getProgress()).thenAnswer(
      (_) async => const PlayerProgressDto(
        userId: 'u-1',
        completedLevels: ['level_1', 'level_2'],
        bestScores: {'level_1': 900, 'level_2': 800},
        currentLevelId: 'level_3',
      ),
    );
    return this;
  }

  HydrateProgressTestApi givenNewUserWithoutProgress() {
    when(() => _progress.getProgress())
        .thenThrow(const NotFoundError('Progress not found'));
    return this;
  }

  HydrateProgressTestApi givenNetworkFails() {
    when(() => _progress.getProgress())
        .thenThrow(const NetworkError('No connection'));
    return this;
  }

  Future<HydrateProgressTestApi> whenHydrating() async {
    try {
      await _useCase.execute();
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<void> thenLocalProgressShouldMatchRemote() async {
    expect(_error, isNull);
    final all = await _local.findAll();
    expect(all, hasLength(2));
    expect(all.map((p) => p.levelId), containsAll(['level_1', 'level_2']));
    expect(await _local.find('level_old'), isNull);

    final level1 = await _local.find('level_1');
    expect(level1!.bestScore, 900);
    expect(level1.starsEarned, 3);

    final level2 = await _local.find('level_2');
    expect(level2!.bestScore, 800);
    expect(level2.starsEarned, 3);
  }

  Future<void> thenLocalProgressShouldBeEmpty() async {
    expect(_error, isNull);
    expect(await _local.findAll(), isEmpty);
  }

  Future<void> thenHydrationShouldSwallowErrorAndKeepLocal() async {
    expect(_error, isNull);
    expect(await _local.find('level_old'), isNotNull);
  }
}
