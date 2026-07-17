import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/commands/remove_arrow_command.dart';
import 'package:arrow_maze/application/use_cases/i_remove_arrow_use_case.dart';

/// Caso de uso central: encapsula el toque de una flecha como un Command
/// para poder deshacerlo (Undo). El CommandInvoker mantiene el historial.
class RemoveArrowUseCase implements IRemoveArrowUseCase {
  final CommandInvoker _invoker;

  RemoveArrowUseCase({required CommandInvoker invoker}) : _invoker = invoker;

  @override
  bool execute(
    Board board,
    String arrowId, {
    bool applyLifePenalty = true,
  }) {
    final command = RemoveArrowCommand(
      board: board,
      arrowId: arrowId,
      applyLifePenalty: applyLifePenalty,
    );
    return _invoker.execute(command);
  }
}
