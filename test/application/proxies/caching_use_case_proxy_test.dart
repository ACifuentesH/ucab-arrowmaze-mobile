import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/caching_use_case_proxy_test_api.dart';

void main() {
  group('CachingUseCaseProxy (decorator AOP)', () {
    test('should_call_the_wrapped_use_case_when_first_invoked', () async {
      final api = CachingProxyTestApi().givenTheLeaderboardHasEntries();

      await api.whenTheLeaderboardIsRequested();

      api
        ..thenTheWrappedUseCaseShouldHaveBeenCalled(1)
        ..thenTheResultShouldBeTheLeaderboard();
    });

    test('should_return_cached_result_when_called_twice_within_ttl', () async {
      final api = CachingProxyTestApi().givenTheLeaderboardHasEntries();

      await api.whenTheLeaderboardIsRequested();
      await api.whenTheLeaderboardIsRequested();

      api
        ..thenTheWrappedUseCaseShouldHaveBeenCalled(1)
        ..thenTheResultShouldBeTheLeaderboard();
    });

    test('should_call_the_wrapped_use_case_again_when_ttl_expires', () async {
      final api = CachingProxyTestApi().givenTheLeaderboardHasEntries();

      await api.whenTheLeaderboardIsRequested();
      api.whenTheTtlExpires();
      await api.whenTheLeaderboardIsRequested();

      api.thenTheWrappedUseCaseShouldHaveBeenCalled(2);
    });

    test('should_fetch_fresh_data_after_cache_invalidation', () async {
      final api = CachingProxyTestApi().givenTheLeaderboardHasEntries();

      await api.whenTheLeaderboardIsRequested();
      api.whenTheLeaderboardCacheIsInvalidated();
      await api.whenTheLeaderboardIsRequested();

      api.thenTheWrappedUseCaseShouldHaveBeenCalled(2);
    });
  });
}
