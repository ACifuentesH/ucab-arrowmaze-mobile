/// Interfaz Command para operaciones sobre el tablero (GoF / Millett, cap.12).
/// Almacenar los comandos ejecutados en una pila permite Undo paso a paso.
abstract interface class IArrowCommand {
  /// Ejecuta la operación. Devuelve true si el movimiento fue válido.
  bool execute();

  /// Deshace la operación, restaurando el estado previo a [execute].
  void undo();
}
