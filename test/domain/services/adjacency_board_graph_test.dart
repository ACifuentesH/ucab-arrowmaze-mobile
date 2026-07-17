import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/services/adjacency_board_graph.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

import '../../_support/mothers/node_mother.dart';

void main() {
  final east = Direction(index: 1, total: 4);

  group('AdjacencyBoardGraph', () {
    test('should_find_a_node_when_looked_up_by_id', () {
      final nodes = NodeMother.emptyGrid(rows: 1, cols: 2);
      final graph = AdjacencyBoardGraph(nodes);
      expect(graph.nodeById(NodeMother.idAt(0, 1)), isNotNull);
    });

    test('should_answer_null_when_node_does_not_exist', () {
      final graph = AdjacencyBoardGraph(NodeMother.emptyGrid(rows: 1, cols: 1));
      expect(graph.nodeById(NodeMother.idAt(5, 5)), isNull);
    });

    test('should_expose_node_adjacency_when_nodes_are_connected', () {
      // Arrange
      final a = NodeMother.emptyNodeAt(0, 0);
      final b = NodeMother.emptyNodeAt(0, 1);
      a.connect(east, b.id);
      // Act
      final graph = AdjacencyBoardGraph([a, b]);
      // Assert
      expect(graph.connectedNode(a.id, east), equals(b.id));
      expect(graph.connectedNode(b.id, east), isNull);
    });

    test('should_enumerate_every_node_when_iterated', () {
      final graph = AdjacencyBoardGraph(NodeMother.emptyGrid(rows: 2, cols: 3));
      expect(graph.allNodes, hasLength(6));
    });
  });
}
