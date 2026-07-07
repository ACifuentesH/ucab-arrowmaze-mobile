import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/save_progress_test_api.dart';

void main() {
  group('SaveProgressUseCase', () {
    test('should_persist_progress_when_a_level_is_completed', () async {
      final api = await SaveProgressTestApi()
          .whenACompletedLevelIsSaved(levelId: 'level_1', bestScore: 900);
      await api.thenProgressShouldBeStored('level_1', bestScore: 900);
    });

    test('should_overwrite_progress_when_the_same_level_is_saved_again',
        () async {
      final api = await SaveProgressTestApi()
          .whenACompletedLevelIsSaved(levelId: 'level_1', bestScore: 900);
      await api.whenACompletedLevelIsSaved(levelId: 'level_1', bestScore: 950);
      await api.thenProgressShouldBeStored('level_1', bestScore: 950);
      await api.thenStoredLevelsShouldBe(1);
    });
  });
}
