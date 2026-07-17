import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';

/// Fake in-memory de IPlayerProgressRepository.
class FakePlayerProgressRepository implements IPlayerProgressRepository {
  final Map<String, LevelProgress> _store = {};

  @override
  Future<void> save(LevelProgress progress) async {
    _store[progress.levelId] = progress;
  }

  @override
  Future<LevelProgress?> find(String levelId) async => _store[levelId];

  @override
  Future<List<LevelProgress>> findAll() async => _store.values.toList();

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<void> replaceAll(Iterable<LevelProgress> entries) async {
    _store.clear();
    for (final progress in entries) {
      _store[progress.levelId] = progress;
    }
  }
}
