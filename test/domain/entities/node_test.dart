import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/direction.dart';

import '../../_support/mothers/node_mother.dart';

void main() {
  final east = Direction(index: 1, total: 4);
  final west = Direction(index: 3, total: 4);

  group('Node', () {
    test('should_know_its_neighbor_when_connected_in_a_direction', () {
      // Arrange
      final node = NodeMother.emptyNodeAt(0, 0);
      // Act
      node.connect(east, NodeMother.idAt(0, 1));
      // Assert
      expect(node.neighborTowards(east), equals(NodeMother.idAt(0, 1)));
    });

    test('should_answer_null_when_no_edge_exists_in_a_direction', () {
      final node = NodeMother.emptyNodeAt(0, 0);
      expect(node.neighborTowards(west), isNull);
    });

    test('should_delegate_walkability_to_its_content_when_asked', () {
      expect(NodeMother.emptyNodeAt(0, 0).isWalkable, isTrue);
      expect(NodeMother.wallNodeAt(0, 0).isWalkable, isFalse);
    });
  });
}
