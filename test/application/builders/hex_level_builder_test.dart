import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

import '../../_support/apis/level_builder_test_api.dart';

void main() {
  group('LevelBuilder — tableros hexagonales (odd-r)', () {
    test('should_build_hex_board_when_definition_declares_hex_topology', () {
      LevelBuilderTestApi()
          .givenAHexLevelDefinition()
          .whenBoardIsBuilt()
          .thenBoardTopologyShouldBe(TopologyKind.hex);
    });

    test('should_connect_neighbors_per_odd_r_table_when_hex_board_is_built',
        () {
      final api = LevelBuilderTestApi()
          .givenAHexLevelDefinition()
          .whenBoardIsBuilt();
      // Fila IMPAR (1,1): NE → (0,2), SW → (2,1).
      api.thenCellShouldConnectTo('r1c1', 'r0c2', index: 0, total: 6);
      api.thenCellShouldConnectTo('r1c1', 'r2c1', index: 3, total: 6);
      // Fila PAR (0,1): SE → (1,1), NW no aplica aquí; W → (0,0).
      api.thenCellShouldConnectTo('r0c1', 'r1c1', index: 2, total: 6);
      api.thenCellShouldConnectTo('r0c1', 'r0c0', index: 4, total: 6);
    });

    test('should_assign_six_port_head_directions_when_hex_arrows_are_created',
        () {
      final api = LevelBuilderTestApi()
          .givenAHexLevelDefinition()
          .whenBoardIsBuilt();
      api.thenBoardShouldHaveArrows(2);
      // h1 (1,0)→(1,1): Este. h2 (0,2)→(1,2): SE desde fila par.
      api.thenArrowShouldPointTo('h1', index: 1, total: 6);
      api.thenArrowShouldPointTo('h2', index: 2, total: 6);
    });

    test('should_reject_build_when_path_pair_is_not_hex_adjacent', () {
      LevelBuilderTestApi()
          .givenAHexDefinitionWithNonAdjacentArrow()
          .whenBoardIsBuilt()
          .thenBuildShouldBeRejected();
    });

    test('should_default_to_square_when_topology_field_is_missing', () {
      LevelBuilderTestApi()
          .givenAFlatJsonWithoutTopologyField()
          .whenBoardIsBuilt()
          .thenBoardTopologyShouldBe(TopologyKind.square);
    });
  });
}
