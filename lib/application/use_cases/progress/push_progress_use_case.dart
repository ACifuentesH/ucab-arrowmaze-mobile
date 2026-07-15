import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/ports/i_token_storage.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';

/// Tras completar un nivel: arma el PUT /progress (con last*) y lo envía.
///
/// - Sin token → no-op (invitado / sin sesión).
/// - Fallos de red o 5xx → se absorben; el progreso local ya está guardado.
class PushProgressUseCase {
  final SyncProgressUseCase _sync;
  final IPlayerProgressRepository _local;
  final ITokenStorage _tokens;

  const PushProgressUseCase({
    required SyncProgressUseCase sync,
    required IPlayerProgressRepository local,
    required ITokenStorage tokens,
  })  : _sync = sync,
        _local = local,
        _tokens = tokens;

  Future<void> execute({
    required String lastLevelId,
    required int lastScore,
    required int lastMoves,
    required int lastTimeSeconds,
    required String currentLevelId,
  }) async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) return;

    try {
      final all = await _local.findAll();
      final completedLevels = <String>{
        for (final p in all) p.levelId,
        lastLevelId,
      }.toList();

      // Mapa completo de puntajes reales de todos los niveles pasados.
      final bestScores = <String, int>{
        for (final p in all)
          if (p.bestScore > 0) p.levelId: p.bestScore,
      };
      final storedBest = bestScores[lastLevelId] ?? 0;
      if (lastScore > storedBest) {
        bestScores[lastLevelId] = lastScore;
      } else if (!bestScores.containsKey(lastLevelId)) {
        bestScores[lastLevelId] = lastScore;
      }

      await _sync.push(ProgressUpdate(
        completedLevels: completedLevels,
        bestScores: Map<String, int>.from(bestScores),
        currentLevelId: currentLevelId,
        lastLevelId: lastLevelId,
        lastScore: lastScore,
        lastMoves: lastMoves,
        lastTimeSeconds: lastTimeSeconds,
      ));
    } on ApiError {
      // Silencioso: el progreso local ya quedó persistido.
    } catch (_) {
      // Silencioso ante fallos inesperados de transporte.
    }
  }
}
