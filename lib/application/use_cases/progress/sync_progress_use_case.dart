import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';

/// STUB — sincronización de progreso con el backend (compartido entre
/// feature/auth y feature/levels-gameplay).
class SyncProgressUseCase {
  final IApiClient _api;

  const SyncProgressUseCase({required IApiClient api}) : _api = api;

  /// Sube el progreso; al completar un nivel incluir last* en [update]
  /// para que el backend registre la entrada de leaderboard.
  Future<PlayerProgressDto> push(ProgressUpdate update) =>
      _api.putProgress(update);

  /// Baja el progreso remoto; usuario nuevo (404) → null, no es un error.
  Future<PlayerProgressDto?> pull() async {
    try {
      return await _api.getProgress();
    } on NotFoundError {
      return null;
    }
  }
}
