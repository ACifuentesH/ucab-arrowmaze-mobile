import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

/// Entidad Arrow: una pieza del juego que ocupa VARIAS casillas (tail→head).
/// El camino puede ser recto o doblar; la dirección de la punta se determina
/// en tiempo de construcción (fábrica) a partir del último segmento del path.
class Arrow {
  final String id;

  /// Casillas que ocupa la flecha, en orden tail → head. Inmutable.
  final List<CellId> path;

  /// Color en formato hex "#RRGGBB".
  final String color;

  /// Dirección hacia la que apunta la punta (último segmento del camino).
  final Direction headDirection;

  Arrow({
    required this.id,
    required List<CellId> path,
    required this.color,
    required this.headDirection,
  }) : path = List.unmodifiable(path) {
    if (path.length < 2) {
      throw ArgumentError('Arrow "$id": path debe tener al menos 2 casillas.');
    }
  }

  CellId get headCell => path.last;
  CellId get tailCell => path.first;

  @override
  String toString() => 'Arrow($id, ${path.length} celdas, dir=${headDirection.index})';
}
