import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/services/adjacency_board_graph.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';

void main() {
  group('LoadLevelUseCase', () {
    test('execute delega en el repositorio y devuelve el Board resultante',
        () async {
      final expectedBoard = _makeMinimalBoard();
      final repo = _FakeLevelRepository(board: expectedBoard);
      final useCase = LoadLevelUseCase(repository: repo);

      final result = await useCase.execute(LevelId('level_01'));

      expect(result, same(expectedBoard));
      expect(repo.lastRequestedId?.value, 'level_01');
    });

    test('propaga la excepción cuando el repositorio falla', () async {
      final repo = _FailingLevelRepository();
      final useCase = LoadLevelUseCase(repository: repo);

      expect(
        () => useCase.execute(LevelId('missing')),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _FakeLevelRepository implements ILevelRepository {
  final Board board;
  LevelId? lastRequestedId;

  _FakeLevelRepository({required this.board});

  @override
  Future<Board> loadLevel(LevelId id) async {
    lastRequestedId = id;
    return board;
  }

  @override
  Future<void> saveProgress(LevelId id, int score) async {}
}

class _FailingLevelRepository implements ILevelRepository {
  @override
  Future<Board> loadLevel(LevelId id) async =>
      throw Exception('Level not found: ${id.value}');

  @override
  Future<void> saveProgress(LevelId id, int score) async {}
}

Board _makeMinimalBoard() {
  final graph = AdjacencyBoardGraph([]);
  return Board(
    levelId: LevelId('level_01'),
    boundingRows: 0,
    boundingCols: 0,
    graph: graph,
    arrows: {},
    occupancy: {},
  );
}
