import 'package:flutter_test/flutter_test.dart';

import '../../_support/mothers/node_mother.dart';

void main() {
  group('ICell (EmptyCell / WallCell)', () {
    test('should_be_walkable_when_cell_is_empty', () {
      expect(NodeMother.emptyCell().isWalkable, isTrue);
    });

    test('should_block_the_way_when_cell_is_a_wall', () {
      expect(NodeMother.wallCell().isWalkable, isFalse);
    });

    test('should_expose_its_cell_id_when_created', () {
      expect(NodeMother.emptyCell(row: 2, col: 1).id,
          equals(NodeMother.idAt(2, 1)));
      expect(NodeMother.wallCell(row: 0, col: 3).id,
          equals(NodeMother.idAt(0, 3)));
    });
  });
}
