import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/level_builder_test_api.dart';

void main() {
  group('LevelBuilder — Board desde el contrato de niveles', () {
    test('should_build_board_with_arrows_when_definition_is_valid', () {
      LevelBuilderTestApi()
          .givenAValidLevelDefinition()
          .whenBoardIsBuilt()
          .thenBoardShouldHaveArrows(1);
    });

    test('should_honor_configured_lives_when_board_is_built', () {
      LevelBuilderTestApi()
          .givenAValidLevelDefinition(lives: 5)
          .whenBoardIsBuilt()
          .thenBoardLivesShouldBe(5);
    });

    test('should_size_bounding_box_from_cells_when_board_is_built', () {
      LevelBuilderTestApi()
          .givenAValidLevelDefinition()
          .whenBoardIsBuilt()
          .thenBoardBoundsShouldBe(rows: 3, cols: 3);
    });

    test('should_reject_build_when_arrow_steps_outside_the_board', () {
      LevelBuilderTestApi()
          .givenADefinitionWithArrowOutsideBoard()
          .whenBoardIsBuilt()
          .thenBuildShouldBeRejected();
    });

    test('should_reject_build_when_two_arrows_share_a_cell', () {
      LevelBuilderTestApi()
          .givenADefinitionWithOverlappingArrows()
          .whenBoardIsBuilt()
          .thenBuildShouldBeRejected();
    });
  });
}
