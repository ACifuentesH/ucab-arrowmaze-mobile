import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/game_screen_test_api.dart';

void main() {
  group('GameScreen — render', () {
    testWidgets('should_render_the_board_when_a_level_is_loaded',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithAnEscapableArrow(id: 'level_test');
      await api.givenTheGameScreenIsOpenAt('level_test');

      api.thenTheBoardShouldBeShown();
      api.dispose();
    });
  });

  group('GameScreen — arrow interaction', () {
    testWidgets(
        'should_remove_the_arrow_when_a_removable_arrow_is_tapped',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithAnEscapableArrow(id: 'level_test');
      await api.givenTheGameScreenIsOpenAt('level_test');

      await api.whenTheBoardIsTappedAtItsCenter();

      api.thenTheArrowShouldHaveEscaped('a1');
      api.dispose();
    });

    testWidgets('should_lose_a_life_when_a_blocked_arrow_is_tapped',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithABlockedArrow(id: 'level_blocked', lives: 3);
      await api.givenTheGameScreenIsOpenAt('level_blocked');

      await api.whenTheBoardIsTappedAtItsCenter();

      api.thenLivesShouldBe(2);
      api.dispose();
    });
  });

  group('GameScreen — status overlays', () {
    testWidgets('should_show_victory_overlay_when_level_is_cleared',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithAnEscapableArrow(id: 'level_test');
      await api.givenTheGameScreenIsOpenAt('level_test');

      await api.whenTheBoardIsTappedAtItsCenter();

      api.thenTheVictoryOverlayShouldBeShown();
      api.dispose();
    });

    testWidgets('should_show_game_over_overlay_when_lives_run_out',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithABlockedArrow(id: 'level_blocked', lives: 1);
      await api.givenTheGameScreenIsOpenAt('level_blocked');

      await api.whenTheBoardIsTappedAtItsCenter();

      api.thenTheGameOverOverlayShouldBeShown();
      api.dispose();
    });
  });

  group('GameScreen — victory overlay timing', () {
    testWidgets(
        'should_not_show_the_victory_overlay_immediately_when_the_last_arrow_is_tapped',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithAnEscapableArrow(id: 'level_test');
      await api.givenTheGameScreenIsOpenAt('level_test');

      await api.whenTheBoardIsTappedWithoutSettling();

      api.thenTheVictoryOverlayShouldNotBeShownYet();

      // Deja correr los temporizadores pendientes (clearEscaping,
      // deferLevelCleared) antes de terminar: flutter_test falla el test si
      // el árbol de widgets se destruye con timers todavía pendientes.
      await api.whenTheEscapeAnimationDelayElapses();
      api.dispose();
    });

    testWidgets(
        'should_show_the_victory_overlay_after_the_escape_animation_delay_elapses',
        (tester) async {
      final api = GameScreenTestApi(tester);
      api.givenALevelWithAnEscapableArrow(id: 'level_test');
      await api.givenTheGameScreenIsOpenAt('level_test');

      await api.whenTheBoardIsTappedWithoutSettling();
      api.thenTheVictoryOverlayShouldNotBeShownYet();

      await api.whenTheEscapeAnimationDelayElapses();

      api.thenTheVictoryOverlayShouldBeShown();
      api.dispose();
    });
  });
}
