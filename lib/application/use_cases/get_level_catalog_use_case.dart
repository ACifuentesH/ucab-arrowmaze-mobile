import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Devuelve el catálogo completo de niveles disponibles para el jugador.
class GetLevelCatalogUseCase {
  final ILevelCatalogService _catalog;

  const GetLevelCatalogUseCase({required ILevelCatalogService catalog})
      : _catalog = catalog;

  Future<List<LevelPreview>> execute() => _catalog.getLevels();
}
