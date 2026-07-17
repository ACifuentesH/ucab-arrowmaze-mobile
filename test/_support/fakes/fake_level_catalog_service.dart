import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Fake in-memory de ILevelCatalogService.
class FakeLevelCatalogService implements ILevelCatalogService {
  final List<LevelPreview> _previews = [];

  void seed(LevelPreview preview) => _previews.add(preview);

  @override
  Future<List<LevelPreview>> getLevels() async => List.of(_previews);
}
