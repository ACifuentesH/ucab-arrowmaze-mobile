import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/factories/i_arrow_factory.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

/// Crea entidades Arrow a partir de ArrowSpec.
/// Deriva la dirección de la punta del último segmento del camino.
class ArrowFactory implements IArrowFactory {
  static const int _total = 4; // cuadrícula cuadrada: N=0, E=1, S=2, O=3

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

  Direction _computeDirection(List<int> from, List<int> to) {
    final dr = to[0] - from[0];
    final dc = to[1] - from[1];
    if (dr == -1 && dc == 0) return Direction(index: 0, total: _total); // N
    if (dr == 0 && dc == 1) return Direction(index: 1, total: _total);  // E
    if (dr == 1 && dc == 0) return Direction(index: 2, total: _total);  // S
    if (dr == 0 && dc == -1) return Direction(index: 3, total: _total); // O
    throw ArgumentError(
        'Casillas $from → $to no son ortogonalmente adyacentes.');
  }
}
