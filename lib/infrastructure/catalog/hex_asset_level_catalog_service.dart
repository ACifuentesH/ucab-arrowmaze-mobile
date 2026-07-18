import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Lee el catálogo del MODO HEXAGONAL desde assets/levels/hex_manifest.json.
/// Gemelo de [AssetLevelCatalogService] pero apuntando al manifest hex, de modo
/// que los niveles hexagonales viven en un catálogo AISLADO del de la campaña
/// cuadrada (cada modo tiene su propia progresión). Cada entrada del manifest
/// corresponde a un archivo `assets/levels/<id>.json` con `topology: "hex"`.
class HexAssetLevelCatalogService implements ILevelCatalogService {
  const HexAssetLevelCatalogService();

  @override
  Future<List<LevelPreview>> getLevels() async {
    final manifestRaw =
        await rootBundle.loadString('assets/levels/hex_manifest.json');
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
