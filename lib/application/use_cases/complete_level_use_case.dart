import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/dtos/level_result.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/services/score_calculator.dart';

/// Puntúa un nivel recién completado y persiste el mejor intento localmente.
///
/// La sincronización remota (PUT /progress con los campos last*) vive en
/// SyncProgressUseCase y requiere sesión activa — se orquesta desde
/// feature/auth cuando exista login.
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

    // El máximo teórico es el mismo cálculo sin vidas perdidas ni tiempo gastado.
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
    final isNewBest = previous == null || score > previous.bestScore;
    if (isNewBest) {
      await _repository.save(LevelProgress(
        levelId: levelId,
        bestScore: score,
        bestTimeSeconds: elapsedSeconds,
        starsEarned:
            previous != null && previous.starsEarned > stars
                ? previous.starsEarned
                : stars,
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
