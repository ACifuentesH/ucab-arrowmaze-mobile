import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/ports/i_board_graph.dart';
import 'package:arrow_maze/domain/ports/i_topology_strategy.dart';
import 'package:arrow_maze/domain/services/adjacency_board_graph.dart';

/// Estrategia concreta: cuadrícula HEXAGONAL pointy-top con coordenadas offset
/// **odd-r** (las filas IMPARES se desplazan media celda a la derecha).
/// Igual que `SquareGridTopology`, toda la "matemática" de la forma vive AQUÍ;
/// el resto del dominio la ignora. total = 6, índices horarios empezando en NE.
///
/// Los 6 vecinos dependen de la PARIDAD de la fila (odd-r). Esta tabla es la
/// FUENTE DE VERDAD (la comparten `HexArrowFactory` y la validación del builder):
///
/// | index | nombre | fila PAR (r%2==0)  | fila IMPAR      |
/// |-------|--------|--------------------|-----------------|
/// | 0     | NE     | (r-1, c)           | (r-1, c+1)      |
/// | 1     | E      | (r,   c+1)         | (r,   c+1)      |
/// | 2     | SE     | (r+1, c)           | (r+1, c+1)      |
/// | 3     | SW     | (r+1, c-1)         | (r+1, c)        |
/// | 4     | W      | (r,   c-1)         | (r,   c-1)      |
/// | 5     | NW     | (r-1, c-1)         | (r-1, c)        |
///
/// No necesita rows/cols: itera los nodos que realmente existen y conecta los
/// vecinos hexagonales que también existan. Funciona con cualquier forma.
class HexGridTopology implements ITopologyStrategy {
  const HexGridTopology();

  static const int _total = 6;
  static const int ne = 0, e = 1, se = 2, sw = 3, w = 4, nw = 5;

  Direction _dir(int i) => Direction(index: i, total: _total);
  CellId _idAt(int r, int c) => CellId('r${r}c$c');

  @override
  List<Direction> allowedDirections() =>
      [_dir(ne), _dir(e), _dir(se), _dir(sw), _dir(w), _dir(nw)];

  @override
  IBoardGraph buildConnections(List<Node> nodes) {
    final byId = {for (final n in nodes) n.id: n};
    for (final node in nodes) {
      final rc = _parseId(node.id.value);
      if (rc == null) continue;
      final (r, c) = rc;
      // Recorre las 6 direcciones respetando la paridad de la fila del nodo.
      for (int i = 0; i < _total; i++) {
        final (nr, nc) = neighborOffset(i, r, c);
        _tryConnect(node, byId, _dir(i), nr, nc);
      }
    }
    return AdjacencyBoardGraph(nodes);
  }

  /// Coordenada `(fila, col)` del vecino en la dirección [index] desde `(r, c)`,
  /// según la tabla odd-r documentada arriba. Función pura y compartida.
  static (int, int) neighborOffset(int index, int r, int c) {
    final bool even = r.isEven;
    switch (index) {
      case ne:
        return even ? (r - 1, c) : (r - 1, c + 1);
      case e:
        return (r, c + 1);
      case se:
        return even ? (r + 1, c) : (r + 1, c + 1);
      case sw:
        return even ? (r + 1, c - 1) : (r + 1, c);
      case w:
        return (r, c - 1);
      case nw:
        return even ? (r - 1, c - 1) : (r - 1, c);
      default:
        throw ArgumentError('Dirección hex fuera de rango: $index');
    }
  }

  void _tryConnect(Node node, Map<CellId, Node> byId, Direction dir, int r, int c) {
    final neighborId = _idAt(r, c);
    if (byId.containsKey(neighborId)) {
      node.connect(dir, neighborId);
    }
  }

  static (int, int)? _parseId(String id) {
    final m = RegExp(r'^r(\d+)c(\d+)$').firstMatch(id);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }
}
