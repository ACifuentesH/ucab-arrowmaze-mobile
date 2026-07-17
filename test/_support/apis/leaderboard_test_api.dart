import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';

import '../mothers/leaderboard_entry_mother.dart';

class _MockApiClient extends Mock implements IApiClient {}

/// Testing API: consulta del ranking por nivel vía IApiClient (mock:
/// la llamada al backend es el comportamiento observable).
class LeaderboardTestApi {
  final _MockApiClient _api = _MockApiClient();
  List<LeaderboardEntryDto>? _entries;

  LeaderboardTestApi givenARankingWithScores(List<int> scores) {
    when(() => _api.getLeaderboard(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async =>
            [for (final s in scores) LeaderboardEntryMother.entry(score: s)]);
    return this;
  }

  LeaderboardTestApi givenAnEmptyRanking() {
    when(() => _api.getLeaderboard(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => const []);
    return this;
  }

  Future<LeaderboardTestApi> whenLeaderboardIsRequested({
    String levelId = 'level_1',
    int limit = 10,
  }) async {
    _entries = await GetLeaderboardUseCase(api: _api)
        .execute(levelId, limit: limit);
    return this;
  }

  void thenScoresShouldBe(List<int> scores) =>
      expect(_entries!.map((e) => e.score).toList(), equals(scores));

  void thenRankingShouldBeEmpty() => expect(_entries, isEmpty);

  void thenRequestShouldTarget(String levelId, {required int limit}) =>
      verify(() => _api.getLeaderboard(levelId, limit: limit)).called(1);
}
