import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/restore_session_test_api.dart';

void main() {
  group('RestoreSessionUseCase', () {
    test('should_restore_user_when_token_and_user_exist', () async {
      final api =
          await RestoreSessionTestApi().givenAStoredTokenAndUser(userId: 'u-1');
      await api.whenRestoringTheSession();

      api.thenSessionShouldBeRestoredFor('u-1');
    });

    test('should_return_null_and_clear_token_when_user_is_missing', () async {
      final api = RestoreSessionTestApi().givenAStoredTokenWithoutAUser();
      await api.whenRestoringTheSession();

      api.thenSessionShouldBeNull();
      api.thenTokenShouldBeCleared();
    });

    test('should_return_null_when_no_token_exists', () async {
      final api = RestoreSessionTestApi().givenNoStoredToken();
      await api.whenRestoringTheSession();

      api.thenSessionShouldBeNull();
      api.thenTokenShouldNotBeCleared();
    });
  });
}
