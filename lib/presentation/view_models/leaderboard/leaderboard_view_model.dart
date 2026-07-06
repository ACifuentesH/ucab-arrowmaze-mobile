import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';

/// STUB — feature/leaderboard (compañera): estados loading/empty/error/data.
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

/// STUB — feature/leaderboard (compañera).
class LeaderboardViewModel extends StateNotifier<LeaderboardState> {
  // ignore: unused_field
  final GetLeaderboardUseCase _getLeaderboard;

  LeaderboardViewModel({required GetLeaderboardUseCase getLeaderboard})
      : _getLeaderboard = getLeaderboard,
        super(const LeaderboardState());

  // TODO(feature/leaderboard): Future<void> load(String levelId, {int limit})
}
