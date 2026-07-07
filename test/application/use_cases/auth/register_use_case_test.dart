import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/errors/api_error.dart';

import '../../../_support/apis/auth_test_api.dart';

void main() {
  group('RegisterUseCase', () {
    test('should_open_a_session_when_registration_succeeds', () async {
      (await AuthTestApi().givenApiAcceptsCredentials().whenRegistering())
          .thenSessionShouldBeActiveFor('u-1');
    });

    test('should_fail_with_conflict_when_email_is_already_registered',
        () async {
      (await AuthTestApi().givenEmailIsAlreadyRegistered().whenRegistering())
          .thenAuthShouldFailWith<ConflictError>();
    });
  });
}
