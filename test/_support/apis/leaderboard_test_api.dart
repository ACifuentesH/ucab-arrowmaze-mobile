import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/ports/i_leaderboard_repository.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';

import '../mothers/leaderboard_entry_mother.dart';

class MockLeaderboardRepository extends Mock implements ILeaderboardRepository {}

/// Testing API: consulta del ranking por nivel vía [ILeaderboardRepository].
class LeaderboardTestApi {
  final MockLeaderboardRepository _leaderboard = MockLeaderboardRepository();
  List<LeaderboardEntryDto>? _entries;

  LeaderboardTestApi givenARankingWithScores(List<int> scores) {
    when(() => _leaderboard.getLeaderboard(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async =>
            [for (final s in scores) LeaderboardEntryMother.entry(score: s)]);
    return this;
  }

  LeaderboardTestApi givenAnEmptyRanking() {
    when(() => _leaderboard.getLeaderboard(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => const []);
    return this;
  }

  Future<LeaderboardTestApi> whenLeaderboardIsRequested({
    String levelId = 'level_1',
    int limit = 10,
  }) async {
    _entries = await GetLeaderboardUseCase(leaderboard: _leaderboard)
        .execute(levelId, limit: limit);
    return this;
  }

  void thenScoresShouldBe(List<int> scores) =>
      expect(_entries!.map((e) => e.score).toList(), equals(scores));

  void thenRankingShouldBeEmpty() => expect(_entries, isEmpty);

  void thenRequestShouldTarget(String levelId, {required int limit}) =>
      verify(() => _leaderboard.getLeaderboard(levelId, limit: limit)).called(1);
}
