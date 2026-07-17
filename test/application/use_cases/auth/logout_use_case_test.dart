import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/auth_test_api.dart';

void main() {
  group('LogoutUseCase', () {
    test('should_close_the_session_when_logging_out', () async {
      (await AuthTestApi().givenALocalSessionExists().whenLoggingOut())
          .thenSessionShouldBeClosed();
    });

    test('should_clear_local_progress_when_logging_out', () async {
      final api = await AuthTestApi().givenALocalSessionWithProgress();
      await api.whenLoggingOut();
      api.thenSessionShouldBeClosed();
      await api.thenLocalProgressShouldBeEmpty();
      await api.thenUserStorageShouldBeCleared();
    });
  });
}
