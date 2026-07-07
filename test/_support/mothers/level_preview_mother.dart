import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_source.dart';

import 'level_definition_mother.dart';

/// Object Mother: LevelPreview válidos para el catálogo de niveles.
class LevelPreviewMother {
  static LevelPreview asset({String id = 'level_1'}) =>
      LevelPreview.fromDefinition(
        LevelDefinitionMother.withEscapableArrow(id: id),
        source: LevelSource.asset,
      );

  static LevelPreview generated({String id = 'generated_1'}) =>
      LevelPreview.fromDefinition(
        LevelDefinitionMother.withEscapableArrow(id: id),
        source: LevelSource.generated,
      );
}
