import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_progress_repository.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';

import '../mothers/progress_mother.dart';

class MockProgressRepository extends Mock implements IProgressRepository {}

/// Testing API: sincronización de progreso contra [IProgressRepository].
class SyncProgressTestApi {
  SyncProgressTestApi() {
    registerFallbackValue(ProgressMother.minimalUpdate());
  }

  final MockProgressRepository _progress = MockProgressRepository();
  late final SyncProgressUseCase _useCase =
      SyncProgressUseCase(progress: _progress);
  PlayerProgressDto? _pulled;
  Object? _error;

  SyncProgressTestApi givenARemoteProgressExists() {
    when(() => _progress.getProgress()).thenAnswer(
      (_) async => const PlayerProgressDto(
        userId: 'u-1',
        completedLevels: ['level_1'],
        bestScores: {'level_1': 900},
        currentLevelId: 'level_2',
      ),
    );
    return this;
  }

  SyncProgressTestApi givenANewUserWithoutProgress() {
    when(() => _progress.getProgress())
        .thenThrow(const NotFoundError('Progress not found'));
    return this;
  }

  SyncProgressTestApi givenTheServerAcceptsUpdates() {
    when(() => _progress.putProgress(any())).thenAnswer(
      (invocation) async => const PlayerProgressDto(
        userId: 'u-1',
        completedLevels: ['level_1'],
        bestScores: {'level_1': 950},
        currentLevelId: 'level_2',
      ),
    );
    return this;
  }

  Future<SyncProgressTestApi> whenProgressIsPulled() async {
    try {
      _pulled = await _useCase.pull();
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<SyncProgressTestApi> whenACompletedLevelIsPushed() async {
    await _useCase.push(ProgressMother.levelCompletedUpdate());
    return this;
  }

  void thenProgressShouldBeAvailable() {
    expect(_error, isNull);
    expect(_pulled, isNotNull);
  }

  void thenResultShouldBeNoProgressYet() {
    expect(_error, isNull, reason: '404 debe tratarse como usuario nuevo');
    expect(_pulled, isNull);
  }

  void thenUpdateShouldReachTheServerWithLeaderboardFields() {
    final captured =
        verify(() => _progress.putProgress(captureAny())).captured.single
            as ProgressUpdate;
    expect(captured.lastLevelId, isNotNull);
    expect(captured.lastScore, isNotNull);
  }
}
