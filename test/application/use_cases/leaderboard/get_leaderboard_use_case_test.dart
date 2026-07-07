import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/leaderboard_test_api.dart';

void main() {
  group('GetLeaderboardUseCase', () {
    test('should_return_ranked_entries_when_level_has_scores', () async {
      (await LeaderboardTestApi()
              .givenARankingWithScores([950, 900])
              .whenLeaderboardIsRequested())
          .thenScoresShouldBe([950, 900]);
    });

    test('should_return_empty_ranking_when_level_has_no_scores', () async {
      (await LeaderboardTestApi()
              .givenAnEmptyRanking()
              .whenLeaderboardIsRequested())
          .thenRankingShouldBeEmpty();
    });

    test('should_request_the_given_level_and_limit_when_fetching', () async {
      (await LeaderboardTestApi()
              .givenAnEmptyRanking()
              .whenLeaderboardIsRequested(levelId: 'level_7', limit: 5))
          .thenRequestShouldTarget('level_7', limit: 5);
    });
  });
}
