import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';

/// Puerto de persistencia (DIP). El caso de uso depende de esto, no de la BD.
abstract interface class ILevelRepository {
  Future<Board> loadLevel(LevelId id);
  Future<void> saveProgress(LevelId id, int score);
}
