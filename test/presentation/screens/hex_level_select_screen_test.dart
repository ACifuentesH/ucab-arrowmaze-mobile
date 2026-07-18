import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/hex_level_select_screen_test_api.dart';

void main() {
  group('HexLevelSelectScreen — render', () {
    testWidgets(
        'should_show_three_levels_with_only_hex_1_unlocked_when_no_progress',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenTheHexScreenIsOpen();

      // Los tres nodos presentes; hex_1 desbloqueado (primero de la campaña),
      // hex_2 y hex_3 bloqueados -> exactamente dos candados.
      api
        ..thenHexTileShouldExist(1)
        ..thenHexTileShouldExist(2)
        ..thenHexTileShouldExist(3)
        ..thenLockIconsShouldBeShown(count: 2);
    });

    testWidgets('should_show_the_coming_soon_node_at_the_end_of_the_trail',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenTheHexScreenIsOpen();

      api.thenTheComingSoonNodeShouldBeShown();
    });

    testWidgets('should_unlock_hex_2_when_hex_1_is_completed', (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenHexLevelIsCompleted('hex_1', stars: 3);
      await api.givenTheHexScreenIsOpen();

      // hex_1 completado (check), hex_2 pasa a jugable, hex_3 sigue bloqueado
      // -> un solo candado.
      api.thenLockIconsShouldBeShown(count: 1);
    });

    testWidgets('should_unlock_hex_3_when_hex_1_and_hex_2_are_completed',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenHexLevelIsCompleted('hex_1', stars: 3);
      await api.givenHexLevelIsCompleted('hex_2', stars: 2);
      await api.givenTheHexScreenIsOpen();

      // Progresión completa hex_1 -> hex_2 -> hex_3: ningún candado.
      api.thenLockIconsShouldBeShown(count: 0);
    });
  });

  group('HexLevelSelectScreen — interaction', () {
    testWidgets('should_not_navigate_when_a_locked_level_is_tapped',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenTheHexScreenIsOpen();

      await api.whenHexTileIsTapped(2);

      api.thenTheHexScreenShouldBeShown();
    });

    testWidgets('should_not_navigate_when_the_coming_soon_node_is_tapped',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenTheHexScreenIsOpen();

      await api.whenComingSoonNodeIsTapped();

      api.thenTheHexScreenShouldBeShown();
    });
  });

  group('HexLevelSelectScreen — navigation', () {
    testWidgets('should_navigate_to_game_screen_when_unlocked_level_is_tapped',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2')
        ..givenAHexLevel('hex_3');
      await api.givenTheHexScreenIsOpen();

      await api.whenHexTileIsTapped(1);

      api.thenTheGameScreenShouldBeShown();
    });
  });
}
