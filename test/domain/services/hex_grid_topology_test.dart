import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/services/hex_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

import '../../_support/mothers/node_mother.dart';

void main() {
  const topology = HexGridTopology();
  Direction dir(int i) => Direction(index: i, total: 6);
  final ne = dir(0), e = dir(1), se = dir(2), sw = dir(3), w = dir(4), nw = dir(5);

  /// Cuadrícula rectangular de celdas para tener todos los vecinos presentes.
  List<Node> rectGrid({required int rows, required int cols}) => [
        for (int r = 0; r < rows; r++)
          for (int c = 0; c < cols; c++) NodeMother.emptyNodeAt(r, c),
      ];

  group('HexGridTopology — allowed directions', () {
    test('should_offer_six_ports_with_total_six_when_asked', () {
      final dirs = topology.allowedDirections();
      expect(dirs, hasLength(6));
      expect(dirs.map((d) => d.index).toList(), equals([0, 1, 2, 3, 4, 5]));
      expect(dirs.every((d) => d.total == 6), isTrue);
    });
  });

  group('HexGridTopology — neighbors of an EVEN-row node (odd-r)', () {
    // Nodo central en fila PAR (2,2) dentro de un tablero 4×4.
    test('should_connect_all_six_neighbors_when_row_is_even', () {
      final graph = topology.buildConnections(rectGrid(rows: 4, cols: 4));
      final o = NodeMother.idAt(2, 2);
      expect(graph.connectedNode(o, ne), equals(NodeMother.idAt(1, 2)));
      expect(graph.connectedNode(o, e), equals(NodeMother.idAt(2, 3)));
      expect(graph.connectedNode(o, se), equals(NodeMother.idAt(3, 2)));
      expect(graph.connectedNode(o, sw), equals(NodeMother.idAt(3, 1)));
      expect(graph.connectedNode(o, w), equals(NodeMother.idAt(2, 1)));
      expect(graph.connectedNode(o, nw), equals(NodeMother.idAt(1, 1)));
    });
  });

  group('HexGridTopology — neighbors of an ODD-row node (odd-r)', () {
    // Nodo central en fila IMPAR (1,2) dentro de un tablero 4×4.
    test('should_connect_all_six_neighbors_when_row_is_odd', () {
      final graph = topology.buildConnections(rectGrid(rows: 4, cols: 4));
      final o = NodeMother.idAt(1, 2);
      expect(graph.connectedNode(o, ne), equals(NodeMother.idAt(0, 3)));
      expect(graph.connectedNode(o, e), equals(NodeMother.idAt(1, 3)));
      expect(graph.connectedNode(o, se), equals(NodeMother.idAt(2, 3)));
      expect(graph.connectedNode(o, sw), equals(NodeMother.idAt(2, 2)));
      expect(graph.connectedNode(o, w), equals(NodeMother.idAt(1, 1)));
      expect(graph.connectedNode(o, nw), equals(NodeMother.idAt(0, 2)));
    });
  });

  group('HexGridTopology — boundaries and holes', () {
    test('should_leave_edges_missing_when_neighbor_cell_does_not_exist', () {
      // Corner (0,0) fila par: W(0,-1), NW(-1,-1), NE(-1,0), SW(1,-1) no existen.
      final graph = topology.buildConnections(rectGrid(rows: 2, cols: 2));
      final corner = NodeMother.idAt(0, 0);
      expect(graph.connectedNode(corner, ne), isNull);
      expect(graph.connectedNode(corner, nw), isNull);
      expect(graph.connectedNode(corner, w), isNull);
      expect(graph.connectedNode(corner, sw), isNull);
      // E y SE sí existen.
      expect(graph.connectedNode(corner, e), equals(NodeMother.idAt(0, 1)));
      expect(graph.connectedNode(corner, se), equals(NodeMother.idAt(1, 0)));
    });

    test('should_skip_connection_when_a_middle_cell_is_absent', () {
      // Tablero 4×4 SIN la celda (2,3): el nodo par (2,2) pierde su vecino E.
      final nodes = [
        for (int r = 0; r < 4; r++)
          for (int c = 0; c < 4; c++)
            if (!(r == 2 && c == 3)) NodeMother.emptyNodeAt(r, c),
      ];
      final graph = topology.buildConnections(nodes);
      final o = NodeMother.idAt(2, 2);
      expect(graph.connectedNode(o, e), isNull);
      // El resto de vecinos del nodo par siguen conectados.
      expect(graph.connectedNode(o, w), equals(NodeMother.idAt(2, 1)));
      expect(graph.connectedNode(o, se), equals(NodeMother.idAt(3, 2)));
    });
  });
}
