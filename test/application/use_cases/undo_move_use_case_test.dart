import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/remove_arrow_test_api.dart';

void main() {
  group('UndoMoveUseCase', () {
    test('should_restore_the_arrow_when_last_move_is_undone', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenArrowIsTapped('a1')
          .whenMoveIsUndone()
          ..thenUndoShouldSucceed()
          ..thenArrowShouldBeBackOnBoard('a1')
          ..thenArrowCountShouldBe(1);
    });

    test('should_reject_undo_when_no_moves_were_made', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenMoveIsUndone()
          .thenUndoShouldBeRejected();
    });

    test('should_reject_undo_when_the_only_move_was_blocked', () {
      // Un movimiento inválido no entra al historial del CommandInvoker.
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a1')
          .whenMoveIsUndone()
          .thenUndoShouldBeRejected();
    });
  });
}
