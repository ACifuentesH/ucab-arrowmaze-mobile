import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/logger_proxy_test_api.dart';

void main() {
  group('UseCaseLoggerProxy (decorator AOP)', () {
    test('should_delegate_the_tap_when_executed', () {
      LoggerProxyTestApi()
          .givenDelegateWillReport(true)
          .whenArrowIsTapped('a1')
          .thenDelegateShouldHandleTheTap('a1');
    });

    test('should_passthrough_success_when_delegate_accepts_the_move', () {
      LoggerProxyTestApi()
          .givenDelegateWillReport(true)
          .whenArrowIsTapped('a1')
          .thenResultShouldBe(true);
    });

    test('should_passthrough_failure_when_delegate_rejects_the_move', () {
      LoggerProxyTestApi()
          .givenDelegateWillReport(false)
          .whenArrowIsTapped('a1')
          .thenResultShouldBe(false);
    });
  });
}
