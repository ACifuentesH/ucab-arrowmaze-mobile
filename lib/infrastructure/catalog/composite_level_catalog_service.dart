import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Patrón Composite: combina múltiples [ILevelCatalogService] en uno solo.
/// El cliente no sabe si está hablando con una fuente o con N fuentes.
///
/// Uso típico: AssetLevelCatalogService + GeneratedLevelCatalogService.
class CompositeLevelCatalogService implements ILevelCatalogService {
  final List<ILevelCatalogService> _catalogs;

  const CompositeLevelCatalogService(this._catalogs);

  @override
  Future<List<LevelPreview>> getLevels() async {
    final results =
        await Future.wait(_catalogs.map((c) => c.getLevels()));
    return results.expand((list) => list).toList();
  }
}
