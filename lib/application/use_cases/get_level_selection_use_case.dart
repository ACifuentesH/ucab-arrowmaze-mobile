import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';

/// Combina el catálogo de niveles con el progreso local del jugador para
/// producir la lista de la pantalla de selección.
///
/// Regla de progresión de la campaña (niveles de assets, en el orden del
/// catálogo): el primero siempre está desbloqueado; cada uno de los demás se
/// desbloquea al completar el anterior. Los niveles generados por IA no
/// pertenecen a la campaña y nunca se bloquean.
class GetLevelSelectionUseCase {
  final ILevelCatalogService _catalog;
  final IPlayerProgressRepository _progress;

  const GetLevelSelectionUseCase({
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
