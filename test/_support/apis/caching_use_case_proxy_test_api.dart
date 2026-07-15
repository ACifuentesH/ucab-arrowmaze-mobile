import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/proxies/caching_use_case_proxy.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';

import '../mothers/leaderboard_entry_mother.dart';

class _MockGetLeaderboardUseCase extends Mock
    implements GetLeaderboardUseCase {}

/// Testing API: proxy de caché con TTL (decorator AOP). Aquí el mock es
/// legítimo: lo observable es SI el caso de uso envuelto se invoca o se sirve
/// desde caché. El reloj se controla para expirar el TTL sin esperas reales.
class CachingProxyTestApi {
  static const _ttl = Duration(seconds: 30);
  static const _levelId = 'level_1';

  final _MockGetLeaderboardUseCase _delegate = _MockGetLeaderboardUseCase();
  DateTime _clock = DateTime.utc(2026, 1, 1, 12);
  late final CachingUseCaseProxy _proxy = CachingUseCaseProxy(
    delegate: _delegate,
    ttl: _ttl,
    clock: () => _clock,
  );

  late List<LeaderboardEntryDto> _delegateResult;
  List<LeaderboardEntryDto>? _result;

  CachingProxyTestApi givenTheLeaderboardHasEntries() {
    _delegateResult = [
      LeaderboardEntryMother.entry(username: 'alice', score: 950),
      LeaderboardEntryMother.entry(username: 'bob', score: 800),
    ];
    when(() => _delegate.execute(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => _delegateResult);
    return this;
  }

  Future<CachingProxyTestApi> whenTheLeaderboardIsRequested() async {
    _result = await _proxy.execute(_levelId);
    return this;
  }

  CachingProxyTestApi whenTheTtlExpires() {
    _clock = _clock.add(_ttl + const Duration(seconds: 1));
    return this;
  }

  void thenTheWrappedUseCaseShouldHaveBeenCalled(int times) =>
      verify(() => _delegate.execute(any(), limit: any(named: 'limit')))
          .called(times);

  void thenTheResultShouldBeTheLeaderboard() =>
      expect(_result, equals(_delegateResult));
}
