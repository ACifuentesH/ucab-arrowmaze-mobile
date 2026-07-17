import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/ports/i_board_graph.dart';

/// Implementación del grafo basada en las listas de adyacencia de los nodos.
/// Es AGNÓSTICA a la forma: sirve igual para cuadrada, hexagonal o 3D.
/// 
class AdjacencyBoardGraph implements IBoardGraph {
  final Map<CellId, Node> _nodes;

  AdjacencyBoardGraph(List<Node> nodes)
      : _nodes = {for (final n in nodes) n.id: n};

  @override
  Node? nodeById(CellId id) => _nodes[id];

  @override
  CellId? connectedNode(CellId sourceId, Direction direction) =>
      _nodes[sourceId]?.neighborTowards(direction);

  @override
  Iterable<Node> get allNodes => _nodes.values;
}
