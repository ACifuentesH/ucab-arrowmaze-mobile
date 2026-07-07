import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/generate_level_test_api.dart';

void main() {
  group('GenerateLevelUseCase', () {
    test('should_return_a_preview_and_persist_it_when_level_is_valid',
        () async {
      final api = await GenerateLevelTestApi()
          .givenAGeneratorThatReturnsAValidLevel()
          .whenLevelIsGenerated();
      api.thenAPreviewShouldBeReturned();
      await api.thenLevelShouldBePersisted('generated_1');
    });

    test('should_retry_once_when_first_generation_fails', () async {
      final api = await GenerateLevelTestApi()
          .givenAGeneratorThatFailsOnceThenSucceeds()
          .whenLevelIsGenerated();
      api
        ..thenAPreviewShouldBeReturned()
        ..thenGeneratorShouldHaveBeenAskedTimes(2);
    });

    test('should_fail_and_persist_nothing_when_both_attempts_are_unplayable',
        () async {
      final api = await GenerateLevelTestApi()
          .givenAGeneratorThatReturnsAnUnplayableLevelTwice()
          .whenLevelIsGenerated();
      api
        ..thenGenerationShouldFail()
        ..thenGeneratorShouldHaveBeenAskedTimes(2);
      await api.thenNothingShouldBePersisted();
    });
  });
}
