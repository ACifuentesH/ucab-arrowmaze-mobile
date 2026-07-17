import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Lee el catálogo de niveles generados por el usuario desde el repositorio local.
class GeneratedLevelCatalogService implements ILevelCatalogService {
  final IGeneratedLevelRepository _repository;

  const GeneratedLevelCatalogService(this._repository);

  @override
  Future<List<LevelPreview>> getLevels() async {
    final defs = await _repository.findAll();
    return defs
        .map((d) => LevelPreview.fromDefinition(d, source: LevelSource.generated))
        .toList();
  }
}
