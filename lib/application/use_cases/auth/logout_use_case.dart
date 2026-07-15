import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';

/// Cierra la sesión local: token, perfil y progreso del jugador anterior.
///
/// El progreso de invitado/autenticado vive en el mismo repositorio local;
/// al logout se borra para no filtrar completedLevels/bestScores al modo invitado.
class LogoutUseCase {
  final IApiClient _api;
  final IUserStorage _userStorage;
  final IPlayerProgressRepository _progress;

  const LogoutUseCase({
    required IApiClient api,
    required IUserStorage userStorage,
    required IPlayerProgressRepository progress,
  })  : _api = api,
        _userStorage = userStorage,
        _progress = progress;

  Future<void> execute() async {
    await _api.logout();
    await _userStorage.clear();
    await _progress.clear();
  }
}
