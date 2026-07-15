import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_progress_repository.dart';
import 'package:arrow_maze/application/use_cases/progress/push_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_player_progress_repository.dart';
import '../mothers/progress_mother.dart';

class _MockProgressRepository extends Mock implements IProgressRepository {}

/// Testing API: push de progreso tras completar un nivel.
class PushProgressTestApi {
  PushProgressTestApi() {
    registerFallbackValue(ProgressMother.minimalUpdate());
  }

  final _MockProgressRepository _progress = _MockProgressRepository();
  final FakePlayerProgressRepository _local = FakePlayerProgressRepository();
  final FakeLocalStorage _storage = FakeLocalStorage();

  late final PushProgressUseCase _useCase = PushProgressUseCase(
    sync: SyncProgressUseCase(progress: _progress),
    local: _local,
    storage: _storage,
  );

  Object? _error;

  Future<PushProgressTestApi> givenLocalProgressExists() async {
    await _local.save(ProgressMother.completedLevel(bestScore: 900));
    return this;
  }

  PushProgressTestApi givenAnAuthenticatedSession() {
    _storage.token = 'jwt-token';
    return this;
  }

  PushProgressTestApi givenNoSession() {
    _storage.token = null;
    return this;
  }

  PushProgressTestApi givenTheServerAcceptsUpdates() {
    when(() => _progress.putProgress(any())).thenAnswer(
      (_) async => const PlayerProgressDto(
        userId: 'u-1',
        completedLevels: ['level_1'],
        bestScores: {'level_1': 950},
        currentLevelId: 'level_2',
      ),
    );
    return this;
  }

  PushProgressTestApi givenTheServerFails() {
    when(() => _progress.putProgress(any()))
        .thenThrow(const ServerError('Internal server error'));
    return this;
  }

  PushProgressTestApi givenNetworkFails() {
    when(() => _progress.putProgress(any()))
        .thenThrow(const NetworkError('No connection'));
    return this;
  }

  Future<PushProgressTestApi> whenLevelCompletionIsPushed({
    int lastScore = 950,
    int lastMoves = 8,
    int lastTimeSeconds = 45,
  }) async {
    try {
      await _useCase.execute(
        lastLevelId: 'level_1',
        lastScore: lastScore,
        lastMoves: lastMoves,
        lastTimeSeconds: lastTimeSeconds,
        currentLevelId: 'level_2',
      );
    } catch (e) {
      _error = e;
    }
    return this;
  }

  void thenPushShouldIncludeLeaderboardFields() {
    expect(_error, isNull);
    final captured =
        verify(() => _progress.putProgress(captureAny())).captured.single
            as ProgressUpdate;
    expect(captured.lastLevelId, 'level_1');
    expect(captured.lastScore, 950);
    expect(captured.lastMoves, 8);
    expect(captured.lastTimeSeconds, 45);
    expect(captured.completedLevels, contains('level_1'));
    expect(captured.bestScores['level_1'], isNotNull);
    expect(captured.currentLevelId, 'level_2');
  }

  void thenNoRequestShouldBeSent() {
    expect(_error, isNull);
    verifyNever(() => _progress.putProgress(any()));
  }

  void thenErrorShouldBeSwallowed() {
    expect(_error, isNull);
  }
}
