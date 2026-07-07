import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/load_level_test_api.dart';

void main() {
  group('LoadLevelUseCase', () {
    test('should_return_a_playable_board_when_level_exists', () async {
      (await LoadLevelTestApi()
              .givenARepositoryWithLevel('level_01')
              .whenLevelIsLoaded('level_01'))
          ..thenBoardShouldBeReady()
          ..thenBoardShouldHaveArrows(1);
    });

    test('should_request_the_level_by_its_id_when_loading', () async {
      (await LoadLevelTestApi()
              .givenARepositoryWithLevel('level_01')
              .whenLevelIsLoaded('level_01'))
          .thenRequestedLevelShouldBe('level_01');
    });

    test('should_fail_when_level_does_not_exist', () async {
      (await LoadLevelTestApi()
              .givenAnEmptyRepository()
              .whenLevelIsLoaded('missing'))
          .thenLoadShouldFail();
    });
  });
}
