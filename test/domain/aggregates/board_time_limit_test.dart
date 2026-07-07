import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/board_time_test_api.dart';

void main() {
  group('Board — límite de tiempo (applyTimeTick)', () {
    test('should_keep_playing_when_time_is_below_the_limit', () {
      BoardTimeTestApi()
          .givenABoardWithTimeLimit(seconds: 10)
          .whenTimeAdvancesTo(9)
          .thenGameShouldStillBePlaying();
    });

    test('should_end_game_when_time_reaches_the_limit', () {
      BoardTimeTestApi()
          .givenABoardWithTimeLimit(seconds: 10)
          .whenTimeAdvancesTo(10)
          .thenGameShouldBeOver();
    });

    test('should_end_game_when_time_exceeds_the_limit', () {
      BoardTimeTestApi()
          .givenABoardWithTimeLimit(seconds: 10)
          .whenTimeAdvancesTo(15)
          .thenGameShouldBeOver();
    });

    test('should_not_emit_further_events_when_game_is_already_over', () {
      BoardTimeTestApi()
          .givenABoardWithTimeLimit(seconds: 10)
          .whenTimeAdvancesTo(10)
          .whenTimeAdvancesTo(11)
          .thenNoFurtherEventsShouldBeEmitted();
    });

    test('should_ignore_elapsed_time_when_board_has_no_limit', () {
      BoardTimeTestApi()
          .givenABoardWithoutTimeLimit()
          .whenTimeAdvancesTo(999)
          .thenGameShouldStillBePlaying();
    });
  });
}
