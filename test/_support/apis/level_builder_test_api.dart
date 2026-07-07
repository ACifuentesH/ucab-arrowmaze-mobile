import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';

import '../mothers/level_definition_mother.dart';

/// Testing API: construcción de Board desde LevelDefinition (patrón Builder).
class LevelBuilderTestApi {
  late LevelDefinition _definition;
  Board? _board;
  Object? _error;

  LevelBuilderTestApi givenAValidLevelDefinition({int lives = 3}) {
    _definition = LevelDefinitionMother.withEscapableArrow(lives: lives);
    return this;
  }

  LevelBuilderTestApi givenADefinitionWithArrowOutsideBoard() {
    _definition = LevelDefinitionMother.withArrowOutsideBoard();
    return this;
  }

  LevelBuilderTestApi givenADefinitionWithOverlappingArrows() {
    _definition = LevelDefinitionMother.withOverlappingArrows();
    return this;
  }

  LevelBuilderTestApi whenBoardIsBuilt() {
    try {
      _board = LevelBuilder().build(_definition);
    } catch (e) {
      _error = e;
    }
    return this;
  }

  void thenBoardShouldHaveArrows(int count) =>
      expect(_board!.arrowCount, equals(count));

  void thenBoardLivesShouldBe(int lives) =>
      expect(_board!.lives.value, equals(lives));

  void thenBoardBoundsShouldBe({required int rows, required int cols}) {
    expect(_board!.boundingRows, equals(rows));
    expect(_board!.boundingCols, equals(cols));
  }

  void thenBuildShouldBeRejected() => expect(_error, isA<ArgumentError>());
}
