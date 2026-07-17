import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/errors/api_error.dart';

import '../../_support/apis/api_client_test_api.dart';
import '../../_support/mothers/api_response_mother.dart';

void main() {
  group('HttpApiClient — auth', () {
    test('should_store_token_and_normalize_user_when_registering', () async {
      (await ApiClientTestApi()
              .givenServerResponds(201, ApiResponseMother.registerSuccess())
              .whenRegistering())
          ..thenRequestShouldBe('POST', '/auth/register')
          ..thenSessionUserIdShouldBe('u-1') // viene como user.id
          ..thenTokenShouldBeStored('jwt-register');
    });

    test('should_normalize_user_id_when_logging_in', () async {
      (await ApiClientTestApi()
              .givenServerResponds(200, ApiResponseMother.loginSuccess())
              .whenLoggingIn())
          ..thenSessionUserIdShouldBe('u-1') // viene como user.userId
          ..thenTokenShouldBeStored('jwt-login');
    });

    test('should_send_no_authorization_header_when_authenticating', () async {
      (await ApiClientTestApi()
              .givenServerResponds(200, ApiResponseMother.loginSuccess())
              .whenLoggingIn())
          .thenNoAuthorizationHeaderShouldBeSent();
    });

    test('should_clear_stored_token_when_logging_out', () async {
      (await ApiClientTestApi().givenAStoredToken().whenLoggingOut())
          ..thenNoErrorShouldOccur()
          ..thenTokenShouldBeCleared();
    });

    test('should_fail_with_unauthorized_when_credentials_are_rejected',
        () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  401, ApiResponseMother.error('Invalid credentials'))
              .whenLoggingIn())
          .thenErrorShouldBe<UnauthorizedError>();
    });

    test('should_fail_with_conflict_when_email_is_taken', () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  409, ApiResponseMother.error('Email already registered'))
              .whenRegistering())
          .thenErrorShouldBe<ConflictError>();
    });

    test('should_fail_with_validation_error_when_body_is_invalid', () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  422, ApiResponseMother.error('password too short'))
              .whenRegistering())
          .thenErrorShouldBe<ValidationError>();
    });

    test(
        'should_map_400_email_details_to_invalid_email_validation_code',
        () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                400,
                ApiResponseMother.validationErrorWithEmailDetails(),
              )
              .whenLoggingIn())
        ..thenErrorShouldBe<ValidationError>()
        ..thenErrorMessageShouldBe('invalid_email');
    });

    test('should_fail_with_server_error_when_backend_breaks', () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  500, ApiResponseMother.error('Internal server error'))
              .whenLoggingIn())
          .thenErrorShouldBe<ServerError>();
    });
  });

  group('HttpApiClient — progress (JWT)', () {
    test('should_attach_bearer_token_when_getting_progress', () async {
      (await ApiClientTestApi()
              .givenAStoredToken('stored-jwt')
              .givenServerResponds(200, ApiResponseMother.progress())
              .whenGettingProgress())
          ..thenRequestShouldBe('GET', '/progress')
          ..thenAuthorizationHeaderShouldBe('Bearer stored-jwt')
          ..thenProgressUserIdShouldBe('u-1')
          ..thenProgressBestScoreShouldBe('level_1', 900);
    });

    test('should_fail_with_unauthorized_when_no_token_is_stored', () async {
      (await ApiClientTestApi()
              .givenServerResponds(200, ApiResponseMother.progress())
              .whenGettingProgress())
          .thenErrorShouldBe<UnauthorizedError>();
    });

    test('should_fail_with_not_found_when_user_has_no_progress_yet',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(
                  404, ApiResponseMother.error('Progress not found'))
              .whenGettingProgress())
          .thenErrorShouldBe<NotFoundError>();
    });

    test('should_include_leaderboard_fields_when_putting_completed_progress',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(200, ApiResponseMother.progress())
              .whenPuttingCompletedLevelProgress())
          ..thenRequestShouldBe('PUT', '/progress')
          ..thenRequestBodyFieldShouldBe('lastLevelId', 'level_1')
          ..thenRequestBodyFieldShouldBe('lastScore', 950);
    });

    test('should_omit_last_fields_when_putting_minimal_progress', () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(200, ApiResponseMother.progress())
              .whenPuttingMinimalProgress())
          ..thenRequestBodyShouldNotContain('lastLevelId')
          ..thenRequestBodyShouldNotContain('lastScore');
    });
  });

  group('HttpApiClient — leaderboard', () {
    test('should_parse_entries_when_ranking_exists', () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  200, ApiResponseMother.leaderboardWithOneEntry(score: 950))
              .whenGettingLeaderboard())
          ..thenRequestShouldBe('GET', '/leaderboard/level_1?limit=10')
          ..thenLeaderboardShouldHaveEntries(1)
          ..thenFirstLeaderboardScoreShouldBe(950);
    });

    test('should_return_empty_list_when_ranking_is_empty', () async {
      (await ApiClientTestApi()
              .givenServerResponds(200, ApiResponseMother.emptyLeaderboard())
              .whenGettingLeaderboard())
          .thenLeaderboardShouldHaveEntries(0);
    });
  });

  group('HttpApiClient — levels (contrato)', () {
    test('should_parse_level_list_when_getting_levels', () async {
      (await ApiClientTestApi()
              .givenServerResponds(200, ApiResponseMother.levelsList())
              .whenGettingLevels())
          ..thenRequestShouldBe('GET', '/levels')
          ..thenLevelsShouldHaveIds(['level_1']);
    });

    test('should_follow_the_level_contract_when_getting_a_level_by_id',
        () async {
      (await ApiClientTestApi()
              .givenServerResponds(200, ApiResponseMother.levelDto())
              .whenGettingLevelById('level_1'))
          ..thenRequestShouldBe('GET', '/levels/level_1')
          ..thenLevelShouldFollowContract();
    });

    test('should_fail_with_not_found_when_level_does_not_exist', () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  404, ApiResponseMother.error('Level not found'))
              .whenGettingLevelById('nope'))
          .thenErrorShouldBe<NotFoundError>();
    });
  });

  group('HttpApiClient — AI level generation', () {
    test('should_post_prompt_and_difficulty_when_generating_a_level',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(
                  200, ApiResponseMother.generatedLevelData())
              .whenGeneratingLevel(shapeName: 'a heart'))
          ..thenRequestShouldBe('POST', '/levels/generate')
          ..thenRequestBodyFieldShouldContain('prompt', 'a heart')
          ..thenRequestBodyFieldShouldContain('prompt', '16x16 grid')
          ..thenRequestBodyFieldShouldContain('prompt', 'will be discarded')
          ..thenRequestBodyFieldShouldBe('difficulty', 'medium');
    });

    test(
        'should_translate_the_shape_to_the_origin_when_the_model_draws_it_off_center',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(
                  200, ApiResponseMother.generatedLevelDataOffOrigin())
              .whenGeneratingLevel())
          .thenGeneratedLevelCellsShouldBe([
        [0, 0],
        [0, 1],
        [1, 0],
      ]);
    });

    test('should_send_authorization_header_when_generating_a_level',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken('jwt-generate')
              .givenServerResponds(
                  200, ApiResponseMother.generatedLevelData())
              .whenGeneratingLevel())
          .thenAuthorizationHeaderShouldBe('Bearer jwt-generate');
    });

    test(
        'should_build_a_level_definition_from_the_backend_blob_when_generating',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(
                  200, ApiResponseMother.generatedLevelData())
              .whenGeneratingLevel(shapeName: 'a heart'))
          ..thenLevelShouldFollowContract()
          ..thenGeneratedLevelNameShouldBe('a heart');
    });

    test(
        'should_use_the_spec_lives_and_not_the_backend_ones_when_generating',
        () async {
      // El mother devuelve lives:5, pero el spec (dificultad media) manda
      // 3 vidas — igual que el adaptador anterior, el backend nunca decide
      // el balance del juego.
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(
                  200, ApiResponseMother.generatedLevelData())
              .whenGeneratingLevel(difficulty: Difficulty.medium))
          .thenGeneratedLevelLivesShouldBe(3);
    });

    test('should_require_a_stored_token_when_generating_a_level', () async {
      (await ApiClientTestApi()
              .givenServerResponds(
                  200, ApiResponseMother.generatedLevelData())
              .whenGeneratingLevel())
          .thenErrorShouldBe<UnauthorizedError>();
    });

    test('should_fail_with_server_error_when_the_llm_fails_upstream',
        () async {
      (await ApiClientTestApi()
              .givenAStoredToken()
              .givenServerResponds(
                  502, ApiResponseMother.error('Failed to generate level'))
              .whenGeneratingLevel())
          .thenErrorShouldBe<ServerError>();
    });
  });
}
