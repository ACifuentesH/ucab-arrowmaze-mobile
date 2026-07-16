import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';

import '../../_support/apis/api_level_generator_test_api.dart';
import '../../_support/mothers/level_definition_mother.dart';

void main() {
  setUpAll(ApiLevelGeneratorTestApi.registerFallbacks);

  group('ApiLevelGeneratorService (adapter → backend)', () {
    test('should_delegate_to_the_api_client_with_the_spec_when_generating',
        () async {
      final level = LevelDefinitionMother.withEscapableArrow();
      (await ApiLevelGeneratorTestApi()
              .givenTheBackendReturns(level)
              .whenGenerating())
          .thenTheApiClientShouldHaveBeenCalledWithTheSpec();
    });

    test('should_return_the_backend_level_when_generation_succeeds',
        () async {
      final level = LevelDefinitionMother.withEscapableArrow();
      (await ApiLevelGeneratorTestApi()
              .givenTheBackendReturns(level)
              .whenGenerating())
          .thenTheResultShouldBe(level);
    });

    test(
        'should_translate_unauthorized_into_a_friendly_login_message_when_generating',
        () async {
      (await ApiLevelGeneratorTestApi()
              .givenTheBackendFailsWith(
                  const UnauthorizedError('No stored session token'))
              .whenGenerating())
        ..thenItShouldFailWith<LevelGenerationException>()
        ..thenTheErrorMessageShouldBe(
            'Inicia sesión para generar niveles con IA.');
    });

    test('should_wrap_any_other_api_error_as_a_level_generation_exception',
        () async {
      (await ApiLevelGeneratorTestApi()
              .givenTheBackendFailsWith(
                  const ServerError('Failed to generate level'))
              .whenGenerating())
        ..thenItShouldFailWith<LevelGenerationException>()
        ..thenTheErrorMessageShouldBe('Failed to generate level');
    });
  });
}
