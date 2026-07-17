import 'package:arrow_maze/application/commands/i_arrow_command.dart';

/// Mantiene el historial de comandos ejecutados y soporta Undo (GoF Command).
/// La capa de aplicación usa este invoker para no acumular lógica de deshacer
/// en los casos de uso individuales.
class CommandInvoker {
  final _history = <IArrowCommand>[];

  /// Ejecuta el comando y, si tuvo éxito, lo apila en el historial.
  bool execute(IArrowCommand command) {
    final result = command.execute();
    if (result) _history.add(command);
    return result;
  }

  /// Deshace el último comando exitoso.
  void undo() {
    if (_history.isNotEmpty) _history.removeLast().undo();
  }

  /// Vacía el historial (usado al reiniciar el nivel).
  void clear() => _history.clear();

  bool get canUndo => _history.isNotEmpty;
}
