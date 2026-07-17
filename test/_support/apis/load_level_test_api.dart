import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/restart_level_use_case.dart';
import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

import '../fakes/fake_level_repository.dart';
import '../mothers/level_definition_mother.dart';

/// Testing API: carga y reinicio de niveles vía puerto ILevelRepository (fake).
class LoadLevelTestApi {
  final FakeLevelRepository _repository = FakeLevelRepository();
  final CommandInvoker _invoker = CommandInvoker();
  Board? _board;
  Object? _error;

  LoadLevelTestApi givenARepositoryWithLevel(String levelId) {
    _repository.seed(LevelDefinitionMother.withEscapableArrow(id: levelId));
    return this;
  }

  LoadLevelTestApi givenAnEmptyRepository() => this;

  Future<LoadLevelTestApi> whenLevelIsLoaded(String levelId) async {
    try {
      _board = await LoadLevelUseCase(repository: _repository)
          .execute(LevelId(levelId));
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<LoadLevelTestApi> whenLevelIsRestartedAfterAMove(
      String levelId) async {
    _board = await LoadLevelUseCase(repository: _repository)
        .execute(LevelId(levelId));
    RemoveArrowUseCase(invoker: _invoker).execute(_board!, 'a1');
    _board = await RestartLevelUseCase(
      repository: _repository,
      invoker: _invoker,
    ).execute(LevelId(levelId));
    return this;
  }

  void thenBoardShouldBeReady() {
    expect(_board, isNotNull);
    expect(_error, isNull);
  }

  void thenBoardShouldHaveArrows(int count) =>
      expect(_board!.arrowCount, equals(count));

  void thenRequestedLevelShouldBe(String levelId) =>
      expect(_repository.lastRequestedId, equals(LevelId(levelId)));

  void thenLoadShouldFail() => expect(_error, isNotNull);

  void thenUndoHistoryShouldBeEmpty() => expect(_invoker.canUndo, isFalse);
}
