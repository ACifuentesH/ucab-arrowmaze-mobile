import 'package:arrow_maze/application/dtos/submit_survival_input.dart';
import 'package:arrow_maze/application/dtos/survival_entry_dto.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_survival_repository.dart';

class SurvivalRepositoryImpl implements ISurvivalRepository {
  final IApiClient _api;

  const SurvivalRepositoryImpl({required IApiClient api}) : _api = api;

  @override
  Future<void> submitRun(SubmitSurvivalInput input) {
    // El backend (422) rechaza claves con valor null (p. ej. totalScore).
    final body = Map<String, dynamic>.from(input.toJson());
    body.removeWhere((_, value) => value == null);
    return _api.submitSurvival(body);
  }

  @override
  Future<List<SurvivalEntryDto>> getLeaderboard({
    required int durationSeconds,
    int limit = 10,
  }) =>
      _api.getSurvivalLeaderboard(
        durationSeconds: durationSeconds,
        limit: limit,
      );
}
