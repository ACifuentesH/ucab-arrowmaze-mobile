import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/remove_arrow_test_api.dart';

void main() {
  group('CommandInvoker (GoF Command + Undo)', () {
    test('should_stack_the_command_when_execution_succeeds', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenArrowIsTapped('a1')
          .whenMoveIsUndone()
          .thenUndoShouldSucceed();
    });

    test('should_not_stack_the_command_when_execution_fails', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a1') // bloqueado → no entra al historial
          .whenMoveIsUndone()
          .thenUndoShouldBeRejected();
    });

    test('should_undo_moves_in_reverse_order_when_undone_repeatedly', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a2')
          .whenArrowIsTapped('a1')
          .whenMoveIsUndone() // vuelve a1
          ..thenArrowShouldBeBackOnBoard('a1')
          ..whenMoveIsUndone() // vuelve a2
          ..thenArrowShouldBeBackOnBoard('a2')
          ..thenArrowCountShouldBe(2);
    });
  });
}
