import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/undo_move_use_case.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/events/domain_events.dart';
import 'package:arrow_maze/domain/game_status.dart';

import '../mothers/board_mother.dart';

/// Testing API: sacar flechas del tablero (Board + Command + Undo).
/// Encapsula la orquestación del SUT; los tests solo hablan negocio.
class RemoveArrowTestApi {
  late Board _board;
  final CommandInvoker _invoker = CommandInvoker();
  bool? _lastResult;
  bool? _undoResult;
  final List<DomainEvent> _events = [];

  // ── Given ──────────────────────────────────────────────────────────────────

  RemoveArrowTestApi givenABoardWithEscapableArrow({int lives = 3}) {
    _board = BoardMother.withEscapableArrow(lives: lives);
    return this;
  }

  RemoveArrowTestApi givenABoardWithBlockedArrow({int lives = 3}) {
    _board = BoardMother.withBlockedArrow(lives: lives);
    return this;
  }

  RemoveArrowTestApi givenAnAlmostClearedBoard() {
    _board = BoardMother.almostCleared();
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  RemoveArrowTestApi whenArrowIsTapped(String arrowId) {
    _lastResult = RemoveArrowUseCase(invoker: _invoker).execute(_board, arrowId);
    _events.addAll(_board.pullEvents());
    return this;
  }

  RemoveArrowTestApi whenMoveIsUndone() {
    _undoResult = UndoMoveUseCase(invoker: _invoker).execute();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenArrowShouldEscape() {
    expect(_lastResult, isTrue);
    expect(_events.whereType<ArrowEscaped>(), isNotEmpty);
  }

  void thenMoveShouldBeRejected() {
    expect(_lastResult, isFalse);
    expect(_events.whereType<MoveBlocked>(), isNotEmpty);
  }

  /// El tablero ya no está en juego: el tap no produce efecto alguno.
  void thenMoveShouldBeIgnored() => expect(_lastResult, isFalse);

  void thenUndoShouldSucceed() => expect(_undoResult, isTrue);

  void thenUndoShouldBeRejected() => expect(_undoResult, isFalse);

  void thenALifeShouldBeLost({required int to}) =>
      expect(_board.lives.value, equals(to));

  void thenLevelShouldBeCleared() {
    expect(_board.status, equals(GameStatus.levelCleared));
    expect(_events.whereType<LevelCleared>(), isNotEmpty);
  }

  void thenGameShouldBeOver() {
    expect(_board.status, equals(GameStatus.gameOver));
    expect(_events.whereType<GameOver>(), isNotEmpty);
  }

  void thenGameShouldStillBePlaying() =>
      expect(_board.status, equals(GameStatus.playing));

  void thenArrowCountShouldBe(int count) =>
      expect(_board.arrowCount, equals(count));

  void thenMoveCountShouldBe(int count) =>
      expect(_board.moves.value, equals(count));

  void thenArrowShouldBeBackOnBoard(String arrowId) =>
      expect(_board.arrowById(arrowId), isNotNull);
}
