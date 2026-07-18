import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/factories/i_arrow_factory.dart';
import 'package:arrow_maze/domain/services/hex_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

/// Crea entidades Arrow sobre una cuadrícula HEXAGONAL (pointy-top, odd-r).
/// Igual que `ArrowFactory` pero total = 6: deriva la dirección de la punta del
/// último segmento del camino resolviendo el delta contra la tabla odd-r
/// (la fuente de verdad vive en `HexGridTopology`), usando la paridad de la
/// fila ORIGEN del segmento.
class HexArrowFactory implements IArrowFactory {
  static const int _total = 6;

  @override
  Arrow create(ArrowSpec spec) {
    if (spec.path.length < 2) {
      throw ArgumentError('Arrow "${spec.id}": path debe tener al menos 2 casillas.');
    }
    final path = spec.path.map((rc) => CellId('r${rc[0]}c${rc[1]}')).toList();
    final headDir = _computeDirection(
      spec.path[spec.path.length - 2],
      spec.path[spec.path.length - 1],
    );
    return Arrow(id: spec.id, path: path, color: spec.color, headDirection: headDir);
  }

  /// Resuelve `(to - from)` contra las 6 direcciones hexagonales usando la
  /// paridad de la fila de [from]. Si no corresponde a ninguna → ArgumentError.
  Direction _computeDirection(List<int> from, List<int> to) {
    final r = from[0];
    final c = from[1];
    for (int i = 0; i < _total; i++) {
      final (nr, nc) = HexGridTopology.neighborOffset(i, r, c);
      if (nr == to[0] && nc == to[1]) {
        return Direction(index: i, total: _total);
      }
    }
    throw ArgumentError(
        'Casillas $from → $to no son hexagonalmente adyacentes (odd-r).');
  }
}
