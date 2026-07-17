import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/services/square_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

import '../../_support/mothers/node_mother.dart';

void main() {
  const topology = SquareGridTopology();
  final north = Direction(index: 0, total: 4);
  final east = Direction(index: 1, total: 4);
  final south = Direction(index: 2, total: 4);
  final west = Direction(index: 3, total: 4);

  group('SquareGridTopology', () {
    test('should_offer_four_ports_when_asked_for_allowed_directions', () {
      expect(topology.allowedDirections(), hasLength(4));
    });

    test('should_connect_orthogonal_neighbors_when_building_a_full_grid', () {
      // Arrange
      final nodes = NodeMother.emptyGrid(rows: 2, cols: 2);
      // Act
      final graph = topology.buildConnections(nodes);
      // Assert — el centro superior-izquierdo ve Este y Sur, no Norte ni Oeste.
      final origin = NodeMother.idAt(0, 0);
      expect(graph.connectedNode(origin, east), equals(NodeMother.idAt(0, 1)));
      expect(graph.connectedNode(origin, south), equals(NodeMother.idAt(1, 0)));
      expect(graph.connectedNode(origin, north), isNull);
      expect(graph.connectedNode(origin, west), isNull);
    });

    test('should_leave_edges_missing_when_neighbor_cell_does_not_exist', () {
      // Tablero en L: existe (0,0), (1,0) y (1,1) — falta (0,1).
      final nodes = [
        NodeMother.emptyNodeAt(0, 0),
        NodeMother.emptyNodeAt(1, 0),
        NodeMother.emptyNodeAt(1, 1),
      ];
      final graph = topology.buildConnections(nodes);
      expect(graph.connectedNode(NodeMother.idAt(0, 0), east), isNull);
      expect(graph.connectedNode(NodeMother.idAt(1, 0), east),
          equals(NodeMother.idAt(1, 1)));
    });
  });
}
