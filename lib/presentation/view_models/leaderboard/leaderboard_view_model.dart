import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';

/// Estados loading / empty / error / data del ranking por nivel.
class LeaderboardState {
  final List<LeaderboardEntryDto> entries;
  final bool isLoading;
  final String? errorMessage;

  const LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => !isLoading && errorMessage == null && entries.isEmpty;
}

class LeaderboardViewModel extends StateNotifier<LeaderboardState> {
  final GetLeaderboardUseCase _getLeaderboard;

  LeaderboardViewModel({required GetLeaderboardUseCase getLeaderboard})
      : _getLeaderboard = getLeaderboard,
        super(const LeaderboardState());

  Future<void> load(String levelId, {int limit = 10}) async {
    state = const LeaderboardState(isLoading: true);

    try {
      final data = await _getLeaderboard.execute(levelId, limit: limit);
      state = LeaderboardState(entries: data);
    } on ApiError catch (e) {
      state = LeaderboardState(errorMessage: e.message);
    } catch (e) {
      state = LeaderboardState(errorMessage: e.toString());
    }
  }
}
