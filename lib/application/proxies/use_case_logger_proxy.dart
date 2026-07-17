import 'dart:developer' show log;

import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/application/use_cases/i_remove_arrow_use_case.dart';

/// AOP – Proxy de logging para IRemoveArrowUseCase.
/// Registra entrada, salida y snapshot del tablero sin tocar la lógica delegada.
class UseCaseLoggerProxy implements IRemoveArrowUseCase {
  final IRemoveArrowUseCase _delegate;

  UseCaseLoggerProxy({required IRemoveArrowUseCase delegate})
      : _delegate = delegate;

  @override
  bool execute(
    Board board,
    String arrowId, {
    bool applyLifePenalty = true,
  }) {
    final arrowsBefore = board.arrowCount;
    final livesBefore = board.lives.value;
    final start = DateTime.now();

    final result = _delegate.execute(
      board,
      arrowId,
      applyLifePenalty: applyLifePenalty,
    );

    final ms = DateTime.now().difference(start).inMilliseconds;
    log(
      '[RemoveArrow] arrowId=$arrowId valid=$result '
      'arrows $arrowsBefore→${board.arrowCount} '
      'lives $livesBefore→${board.lives.value} '
      'penalty=$applyLifePenalty '
      '${ms}ms status=${board.status.name}',
      name: 'UseCaseLogger',
    );
    return result;
  }
}
