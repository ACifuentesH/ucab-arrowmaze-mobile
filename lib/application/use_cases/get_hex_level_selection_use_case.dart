import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';

/// Combina el catálogo del MODO HEXAGONAL con el progreso local del jugador
/// para producir la lista de su pantalla de selección.
///
/// Espejo de [GetLevelSelectionUseCase] pero sobre el catálogo hex: misma regla
/// de progresión secuencial (el primer nivel nace desbloqueado; cada siguiente
/// se desbloquea al completar el anterior). El progreso se comparte con el
/// repositorio único de jugador — los ids hex no colisionan con los cuadrados.
class GetHexLevelSelectionUseCase {
  final ILevelCatalogService _catalog;
  final IPlayerProgressRepository _progress;

  const GetHexLevelSelectionUseCase({
    required ILevelCatalogService catalog,
    required IPlayerProgressRepository progress,
  })  : _catalog = catalog,
        _progress = progress;

  Future<List<LevelSelectEntry>> execute() async {
    final previews = await _catalog.getLevels();
    final progressById = {
      for (final p in await _progress.findAll()) p.levelId: p,
    };

    final entries = <LevelSelectEntry>[];
    var previousCampaignLevelCompleted = true; // el primero nace desbloqueado
    for (final preview in previews) {
      final progress = progressById[preview.id];
      final completed = progress != null;

      final LevelStatus status;
      if (preview.source == LevelSource.asset) {
        status = completed
            ? LevelStatus.completed
            : previousCampaignLevelCompleted
                ? LevelStatus.unlocked
                : LevelStatus.locked;
        previousCampaignLevelCompleted = completed;
      } else {
        status = completed ? LevelStatus.completed : LevelStatus.unlocked;
      }

      entries.add(LevelSelectEntry(
        preview: preview,
        status: status,
        stars: progress?.starsEarned ?? 0,
        bestScore: progress?.bestScore,
      ));
    }
    return entries;
  }
}
