import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';
import 'package:arrow_maze/presentation/views/widgets/board_view.dart';
import 'package:arrow_maze/presentation/views/widgets/hex_board_geometry.dart';

import '../../_support/mothers/level_definition_mother.dart';

/// Integración de la vista sobre un tablero HEX real (construido con
/// `LevelBuilder` y una `LevelDefinition` con `topology: hex`): render sin
/// excepciones y que el tap sobre una celda de flecha dispare `onTapArrow` con
/// el id correcto, mientras una celda vacía no dispara nada.
void main() {
  // Tablero hex 3×3: h1 ocupa (1,0)-(1,1); h2 ocupa (0,2)-(1,2).
  // Vacías: (0,0) (0,1) (2,0) (2,1) (2,2).
  Board buildHexBoard() =>
      LevelBuilder().build(LevelDefinitionMother.hexLevel());

  const geo = HexBoardGeometry();
  const double side = 300;

  /// Posición global del centro de la celda (r,c) dentro del BoardView, que
  /// llena un cuadrado [side]×[side] y centra el tablero hex dentro.
  Offset globalCenterOf(WidgetTester tester, int r, int c) {
    final viewRect = tester.getRect(find.byType(BoardView));
    final cell = geo.cellScaleFor(side, side, 3, 3);
    final board = geo.boardSize(3, 3, cell);
    final origin = viewRect.topLeft +
        Offset((side - board.width) / 2, (side - board.height) / 2);
    return origin + geo.cellCenter(r, c, cell);
  }

  Future<String?> pumpAndReturnTapTarget(
    WidgetTester tester, {
    required int tapRow,
    required int tapCol,
  }) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: side,
              height: side,
              child: BoardView(
                board: buildHexBoard(),
                onTapArrow: (id) => tapped = id,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(globalCenterOf(tester, tapRow, tapCol));
    await tester.pump();
    return tapped;
  }

  testWidgets('should_render_a_hex_board_without_exceptions_when_built',
      (tester) async {
    final board = buildHexBoard();
    expect(board.topologyKind, TopologyKind.hex);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: side,
              height: side,
              child: BoardView(board: board, onTapArrow: (_) {}),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BoardView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('should_fire_onTapArrow_with_correct_id_when_tapping_an_arrow',
      (tester) async {
    // (1,1) es la cabeza de h1.
    final tapped = await pumpAndReturnTapTarget(tester, tapRow: 1, tapCol: 1);
    expect(tapped, 'h1');
  });

  testWidgets('should_not_fire_onTapArrow_when_tapping_an_empty_cell',
      (tester) async {
    // (2,1) es una celda vacía.
    final tapped = await pumpAndReturnTapTarget(tester, tapRow: 2, tapCol: 1);
    expect(tapped, isNull);
  });
}
