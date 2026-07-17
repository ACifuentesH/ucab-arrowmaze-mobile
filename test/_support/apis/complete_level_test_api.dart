import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/dtos/level_result.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/use_cases/complete_level_use_case.dart';

import '../fakes/fake_player_progress_repository.dart';
import '../mothers/progress_mother.dart';

/// Testing API: puntuación y persistencia al completar un nivel.
class CompleteLevelTestApi {
  static const String _levelId = 'level_1';

  final FakePlayerProgressRepository _repository =
      FakePlayerProgressRepository();
  late final CompleteLevelUseCase _useCase =
      CompleteLevelUseCase(repository: _repository);
  LevelResult? _result;

  Future<CompleteLevelTestApi> givenAPreviousBestOf(int score) async {
    await _repository.save(
      ProgressMother.completedLevel(levelId: _levelId, bestScore: score),
    );
    return this;
  }

  /// Nivel de 5 flechas y 3 vidas iniciales, sin límite de tiempo:
  /// puntuación máxima teórica = 5×100 + 3×150 = 950 (easy).
  Future<CompleteLevelTestApi> whenLevelIsCompleted({
    int livesRemaining = 3,
    int elapsedSeconds = 30,
    int? timeLimitSeconds,
    Difficulty difficulty = Difficulty.easy,
  }) async {
    _result = await _useCase.execute(
      levelId: _levelId,
      difficulty: difficulty,
      initialArrowCount: 5,
      initialLives: 3,
      livesRemaining: livesRemaining,
      elapsedSeconds: elapsedSeconds,
      timeLimitSeconds: timeLimitSeconds,
    );
    return this;
  }

  void thenScoreShouldBe(int score) =>
      expect(_result!.score, equals(score));

  void thenStarsShouldBe(int stars) =>
      expect(_result!.stars, equals(stars));

  void thenItShouldBeANewBest() => expect(_result!.isNewBest, isTrue);

  void thenItShouldNotBeANewBest() => expect(_result!.isNewBest, isFalse);

  Future<void> thenStoredBestShouldBe(int score) async {
    final stored = await _repository.find(_levelId);
    expect(stored!.bestScore, equals(score));
  }

  Future<void> thenStoredStarsShouldBe(int stars) async {
    final stored = await _repository.find(_levelId);
    expect(stored!.starsEarned, equals(stars));
  }

  Future<CompleteLevelTestApi> givenHydratedProgressWithDefaultStars({
    int bestScore = 900,
  }) async {
    await _repository.save(
      ProgressMother.completedLevel(
        levelId: _levelId,
        bestScore: bestScore,
        stars: 1,
      ),
    );
    return this;
  }
}
