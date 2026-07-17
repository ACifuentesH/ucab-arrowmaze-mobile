import 'package:arrow_maze/application/dtos/level_progress.dart';

/// Puerto de persistencia del progreso del jugador.
abstract interface class IPlayerProgressRepository {
  Future<void> save(LevelProgress progress);
  Future<LevelProgress?> find(String levelId);
  Future<List<LevelProgress>> findAll();

  /// Elimina todo el progreso local (p. ej. usuario nuevo sin progreso remoto).
  Future<void> clear();

  /// Sustituye el progreso local por [entries] (hidratación desde el servidor).
  Future<void> replaceAll(Iterable<LevelProgress> entries);
}
