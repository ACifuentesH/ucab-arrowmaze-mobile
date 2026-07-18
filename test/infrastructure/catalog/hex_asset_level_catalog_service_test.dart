import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/topology_kind.dart';
import 'package:arrow_maze/infrastructure/catalog/asset_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/hex_asset_level_catalog_service.dart';

/// Los dos catálogos de assets están AISLADOS: el manifest cuadrado nunca
/// expone niveles hex y viceversa. Se lee del bundle real (pubspec → assets),
/// por eso usa `testWidgets` (inicializa el binding que sirve rootBundle).
void main() {
  group('Aislamiento de catálogos de assets', () {
    testWidgets('should_never_expose_hex_levels_when_reading_square_manifest',
        (tester) async {
      final previews = await const AssetLevelCatalogService().getLevels();

      expect(previews, isNotEmpty);
      expect(previews.any((p) => p.id.startsWith('hex_')), isFalse,
          reason: 'el manifest cuadrado no debe incluir niveles hex');
      expect(previews.every((p) => p.topology == TopologyKind.square), isTrue);
    });

    testWidgets('should_expose_exactly_hex_1_and_hex_2_when_reading_hex_manifest',
        (tester) async {
      final previews = await const HexAssetLevelCatalogService().getLevels();

      expect(previews.map((p) => p.id).toList(), equals(['hex_1', 'hex_2']));
      expect(previews.every((p) => p.topology == TopologyKind.hex), isTrue,
          reason: 'todo nivel del catálogo hex declara topology hex');
    });
  });
}
