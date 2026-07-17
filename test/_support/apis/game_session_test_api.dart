import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/dtos/playable_level.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/use_cases/complete_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/restart_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/undo_move_use_case.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';

import '../fakes/fake_audio_service.dart';
import '../fakes/fake_level_repository.dart';
import '../fakes/fake_player_progress_repository.dart';
import '../fakes/fake_time_service.dart';
import '../mothers/level_definition_mother.dart';

/// Testing API: sesión de juego completa a través del GameViewModel
/// (campaña, completar nivel, puntuación y siguiente nivel).
class GameSessionTestApi {
  final FakeLevelRepository _levels = FakeLevelRepository();
  final FakePlayerProgressRepository _progress =
      FakePlayerProgressRepository();
  final CommandInvoker _invoker = CommandInvoker();
  final FakeTimeService _time = FakeTimeService();

  late final GameViewModel _viewModel = GameViewModel(
    loadLevel: LoadLevelUseCase(repository: _levels),
    removeArrow: RemoveArrowUseCase(invoker: _invoker),
    restart: RestartLevelUseCase(repository: _levels, invoker: _invoker),
    undo: UndoMoveUseCase(invoker: _invoker),
    completeLevel: CompleteLevelUseCase(repository: _progress),
    timeService: _time,
    audioService: FakeAudioService(),
  );

  List<String> _campaign = const [];

  // ── Given ──────────────────────────────────────────────────────────────────

  /// Cada nivel tiene una sola flecha 'a1' liberable (se completa en un tap).
  GameSessionTestApi givenACampaignWithLevels(List<String> ids) {
    for (final id in ids) {
      _levels.seed(LevelDefinitionMother.withEscapableArrow(id: id));
    }
    _campaign = ids;
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<GameSessionTestApi> whenCampaignStarts() async {
    await _viewModel.startCampaign([
      for (final id in _campaign)
        PlayableLevel(id: id, difficulty: Difficulty.easy),
    ]);
    return this;
  }

  Future<GameSessionTestApi> whenTheOnlyArrowIsTapped() async {
    _viewModel.tapArrow('a1');
    await pumpEventQueue(); // deja correr la puntuación asíncrona
    return this;
  }

  Future<GameSessionTestApi> whenNextLevelIsRequested() async {
    await _viewModel.playNext();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenLevelResultShouldBeAvailable() {
    expect(_viewModel.state.lastResult, isNotNull);
    expect(_viewModel.state.lastResult!.score, greaterThan(0));
  }

  Future<void> thenProgressShouldBeSavedFor(String levelId) async =>
      expect(await _progress.find(levelId), isNotNull);

  void thenNextLevelShouldBeOffered() =>
      expect(_viewModel.state.hasNextLevel, isTrue);

  void thenNoNextLevelShouldBeOffered() =>
      expect(_viewModel.state.hasNextLevel, isFalse);

  void thenCurrentLevelShouldBe(String levelId) =>
      expect(_viewModel.state.currentLevelId?.value, equals(levelId));

  void thenResultShouldBeClearedForTheNewLevel() =>
      expect(_viewModel.state.lastResult, isNull);

  void dispose() {
    _viewModel.dispose();
    _time.dispose();
  }
}
