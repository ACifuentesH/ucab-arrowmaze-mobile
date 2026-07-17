import 'package:arrow_maze/domain/entities/cell/empty_cell.dart';
import 'package:arrow_maze/domain/entities/cell/wall_cell.dart';
import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';

/// Object Mother: celdas y nodos del grafo del tablero.
class NodeMother {
  static CellId idAt(int row, int col) => CellId('r${row}c$col');

  static EmptyCell emptyCell({int row = 0, int col = 0}) =>
      EmptyCell(id: idAt(row, col));

  static WallCell wallCell({int row = 0, int col = 0}) =>
      WallCell(id: idAt(row, col));

  static Node emptyNodeAt(int row, int col) =>
      Node(id: idAt(row, col), content: emptyCell(row: row, col: col));

  static Node wallNodeAt(int row, int col) =>
      Node(id: idAt(row, col), content: wallCell(row: row, col: col));

  /// Cuadrícula rows×cols completa de celdas vacías transitables.
  static List<Node> emptyGrid({required int rows, required int cols}) => [
        for (int r = 0; r < rows; r++)
          for (int c = 0; c < cols; c++) emptyNodeAt(r, c),
      ];
}
