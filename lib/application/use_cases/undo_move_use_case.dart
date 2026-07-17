import 'package:arrow_maze/application/commands/command_invoker.dart';

/// Caso de uso: deshace el último movimiento válido.
/// Devuelve false si no hay nada que deshacer.
class UndoMoveUseCase {
  final CommandInvoker _invoker;

  UndoMoveUseCase({required CommandInvoker invoker}) : _invoker = invoker;

  bool execute() {
    if (!_invoker.canUndo) return false;
    _invoker.undo();
    return true;
  }
}
