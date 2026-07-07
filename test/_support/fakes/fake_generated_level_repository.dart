import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';

/// Fake in-memory de IGeneratedLevelRepository.
class FakeGeneratedLevelRepository implements IGeneratedLevelRepository {
  final Map<String, LevelDefinition> _store = {};

  @override
  Future<void> save(LevelDefinition definition) async {
    _store[definition.id] = definition;
  }

  @override
  Future<List<LevelDefinition>> findAll() async => _store.values.toList();

  @override
  Future<LevelDefinition?> findById(String id) async => _store[id];

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }
}
