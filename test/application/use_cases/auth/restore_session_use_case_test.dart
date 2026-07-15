import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/auth_test_api.dart';

void main() {
  group('RestoreSessionUseCase', () {
    test('should_return_user_when_repository_has_stored_session', () async {
      (await AuthTestApi()
              .givenAStoredSessionExists()
              .whenRestoringSession())
          .thenRestoredUserShouldBeAlice();
    });

    test('should_return_null_when_repository_has_no_stored_session', () async {
      (await AuthTestApi().givenNoStoredSession().whenRestoringSession())
          .thenRestoredUserShouldBeAbsent();
    });
  });
}
