import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/load_level_test_api.dart';

void main() {
  group('RestartLevelUseCase', () {
    test('should_restore_all_arrows_when_level_is_restarted', () async {
      (await LoadLevelTestApi()
              .givenARepositoryWithLevel('level_01')
              .whenLevelIsRestartedAfterAMove('level_01'))
          ..thenBoardShouldBeReady()
          ..thenBoardShouldHaveArrows(1);
    });

    test('should_clear_undo_history_when_level_is_restarted', () async {
      (await LoadLevelTestApi()
              .givenARepositoryWithLevel('level_01')
              .whenLevelIsRestartedAfterAMove('level_01'))
          .thenUndoHistoryShouldBeEmpty();
    });
  });
}
