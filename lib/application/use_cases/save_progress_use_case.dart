import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';

class SaveProgressUseCase {
  final IPlayerProgressRepository _repository;

  const SaveProgressUseCase({required IPlayerProgressRepository repository})
      : _repository = repository;

  Future<void> execute(LevelProgress progress) => _repository.save(progress);
}
