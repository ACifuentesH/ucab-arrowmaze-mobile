import 'package:flutter/foundation.dart';

import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Tras completar un nivel: arma el PUT /progress (con last*) y lo envía.
///
/// - Sin token → no-op (invitado / sin sesión).
/// - Fallos de red, 422 o 5xx → se registran en consola y se absorben;
///   el progreso local ya está guardado (UX sin interrupción).
class PushProgressUseCase {
  final SyncProgressUseCase _sync;
  final IPlayerProgressRepository _local;
  final ILocalStorage _storage;

  const PushProgressUseCase({
    required SyncProgressUseCase sync,
    required IPlayerProgressRepository local,
    required ILocalStorage storage,
  })  : _sync = sync,
        _local = local,
        _storage = storage;

  Future<void> execute({
    required String lastLevelId,
    required int lastScore,
    required int lastMoves,
    required int lastTimeSeconds,
    required String currentLevelId,
  }) async {
    final token = await _storage.readToken();
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
    } on ValidationError catch (e) {
      debugPrint(
        '⚠️ [PushProgressUseCase] Error 422: Payload inválido al sincronizar progreso. Detalles: $e',
      );
    } on ApiError catch (e) {
      debugPrint(
        '⚠️ [PushProgressUseCase] Error de API al sincronizar progreso. Detalles: $e',
      );
    } catch (e) {
      debugPrint(
        '⚠️ [PushProgressUseCase] Fallo inesperado de transporte al sincronizar progreso. Detalles: $e',
      );
    }
  }
}
