import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/survival_entry_dto.dart';
import 'package:arrow_maze/config/providers.dart';

/// Top 10 del ranking de supervivencia (partidas de 120 s).
final survivalLeaderboardProvider =
    FutureProvider.autoDispose<List<SurvivalEntryDto>>((ref) {
  return ref.read(getSurvivalLeaderboardUseCaseProvider).execute(
        durationSeconds: 120,
        limit: 10,
      );
});
