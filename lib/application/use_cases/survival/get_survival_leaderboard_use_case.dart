import 'package:arrow_maze/application/dtos/survival_entry_dto.dart';
import 'package:arrow_maze/application/ports/i_survival_repository.dart';

class GetSurvivalLeaderboardUseCase {
  final ISurvivalRepository _repository;

  const GetSurvivalLeaderboardUseCase({
    required ISurvivalRepository repository,
  }) : _repository = repository;

  Future<List<SurvivalEntryDto>> execute({
    required int durationSeconds,
    int limit = 10,
  }) =>
      _repository.getLeaderboard(
        durationSeconds: durationSeconds,
        limit: limit,
      );
}
