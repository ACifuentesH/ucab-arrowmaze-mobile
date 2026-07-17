import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/remove_arrow_test_api.dart';

void main() {
  group('Board — reglas de extracción de flechas', () {
    test('should_remove_arrow_when_path_is_clear', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenArrowIsTapped('a1')
          .thenArrowShouldEscape();
    });

    test('should_lose_a_life_when_arrow_is_blocked', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a1')
          .thenALifeShouldBeLost(to: 2);
    });

    test('should_keep_playing_when_lives_remain_after_a_blocked_move', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow(lives: 3)
          .whenArrowIsTapped('a1')
          .thenGameShouldStillBePlaying();
    });

    test('should_clear_level_when_last_arrow_escapes', () {
      RemoveArrowTestApi()
          .givenAnAlmostClearedBoard()
          .whenArrowIsTapped('a1')
          .thenLevelShouldBeCleared();
    });

    test('should_end_game_when_last_life_is_lost', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow(lives: 1)
          .whenArrowIsTapped('a1')
          .thenGameShouldBeOver();
    });

    test(
        'should_not_lose_a_life_when_blocked_without_life_penalty',
        () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow(lives: 1)
          .whenArrowIsTappedWithoutLifePenalty('a1')
          ..thenMoveShouldBeRejected()
          ..thenALifeShouldBeLost(to: 1)
          ..thenGameShouldStillBePlaying();
    });

    test('should_free_blocked_arrow_when_its_blocker_escapes', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a2') // a2 despeja el carril de a1
          .whenArrowIsTapped('a1')
          .thenLevelShouldBeCleared();
    });

    test('should_count_moves_when_arrows_escape', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenArrowIsTapped('a1')
          .thenMoveCountShouldBe(1);
    });
  });
}
