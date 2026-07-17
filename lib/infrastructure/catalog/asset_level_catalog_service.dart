import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Lee el catálogo de niveles bundleados desde assets/levels/manifest.json.
/// Cada entrada del manifest corresponde a un archivo assets/levels/<id>.json.
class AssetLevelCatalogService implements ILevelCatalogService {
  const AssetLevelCatalogService();

  @override
  Future<List<LevelPreview>> getLevels() async {
    final manifestRaw =
        await rootBundle.loadString('assets/levels/manifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final ids = (manifest['levels'] as List<dynamic>).cast<String>();

    final previews = <LevelPreview>[];
    for (final id in ids) {
      final raw = await rootBundle.loadString('assets/levels/$id.json');
      final def =
          LevelDefinition.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      previews.add(LevelPreview.fromDefinition(def, source: LevelSource.asset));
    }
    return previews;
  }
}
