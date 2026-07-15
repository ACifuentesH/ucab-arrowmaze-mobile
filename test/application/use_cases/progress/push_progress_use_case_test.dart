import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/push_progress_test_api.dart';

void main() {
  group('PushProgressUseCase', () {
    test('should_send_leaderboard_fields_when_authenticated_level_completes',
        () async {
      final api = PushProgressTestApi();
      await api.givenLocalProgressExists();
      (await api
              .givenAnAuthenticatedSession()
              .givenTheServerAcceptsUpdates()
              .whenLevelCompletionIsPushed())
          .thenPushShouldIncludeLeaderboardFields();
    });

    test('should_skip_remote_push_when_there_is_no_session', () async {
      final api = PushProgressTestApi();
      await api.givenLocalProgressExists();
      (await api
              .givenNoSession()
              .givenTheServerAcceptsUpdates()
              .whenLevelCompletionIsPushed())
          .thenNoRequestShouldBeSent();
    });

    test('should_swallow_server_errors_without_failing_the_caller', () async {
      final api = PushProgressTestApi();
      await api.givenLocalProgressExists();
      (await api
              .givenAnAuthenticatedSession()
              .givenTheServerFails()
              .whenLevelCompletionIsPushed())
          .thenErrorShouldBeSwallowed();
    });

    test('should_swallow_network_errors_without_failing_the_caller', () async {
      final api = PushProgressTestApi();
      await api.givenLocalProgressExists();
      (await api
              .givenAnAuthenticatedSession()
              .givenNetworkFails()
              .whenLevelCompletionIsPushed())
          .thenErrorShouldBeSwallowed();
    });
  });
}
