import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/entities/cell/empty_cell.dart';
import 'package:arrow_maze/domain/entities/cell/wall_cell.dart';
import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/services/square_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';

void main() {
  group('RemoveArrowUseCase – flechas multi-casilla', () {
    test('flecha recta sale cuando el camino está despejado', () {
      // Tablero 1×5: [a1-tail][a1][a1-head→][empty][empty]
      final board = _makeBoard(rows: 1, cols: 5, arrows: [_straightEast]);

      final result = RemoveArrowUseCase(invoker: CommandInvoker())
          .execute(board, 'straight');

      expect(result, isTrue);
      expect(board.arrowCount, 0);
      expect(board.moves.value, 1);
    });

    test('flecha curva (L) sale cuando el camino está despejado', () {
      // Tablero 3×3: curva (0,0)→(1,0)→(1,1)→(1,2), punta East
      // Fila 1 col 3 es borde → libre
      final board = _makeBoard(rows: 3, cols: 3, arrows: [_curvedEast]);

      final result = RemoveArrowUseCase(invoker: CommandInvoker())
          .execute(board, 'curved');

      expect(result, isTrue);
      expect(board.arrowCount, 0);
    });

    test('flecha bloqueada por pared resta una vida', () {
      // Tablero 1×4: [a1-tail][a1-head→][wall][empty]
      // La pared está en (0,2), así que la flecha recta no puede salir
      final board = _makeBoard(
        rows: 1,
        cols: 4,
        arrows: [_straightShort],
        wallAt: CellId('r0c2'),
      );
      final livesBefore = board.lives.value;

      final result = RemoveArrowUseCase(invoker: CommandInvoker())
          .execute(board, 'short');

      expect(result, isFalse);
      expect(board.arrowCount, 1);
      expect(board.lives.value, livesBefore - 1);
    });

    test('undo restaura la flecha extraída', () {
      final invoker = CommandInvoker();
      final board = _makeBoard(rows: 1, cols: 5, arrows: [_straightEast]);

      RemoveArrowUseCase(invoker: invoker).execute(board, 'straight');
      expect(board.arrowCount, 0);

      invoker.undo();

      expect(board.arrowCount, 1);
      expect(board.arrowById('straight'), isNotNull);
    });

    test('victoria al vaciar el tablero', () {
      final board = _makeBoard(rows: 1, cols: 5, arrows: [_straightEast]);

      RemoveArrowUseCase(invoker: CommandInvoker()).execute(board, 'straight');

      expect(board.isCleared(), isTrue);
      expect(board.status.name, 'levelCleared');
    });

    test('no opera cuando el juego ya terminó (gameOver)', () {
      final board = _makeBoard(
        rows: 1,
        cols: 4,
        arrows: [_straightShort],
        wallAt: CellId('r0c2'),
        lives: 1,
      );
      final uc = RemoveArrowUseCase(invoker: CommandInvoker());

      uc.execute(board, 'short'); // bloquea → gameOver
      expect(board.status.name, 'gameOver');

      final result = uc.execute(board, 'short');
      expect(result, isFalse);
    });
  });
}

// ── Flechas de prueba ─────────────────────────────────────────────────────────

/// Flecha recta East de 3 casillas: (0,0)→(0,1)→(0,2), cabeza East
final _straightEast = Arrow(
  id: 'straight',
  path: [CellId('r0c0'), CellId('r0c1'), CellId('r0c2')],
  color: '#FF0000',
  headDirection: Direction(index: 1, total: 4),
);

/// Flecha corta East de 2 casillas: (0,0)→(0,1), cabeza East
final _straightShort = Arrow(
  id: 'short',
  path: [CellId('r0c0'), CellId('r0c1')],
  color: '#0000FF',
  headDirection: Direction(index: 1, total: 4),
);

/// Flecha curva (L): (0,0)→(1,0)→(1,1)→(1,2), cabeza East
final _curvedEast = Arrow(
  id: 'curved',
  path: [
    CellId('r0c0'), CellId('r1c0'), CellId('r1c1'), CellId('r1c2')
  ],
  color: '#00FF00',
  headDirection: Direction(index: 1, total: 4),
);

// ── Helper board factory ──────────────────────────────────────────────────────

Board _makeBoard({
  required int rows,
  required int cols,
  required List<Arrow> arrows,
  CellId? wallAt,
  int lives = 3,
}) {
  final topology = SquareGridTopology();
  final nodes = <Node>[];

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final id = CellId('r${r}c$c');
      final content =
          wallAt == id ? WallCell(id: id) : EmptyCell(id: id);
      nodes.add(Node(id: id, content: content));
    }
  }

  final graph = topology.buildConnections(nodes);
  final arrowMap = <String, Arrow>{for (final a in arrows) a.id: a};
  final occupancy = <CellId, String>{
    for (final a in arrows)
      for (final cell in a.path) cell: a.id,
  };

  return Board(
    levelId: LevelId('test'),
    boundingRows: rows,
    boundingCols: cols,
    graph: graph,
    arrows: arrowMap,
    occupancy: occupancy,
    lives: Lives(lives),
  );
}
