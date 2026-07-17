import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/entities/cell/i_cell.dart';

/// Pared: bloquea el paso. Sustituible por cualquier ICell (LSP).
class WallCell implements ICell {
  @override
  final CellId id;
  WallCell({required this.id});

  @override
  bool get isWalkable => false;
}
