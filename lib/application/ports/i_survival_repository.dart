import 'package:arrow_maze/application/dtos/submit_survival_input.dart';
import 'package:arrow_maze/application/dtos/survival_entry_dto.dart';

abstract interface class ISurvivalRepository {
  Future<void> submitRun(SubmitSurvivalInput input);

  Future<List<SurvivalEntryDto>> getLeaderboard({
    required int durationSeconds,
    int limit = 10,
  });
}
