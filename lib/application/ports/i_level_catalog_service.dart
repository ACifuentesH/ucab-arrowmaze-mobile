import 'package:arrow_maze/application/dtos/level_preview.dart';

/// Strategy: devuelve la lista de niveles disponibles desde una fuente concreta.
///
/// Implementaciones:
///  - AssetLevelCatalogService  — lee JSONs bundleados en assets/levels/
///  - GeneratedLevelCatalogService — lee IGeneratedLevelRepository
///  - CompositeLevelCatalogService — combina N implementaciones (Composite)
abstract interface class ILevelCatalogService {
  Future<List<LevelPreview>> getLevels();
}
