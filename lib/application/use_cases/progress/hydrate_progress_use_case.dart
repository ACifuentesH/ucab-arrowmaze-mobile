import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/mappers/progress_mapper.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';

/// Descarga el progreso remoto y lo aplica sobre el almacenamiento local.
///
/// Usuario nuevo (404 → null desde [SyncProgressUseCase.pull]): limpia el
/// progreso local de forma silenciosa.
class HydrateProgressUseCase {
  final SyncProgressUseCase _sync;
  final IPlayerProgressRepository _local;
  final ILevelCatalogService? _catalog;

  const HydrateProgressUseCase({
    required SyncProgressUseCase sync,
    required IPlayerProgressRepository local,
    ILevelCatalogService? catalog,
  })  : _sync = sync,
        _local = local,
        _catalog = catalog;

  Future<void> execute() async {
    final remote = await _sync.pull();
    if (remote == null) {
      await _local.clear();
      return;
    }

    final catalogById = await _catalogById();
    await _local.replaceAll(
      ProgressMapper.toLocalEntries(remote, catalogById: catalogById),
    );
  }

  Future<Map<String, LevelPreview>> _catalogById() async {
    if (_catalog == null) return const {};
    final levels = await _catalog.getLevels();
    return {for (final level in levels) level.id: level};
  }
}
