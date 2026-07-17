import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/sync_progress_test_api.dart';

void main() {
  group('SyncProgressUseCase', () {
    test('should_return_remote_progress_when_it_exists', () async {
      (await SyncProgressTestApi()
              .givenARemoteProgressExists()
              .whenProgressIsPulled())
          .thenProgressShouldBeAvailable();
    });

    test('should_treat_missing_progress_as_new_user_when_server_returns_404',
        () async {
      (await SyncProgressTestApi()
              .givenANewUserWithoutProgress()
              .whenProgressIsPulled())
          .thenResultShouldBeNoProgressYet();
    });

    test('should_send_leaderboard_fields_when_a_completed_level_is_pushed',
        () async {
      (await SyncProgressTestApi()
              .givenTheServerAcceptsUpdates()
              .whenACompletedLevelIsPushed())
          .thenUpdateShouldReachTheServerWithLeaderboardFields();
    });
  });
}
