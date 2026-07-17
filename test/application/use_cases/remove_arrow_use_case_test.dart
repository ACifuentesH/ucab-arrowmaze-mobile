import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/remove_arrow_test_api.dart';

void main() {
  group('RemoveArrowUseCase', () {
    test('should_report_success_and_count_the_move_when_arrow_escapes', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenArrowIsTapped('a1')
          ..thenArrowShouldEscape()
          ..thenArrowCountShouldBe(0)
          ..thenMoveCountShouldBe(1);
    });

    test('should_report_rejection_when_arrow_is_blocked', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a1')
          ..thenMoveShouldBeRejected()
          ..thenArrowCountShouldBe(2);
    });

    test('should_ignore_taps_when_game_is_already_over', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow(lives: 1)
          .whenArrowIsTapped('a1') // pierde la última vida → gameOver
          .whenArrowIsTapped('a2') // el juego terminó: sin efecto
          .thenMoveShouldBeIgnored();
    });
  });
}
