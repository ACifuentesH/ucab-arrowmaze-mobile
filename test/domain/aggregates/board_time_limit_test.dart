import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/events/domain_events.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/domain/services/adjacency_board_graph.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

void main() {
  group('Board.applyTimeTick', () {
    Board makeBoard({int? limit}) => Board(
          levelId: LevelId('test'),
          boundingRows: 0,
          boundingCols: 0,
          graph: AdjacencyBoardGraph([]),
          arrows: {},
          occupancy: {},
          timeLimitSeconds: limit,
        );

    test('sin límite nunca emite GameOver', () {
      final b = makeBoard();
      b.applyTimeTick(999);
      expect(b.pullEvents(), isEmpty);
      expect(b.status, GameStatus.playing);
    });

    test('no emite GameOver antes de alcanzar el límite', () {
      final b = makeBoard(limit: 10);
      b.applyTimeTick(9);
      expect(b.pullEvents(), isEmpty);
      expect(b.status, GameStatus.playing);
    });

    test('emite GameOver al alcanzar exactamente el límite', () {
      final b = makeBoard(limit: 10);
      b.applyTimeTick(10);
      final events = b.pullEvents();
      expect(events.whereType<GameOver>(), hasLength(1));
      expect(b.status, GameStatus.gameOver);
    });

    test('emite GameOver al superar el límite', () {
      final b = makeBoard(limit: 10);
      b.applyTimeTick(15);
      expect(b.pullEvents().whereType<GameOver>(), hasLength(1));
      expect(b.status, GameStatus.gameOver);
    });

    test('no emite segundo GameOver si ya está en gameOver', () {
      final b = makeBoard(limit: 10);
      b.applyTimeTick(10);
      b.pullEvents(); // consume primer evento
      b.applyTimeTick(11);
      expect(b.pullEvents(), isEmpty);
    });
  });
}
