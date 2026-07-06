import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/entities/cell/i_cell.dart';

/// Celda vacía transitable, sin comportamiento.
class EmptyCell implements ICell {
  @override
  final CellId id;
  EmptyCell({required this.id});

  @override
  bool get isWalkable => true;
}
