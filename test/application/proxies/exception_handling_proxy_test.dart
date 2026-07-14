import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/errors/api_error.dart';

import '../../_support/apis/exception_handling_proxy_test_api.dart';

void main() {
  group('ExceptionHandlingApiClientProxy (decorator AOP)', () {
    test('should_map_network_error_to_typed_api_error_when_request_fails',
        () async {
      await ExceptionHandlingProxyTestApi()
          .givenTheDelegateAlwaysThrows(Exception('socket closed'))
          .thenItShouldThrowA<NetworkError>();
    });

    test('should_rethrow_the_typed_api_error_when_delegate_already_maps_it',
        () async {
      await ExceptionHandlingProxyTestApi()
          .givenTheDelegateAlwaysThrows(const NotFoundError('no such level'))
          .thenItShouldThrowA<NotFoundError>();
    });

    test('should_not_retry_when_error_is_deterministic', () async {
      final api = ExceptionHandlingProxyTestApi()
          .givenRetriesAreEnabled(3)
          .givenTheDelegateAlwaysThrows(const ValidationError('bad input'));

      await api.thenItShouldThrowA<ValidationError>();

      api.thenTheDelegateShouldHaveBeenCalled(1);
    });

    test(
        'should_retry_and_succeed_when_first_attempt_hits_a_transient_network_error',
        () async {
      final api = ExceptionHandlingProxyTestApi()
          .givenRetriesAreEnabled(2)
          .givenTheDelegateThrowsThenSucceeds(const NetworkError('timeout'));

      await api.whenTheLeaderboardIsRequested();

      api
        ..thenTheResultShouldNotBeNull()
        ..thenTheDelegateShouldHaveBeenCalled(2);
    });

    test('should_stop_retrying_and_throw_when_network_error_persists',
        () async {
      final api = ExceptionHandlingProxyTestApi()
          .givenRetriesAreEnabled(2)
          .givenTheDelegateAlwaysThrows(const NetworkError('offline'));

      await api.thenItShouldThrowA<NetworkError>();

      api.thenTheDelegateShouldHaveBeenCalled(2);
    });
  });
}
