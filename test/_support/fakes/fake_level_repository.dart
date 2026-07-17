import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

/// Fake in-memory de ILevelRepository (no mock: comportamiento real simplificado).
class FakeLevelRepository implements ILevelRepository {
  final Map<String, LevelDefinition> _definitions = {};
  final Map<String, int> savedScores = {};
  final LevelBuilder _builder = LevelBuilder();

  LevelId? lastRequestedId;
  int loadCount = 0;

  void seed(LevelDefinition definition) =>
      _definitions[definition.id] = definition;

  @override
  Future<Board> loadLevel(LevelId id) async {
    loadCount++;
    lastRequestedId = id;
    final def = _definitions[id.value];
    if (def == null) {
      throw StateError('Level not found: ${id.value}');
    }
    return _builder.build(def);
  }

  @override
  Future<void> saveProgress(LevelId id, int score) async {
    savedScores[id.value] = score;
  }
}
