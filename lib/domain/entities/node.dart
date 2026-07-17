import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/entities/cell/i_cell.dart';

/// Entidad Nodo del grafo del tablero.
/// NO usa coordenadas (x, y): conoce a sus vecinos por dirección.
/// Envuelve una ICell como contenido ("wraps content").
class Node {
  final CellId id;
  final ICell content;
  final Map<Direction, CellId> _connections = {};

  Node({required this.id, required this.content});

  /// Conecta este nodo con otro en una dirección (lo usa la topología al armar).
  void connect(Direction direction, CellId targetId) =>
      _connections[direction] = targetId;

  /// Vecino en una dirección, o null si no hay arista. "Tell, Don't Ask".
  CellId? neighborTowards(Direction direction) => _connections[direction];

  bool get isWalkable => content.isWalkable;
}
