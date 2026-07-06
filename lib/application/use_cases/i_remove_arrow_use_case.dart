import 'package:arrow_maze/domain/aggregates/board.dart';

/// Puerto del caso de uso "sacar una flecha del tablero".
abstract interface class IRemoveArrowUseCase {
  /// Intenta sacar la flecha [arrowId] del [board].
  /// Devuelve true si el movimiento fue válido.
  bool execute(Board board, String arrowId);
}
