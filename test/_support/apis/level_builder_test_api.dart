import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

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

  LevelBuilderTestApi givenAHexLevelDefinition() {
    _definition = LevelDefinitionMother.hexLevel();
    return this;
  }

  LevelBuilderTestApi givenAHexDefinitionWithNonAdjacentArrow() {
    _definition = LevelDefinitionMother.hexWithNonAdjacentArrow();
    return this;
  }

  LevelBuilderTestApi givenAFlatJsonWithoutTopologyField() {
    _definition = LevelDefinition.fromJson(LevelDefinitionMother.flatJson());
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

  void thenBoardTopologyShouldBe(TopologyKind kind) =>
      expect(_board!.topologyKind, equals(kind));

  /// La celda [fromId] debe estar conectada con [toId] en la dirección
  /// [index] (de [total] puertos) del grafo ya construido.
  void thenCellShouldConnectTo(
    String fromId,
    String toId, {
    required int index,
    required int total,
  }) {
    final neighbor = _board!.graph
        .connectedNode(CellId(fromId), Direction(index: index, total: total));
    expect(neighbor, equals(CellId(toId)));
  }

  /// La flecha [arrowId] debe apuntar en la dirección [index] de [total].
  void thenArrowShouldPointTo(
    String arrowId, {
    required int index,
    required int total,
  }) {
    final arrow = _board!.arrowById(arrowId)!;
    expect(arrow.headDirection, equals(Direction(index: index, total: total)));
  }
}
