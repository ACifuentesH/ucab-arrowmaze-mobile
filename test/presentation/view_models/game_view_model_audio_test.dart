import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/enums/sound_effect.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';
import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/restart_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/undo_move_use_case.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/entities/cell/empty_cell.dart';
import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/ports/i_time_service.dart';
import 'package:arrow_maze/domain/services/square_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';

void main() {
  group('GameViewModel – integración audio (Observer: eventos → sfx)', () {
    late _FakeAudio audio;
    late _FakeTimeService time;

    GameViewModel makeCtrl(Board board) {
      final invoker = CommandInvoker();
      final repo = _FakeRepo(board: board);
      return GameViewModel(
        loadLevel: LoadLevelUseCase(repository: repo),
        removeArrow: RemoveArrowUseCase(invoker: invoker),
        restart: RestartLevelUseCase(repository: repo, invoker: invoker),
        undo: UndoMoveUseCase(invoker: invoker),
        timeService: time,
        audioService: audio,
      );
    }

    setUp(() {
      audio = _FakeAudio();
      time = _FakeTimeService();
    });

    test('playMusic se llama al cargar un nivel', () async {
      final ctrl = makeCtrl(_singleArrowBoard());
      await ctrl.loadLevel('test');
      expect(audio.playMusicCount, 1);
      ctrl.dispose();
    });

    test('playSfx(arrowEscaped) al sacar una flecha exitosamente', () async {
      // Tablero 2 flechas sin dependencias: a1 escapa, a2 sigue en tablero.
      final ctrl = makeCtrl(_twoIndependentArrowsBoard());
      await ctrl.loadLevel('test');
      audio.clear();

      ctrl.tapArrow('a1'); // a1 en r0c0 East, sin vecino este → escapa

      expect(audio.sfxCalled, contains(SoundEffect.arrowEscaped));
      expect(audio.sfxCalled, isNot(contains(SoundEffect.levelCleared)));
      ctrl.dispose();
    });

    test('playSfx(moveBlocked) al intentar mover una flecha bloqueada', () async {
      // Tablero 1×2: a1(r0c0 East) bloqueada por a2(r0c1).
      final ctrl = makeCtrl(_blockedArrowBoard());
      await ctrl.loadLevel('test');
      audio.clear();

      ctrl.tapArrow('a1');

      expect(audio.sfxCalled, contains(SoundEffect.moveBlocked));
      ctrl.dispose();
    });

    test('playSfx(levelCleared) y stopMusic al vaciar el tablero', () async {
      final ctrl = makeCtrl(_singleArrowBoard());
      await ctrl.loadLevel('test');
      audio.clear();

      ctrl.tapArrow('a1'); // único arrow → escapa → levelCleared

      expect(audio.sfxCalled, contains(SoundEffect.arrowEscaped));
      expect(audio.sfxCalled, contains(SoundEffect.levelCleared));
      expect(audio.stopMusicCount, 1);
      ctrl.dispose();
    });

    test('toggleMute actualiza isMuted en el estado', () async {
      final ctrl = makeCtrl(_singleArrowBoard());
      await ctrl.loadLevel('test');
      expect(ctrl.state.isMuted, isFalse);

      ctrl.toggleMute();
      expect(ctrl.state.isMuted, isTrue);

      ctrl.toggleMute();
      expect(ctrl.state.isMuted, isFalse);
      ctrl.dispose();
    });
  });
}

// ── Helpers de tablero ────────────────────────────────────────────────────────

/// 1×3: [a1-tail][a1-head→][vacía]  →  única flecha; siempre escapa.
Board _singleArrowBoard() {
  final nodes = [
    Node(id: CellId('r0c0'), content: EmptyCell(id: CellId('r0c0'))),
    Node(id: CellId('r0c1'), content: EmptyCell(id: CellId('r0c1'))),
    Node(id: CellId('r0c2'), content: EmptyCell(id: CellId('r0c2'))),
  ];
  final graph = SquareGridTopology().buildConnections(nodes);
  final a1 = Arrow(
    id: 'a1',
    path: [CellId('r0c0'), CellId('r0c1')],
    color: '#FF0000',
    headDirection: Direction(index: 1, total: 4), // East
  );
  return Board(
    levelId: LevelId('test'),
    boundingRows: 1,
    boundingCols: 3,
    graph: graph,
    arrows: {a1.id: a1},
    occupancy: {CellId('r0c0'): a1.id, CellId('r0c1'): a1.id},
  );
}

/// 2×3: fila 0 → a1; fila 1 → a2. Ambas escapan independientemente.
/// Tocar a1 solo emite ArrowEscaped (a2 sigue en tablero → no LevelCleared).
Board _twoIndependentArrowsBoard() {
  final nodes = [
    Node(id: CellId('r0c0'), content: EmptyCell(id: CellId('r0c0'))),
    Node(id: CellId('r0c1'), content: EmptyCell(id: CellId('r0c1'))),
    Node(id: CellId('r0c2'), content: EmptyCell(id: CellId('r0c2'))),
    Node(id: CellId('r1c0'), content: EmptyCell(id: CellId('r1c0'))),
    Node(id: CellId('r1c1'), content: EmptyCell(id: CellId('r1c1'))),
    Node(id: CellId('r1c2'), content: EmptyCell(id: CellId('r1c2'))),
  ];
  final graph = SquareGridTopology().buildConnections(nodes);
  final a1 = Arrow(
    id: 'a1',
    path: [CellId('r0c0'), CellId('r0c1')],
    color: '#FF0000',
    headDirection: Direction(index: 1, total: 4),
  );
  final a2 = Arrow(
    id: 'a2',
    path: [CellId('r1c0'), CellId('r1c1')],
    color: '#00FF00',
    headDirection: Direction(index: 1, total: 4),
  );
  return Board(
    levelId: LevelId('test'),
    boundingRows: 2,
    boundingCols: 3,
    graph: graph,
    arrows: {a1.id: a1, a2.id: a2},
    occupancy: {
      CellId('r0c0'): a1.id, CellId('r0c1'): a1.id,
      CellId('r1c0'): a2.id, CellId('r1c1'): a2.id,
    },
  );
}

/// 1×4: [a1-tail][a1-head→][a2-tail][a2-head→]
/// a1 intenta escapar East pero r0c2 está ocupado por a2 → BLOQUEADO.
Board _blockedArrowBoard() {
  final nodes = [
    Node(id: CellId('r0c0'), content: EmptyCell(id: CellId('r0c0'))),
    Node(id: CellId('r0c1'), content: EmptyCell(id: CellId('r0c1'))),
    Node(id: CellId('r0c2'), content: EmptyCell(id: CellId('r0c2'))),
    Node(id: CellId('r0c3'), content: EmptyCell(id: CellId('r0c3'))),
  ];
  final graph = SquareGridTopology().buildConnections(nodes);
  final a1 = Arrow(
    id: 'a1',
    path: [CellId('r0c0'), CellId('r0c1')],
    color: '#0000FF',
    headDirection: Direction(index: 1, total: 4),
  );
  final a2 = Arrow(
    id: 'a2',
    path: [CellId('r0c2'), CellId('r0c3')],
    color: '#FF0000',
    headDirection: Direction(index: 1, total: 4),
  );
  return Board(
    levelId: LevelId('test'),
    boundingRows: 1,
    boundingCols: 4,
    graph: graph,
    arrows: {a1.id: a1, a2.id: a2},
    occupancy: {
      CellId('r0c0'): a1.id, CellId('r0c1'): a1.id,
      CellId('r0c2'): a2.id, CellId('r0c3'): a2.id,
    },
    lives: Lives(3),
  );
}

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeRepo implements ILevelRepository {
  final Board board;
  _FakeRepo({required this.board});

  @override
  Future<Board> loadLevel(LevelId id) async => board;

  @override
  Future<void> saveProgress(LevelId id, int score) async {}
}

class _FakeTimeService implements ITimeService {
  final _ctrl = StreamController<int>.broadcast();

  @override
  Stream<int> get elapsed => _ctrl.stream;

  @override
  void start() {}

  @override
  void stop() {}

  @override
  void reset() {}

  void tick(int seconds) => _ctrl.add(seconds);

  void dispose() => _ctrl.close();
}

class _FakeAudio implements IAudioService {
  int playMusicCount = 0;
  int stopMusicCount = 0;
  final List<SoundEffect> sfxCalled = [];
  bool _muted = false;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> playMusic() async => playMusicCount++;

  @override
  Future<void> stopMusic() async => stopMusicCount++;

  @override
  Future<void> playSfx(SoundEffect effect) async => sfxCalled.add(effect);

  @override
  void toggleMute() => _muted = !_muted;

  void clear() {
    sfxCalled.clear();
    playMusicCount = 0;
    stopMusicCount = 0;
  }
}
