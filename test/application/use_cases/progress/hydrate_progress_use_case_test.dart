import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/hydrate_progress_test_api.dart';

void main() {
  group('HydrateProgressUseCase', () {
    test('should_overwrite_local_progress_when_remote_progress_exists',
        () async {
      final api = HydrateProgressTestApi();
      await api.givenStaleLocalProgress();
      api.givenRemoteProgressExists();
      await api.whenHydrating();
      await api.thenLocalProgressShouldMatchRemote();
    });

    test('should_clear_local_progress_when_server_returns_404_for_new_user',
        () async {
      final api = HydrateProgressTestApi();
      await api.givenStaleLocalProgress();
      api.givenNewUserWithoutProgress();
      await api.whenHydrating();
      await api.thenLocalProgressShouldBeEmpty();
    });

    test('should_swallow_network_error_and_keep_local_progress', () async {
      final api = HydrateProgressTestApi();
      await api.givenStaleLocalProgress();
      api.givenNetworkFails();
      await api.whenHydrating();
      await api.thenHydrationShouldSwallowErrorAndKeepLocal();
    });
  });
}
