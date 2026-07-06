import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/application/commands/i_arrow_command.dart';

/// Comando concreto: sacar una flecha del tablero (con soporte Undo).
class RemoveArrowCommand implements IArrowCommand {
  final Board _board;
  final String _arrowId;

  /// Flecha guardada antes de la extracción; permite restaurarla en undo().
  Arrow? _savedArrow;

  RemoveArrowCommand({required Board board, required String arrowId})
      : _board = board,
        _arrowId = arrowId;

  @override
  bool execute() {
    _savedArrow = _board.arrowById(_arrowId);
    return _board.tryRemoveArrow(_arrowId);
  }

  @override
  void undo() {
    if (_savedArrow != null) {
      _board.restoreArrow(_savedArrow!);
      _savedArrow = null;
    }
  }
}
