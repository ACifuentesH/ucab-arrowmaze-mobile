import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/errors/api_error.dart';

import '../../../_support/apis/auth_test_api.dart';

void main() {
  group('LoginUseCase', () {
    test('should_open_a_session_when_credentials_are_valid', () async {
      (await AuthTestApi().givenAuthAcceptsCredentials().whenLoggingIn())
          .thenUserShouldBeActiveWithId('u-1');
    });

    test('should_fail_with_unauthorized_when_credentials_are_invalid',
        () async {
      (await AuthTestApi().givenAuthRejectsCredentials().whenLoggingIn())
          .thenAuthShouldFailWith<UnauthorizedError>();
    });
  });
}
