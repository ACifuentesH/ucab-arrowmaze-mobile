import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/hex_level_select_screen_test_api.dart';

void main() {
  group('HexLevelSelectScreen — render', () {
    testWidgets(
        'should_show_two_levels_with_hex_2_locked_when_no_progress',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2');
      await api.givenTheHexScreenIsOpen();

      // Ambas tarjetas presentes; hex_1 desbloqueado (primero), hex_2 bloqueado
      // porque hex_1 aún no se completó → exactamente un candado.
      api
        ..thenHexTileShouldExist(1)
        ..thenHexTileShouldExist(2)
        ..thenLockIconsShouldBeShown(count: 1);
    });

    testWidgets(
        'should_unlock_hex_2_when_hex_1_is_completed',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2');
      await api.givenHexLevelIsCompleted('hex_1', stars: 3);
      await api.givenTheHexScreenIsOpen();

      // hex_1 completado (check, sin candado) y hex_2 pasa a jugable → ningún
      // candado en pantalla.
      api.thenLockIconsShouldBeShown(count: 0);
    });
  });

  group('HexLevelSelectScreen — interaction', () {
    testWidgets(
        'should_not_navigate_when_a_locked_level_is_tapped',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2');
      await api.givenTheHexScreenIsOpen();

      await api.whenHexTileIsTapped(2);

      api.thenTheHexScreenShouldBeShown();
    });
  });

  group('HexLevelSelectScreen — navigation', () {
    testWidgets(
        'should_navigate_to_game_screen_when_unlocked_level_is_tapped',
        (tester) async {
      final api = HexLevelSelectScreenTestApi(tester);
      api
        ..givenAHexLevel('hex_1')
        ..givenAHexLevel('hex_2');
      await api.givenTheHexScreenIsOpen();

      await api.whenHexTileIsTapped(1);

      api.thenTheGameScreenShouldBeShown();
    });
  });
}
