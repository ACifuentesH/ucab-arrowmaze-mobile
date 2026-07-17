import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/ports/i_board_graph.dart';

/// Patrón Strategy: encapsula TODA la matemática de la forma del tablero.
/// Cambiar cuadrícula cuadrada / hexagonal / 3D no toca el resto del dominio.
abstract interface class ITopologyStrategy {
  /// Direcciones válidas de esta topología (4 cuadrada, 6 hex, ...).
  List<Direction> allowedDirections();

  /// Construye las conexiones entre nodos y devuelve el grafo del tablero.
  IBoardGraph buildConnections(List<Node> nodes);
}
