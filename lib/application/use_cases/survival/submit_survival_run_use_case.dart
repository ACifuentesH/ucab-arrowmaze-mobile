import 'package:arrow_maze/application/dtos/submit_survival_input.dart';
import 'package:arrow_maze/application/ports/i_survival_repository.dart';

class SubmitSurvivalRunUseCase {
  final ISurvivalRepository _repository;

  const SubmitSurvivalRunUseCase({required ISurvivalRepository repository})
      : _repository = repository;

  Future<void> execute(SubmitSurvivalInput input) =>
      _repository.submitRun(input);
}
