import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';

import '../mothers/progress_mother.dart';

class MockApiClient extends Mock implements IApiClient {}

/// Testing API: sincronización de progreso contra el puerto IApiClient.
/// Aquí SÍ usamos mock (mocktail): la llamada al servicio externo ES el
/// comportamiento observable (docs/testing-architecture.md §0.5).
class SyncProgressTestApi {
  SyncProgressTestApi() {
    registerFallbackValue(ProgressMother.minimalUpdate());
  }

  final MockApiClient _api = MockApiClient();
  late final SyncProgressUseCase _useCase = SyncProgressUseCase(api: _api);
  PlayerProgressDto? _pulled;
  Object? _error;

  SyncProgressTestApi givenARemoteProgressExists() {
    when(() => _api.getProgress()).thenAnswer(
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
    when(() => _api.getProgress())
        .thenThrow(const NotFoundError('Progress not found'));
    return this;
  }

  SyncProgressTestApi givenTheServerAcceptsUpdates() {
    when(() => _api.putProgress(any())).thenAnswer(
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
        verify(() => _api.putProgress(captureAny())).captured.single
            as ProgressUpdate;
    expect(captured.lastLevelId, isNotNull);
    expect(captured.lastScore, isNotNull);
  }
}
