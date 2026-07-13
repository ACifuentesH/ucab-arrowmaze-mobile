import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';

/// Puerto remoto de progreso del jugador (rutas JWT `/progress`).
abstract interface class IProgressRepository {
  Future<PlayerProgressDto> getProgress();
  Future<PlayerProgressDto> putProgress(ProgressUpdate update);
}
