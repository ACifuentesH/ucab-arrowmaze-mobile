import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/entities/node.dart';

/// Puerto: abstracción del grafo del tablero (DIP).
/// El dominio depende de esta interfaz, nunca de una implementación concreta.
abstract interface class IBoardGraph {
  Node? nodeById(CellId id);
  CellId? connectedNode(CellId sourceId, Direction direction);
  Iterable<Node> get allNodes;
}
