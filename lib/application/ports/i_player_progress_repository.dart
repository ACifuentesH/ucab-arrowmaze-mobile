import 'package:arrow_maze/application/dtos/level_progress.dart';

/// Puerto de persistencia del progreso del jugador.
abstract interface class IPlayerProgressRepository {
  Future<void> save(LevelProgress progress);
  Future<LevelProgress?> find(String levelId);
  Future<List<LevelProgress>> findAll();
}
