import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/ports/i_board_graph.dart';
import 'package:arrow_maze/domain/ports/i_topology_strategy.dart';
import 'package:arrow_maze/domain/services/adjacency_board_graph.dart';

/// Estrategia concreta: cuadrícula ortogonal de 4 direcciones
/// (N=0, E=1, S=2, O=3). Toda la "matemática" de la forma vive AQUÍ;
/// el resto del dominio la ignora. Para hexagonal se crea otra Strategy
/// (total = 6) sin tocar nada de lo demás.
///
/// No necesita rows/cols: itera los nodos que realmente existen y conecta
/// los vecinos ortogonales que también existan. Funciona con cualquier forma.
class SquareGridTopology implements ITopologyStrategy {
  const SquareGridTopology();

  static const int _total = 4;
  static const int _north = 0, _east = 1, _south = 2, _west = 3;

  Direction _dir(int i) => Direction(index: i, total: _total);
  CellId _idAt(int r, int c) => CellId('r${r}c$c');

  @override
  List<Direction> allowedDirections() =>
      [_dir(_north), _dir(_east), _dir(_south), _dir(_west)];

  @override
  IBoardGraph buildConnections(List<Node> nodes) {
    final byId = {for (final n in nodes) n.id: n};
    for (final node in nodes) {
      final rc = _parseId(node.id.value);
      if (rc == null) continue;
      final (r, c) = rc;
      _tryConnect(node, byId, _dir(_north), r - 1, c);
      _tryConnect(node, byId, _dir(_east),  r,     c + 1);
      _tryConnect(node, byId, _dir(_south), r + 1, c);
      _tryConnect(node, byId, _dir(_west),  r,     c - 1);
    }
    return AdjacencyBoardGraph(nodes);
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
