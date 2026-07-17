import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/dtos/level_result.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/services/score_calculator.dart';

/// Puntúa un nivel recién completado y persiste el mejor intento localmente.
///
/// La sincronización remota (PUT /progress con last*) la dispara
/// [GameViewModel] vía [IProgressSyncCoordinator.pushCompletedLevel] justo
/// después de este caso de uso, sin bloquear la UI de victoria.
class CompleteLevelUseCase {
  final IPlayerProgressRepository _repository;

  const CompleteLevelUseCase({
    required IPlayerProgressRepository repository,
  }) : _repository = repository;

  Future<LevelResult> execute({
    required String levelId,
    required Difficulty difficulty,
    required int initialArrowCount,
    required int initialLives,
    required int livesRemaining,
    required int elapsedSeconds,
    int? timeLimitSeconds,
  }) async {
    final score = ScoreCalculator.calculate(
      arrowCount: initialArrowCount,
      livesRemaining: livesRemaining,
      elapsedSeconds: elapsedSeconds,
      timeLimitSeconds: timeLimitSeconds,
      difficulty: difficulty,
    );

    final maxPossibleScore = ScoreCalculator.calculate(
      arrowCount: initialArrowCount,
      livesRemaining: initialLives,
      elapsedSeconds: 0,
      timeLimitSeconds: timeLimitSeconds,
      difficulty: difficulty,
    );
    final stars = ScoreCalculator.starsFor(
      score,
      maxPossibleScore: maxPossibleScore,
    );

    final previous = await _repository.find(levelId);
    // Null-safe: progreso mal hidratado o sin bestScore → 0.
    final previousBest = previous?.bestScore ?? 0;
    final isNewBest = previous == null || score > previousBest;

    final previousStars = previous?.starsEarned ?? 0;
    final starsToStore = stars > previousStars ? stars : previousStars;

    // Persistir también si solo mejoran las estrellas (p. ej. tras hidratar
    // con stars=1 por defecto antes del fix de mapeo).
    final shouldPersist =
        isNewBest || starsToStore > previousStars;

    if (shouldPersist) {
      await _repository.save(LevelProgress(
        levelId: levelId,
        bestScore: isNewBest ? score : previousBest,
        bestTimeSeconds: isNewBest
            ? elapsedSeconds
            : previous.bestTimeSeconds,
        starsEarned: starsToStore.clamp(1, 3),
        completedAt: DateTime.now(),
      ));
    }

    return LevelResult(
      levelId: levelId,
      score: score,
      stars: stars,
      isNewBest: isNewBest,
    );
  }
}
