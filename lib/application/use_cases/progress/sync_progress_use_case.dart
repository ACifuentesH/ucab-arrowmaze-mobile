import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_progress_repository.dart';

/// Sincronización de progreso con el backend.
class SyncProgressUseCase {
  final IProgressRepository _progress;

  const SyncProgressUseCase({required IProgressRepository progress})
      : _progress = progress;

  Future<PlayerProgressDto> push(ProgressUpdate update) =>
      _progress.putProgress(update);

  Future<PlayerProgressDto?> pull() async {
    try {
      return await _progress.getProgress();
    } on NotFoundError {
      return null;
    }
  }
}
