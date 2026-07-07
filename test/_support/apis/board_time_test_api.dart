import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/events/domain_events.dart';
import 'package:arrow_maze/domain/game_status.dart';

import '../mothers/board_mother.dart';

/// Testing API: regla de dominio del límite de tiempo (Board.applyTimeTick).
class BoardTimeTestApi {
  late Board _board;
  final List<DomainEvent> _events = [];

  BoardTimeTestApi givenABoardWithTimeLimit({required int seconds}) {
    _board = BoardMother.withTimeLimit(seconds: seconds);
    return this;
  }

  BoardTimeTestApi givenABoardWithoutTimeLimit() {
    _board = BoardMother.withoutTimeLimit();
    return this;
  }

  BoardTimeTestApi whenTimeAdvancesTo(int seconds) {
    _board.applyTimeTick(seconds);
    _events.addAll(_board.pullEvents());
    return this;
  }

  void thenGameShouldBeOver() {
    expect(_board.status, equals(GameStatus.gameOver));
    expect(_events.whereType<GameOver>(), hasLength(1));
  }

  void thenGameShouldStillBePlaying() {
    expect(_board.status, equals(GameStatus.playing));
    expect(_events.whereType<GameOver>(), isEmpty);
  }

  void thenNoFurtherEventsShouldBeEmitted() =>
      expect(_board.pullEvents(), isEmpty);
}
