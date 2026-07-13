import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';

/// Solver de referencia para tests: demuestra que un tablero es resoluble.
///
/// Replica Board._isPathClear usando solo la API pública (graph + occupancy)
/// para encontrar una flecha liberable SIN gastar vidas, y las va sacando
/// con avidez hasta vaciar el tablero.
class GreedyBoardSolver {
  const GreedyBoardSolver();

  /// ¿La flecha puede escapar en el estado actual del tablero?
  bool canEscape(Board board, Arrow arrow) {
    var current =
        board.graph.connectedNode(arrow.headCell, arrow.headDirection);
    while (current != null) {
      if (board.occupancy.containsKey(current)) return false;
      if (board.graph.nodeById(current) == null) return true;
      current = board.graph.connectedNode(current, arrow.headDirection);
    }
    return true;
  }

  /// Saca flechas liberables hasta vaciar el tablero. Devuelve false si en
  /// algún punto ninguna flecha puede escapar (nivel atascado/no resoluble).
  bool solve(Board board) {
    var guard = 0;
    while (!board.isCleared()) {
      if (guard++ > 1000) return false;
      Arrow? next;
      for (final arrow in board.arrows.values) {
        if (canEscape(board, arrow)) {
          next = arrow;
          break;
        }
      }
      if (next == null) return false;
      board.tryRemoveArrow(next.id);
    }
    return true;
  }
}
