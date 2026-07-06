import 'dart:math';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/infrastructure/services/groq_level_generator_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cells of a solid [rows]×[cols] rectangle.
List<List<int>> _rectangle(int rows, int cols) => [
      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) [r, c],
    ];

/// Cells of a diamond inscribed in a [size]×[size] box.
List<List<int>> _diamond(int size) {
  final mid = size ~/ 2;
  final cells = <List<int>>[];
  for (int r = 0; r < size; r++) {
    for (int c = 0; c < size; c++) {
      if ((r - mid).abs() + (c - mid).abs() <= mid) cells.add([r, c]);
    }
  }
  return cells;
}

/// Mirrors Board._isPathClear using only the public graph + occupancy API,
/// so we can find an escapable arrow without spending a life.
bool _canEscape(Board board, Arrow arrow) {
  var current = board.graph.connectedNode(arrow.headCell, arrow.headDirection);
  while (current != null) {
    if (board.occupancy.containsKey(current)) return false;
    if (board.graph.nodeById(current) == null) return true;
    current = board.graph.connectedNode(current, arrow.headDirection);
  }
  return true;
}

/// Greedily taps any escapable arrow until the board is cleared. Returns false
/// if it ever gets stuck. Never loses a life (only taps proven-clear arrows).
bool _isSolvable(Board board) {
  var guard = 0;
  while (!board.isCleared()) {
    if (guard++ > 1000) return false;
    Arrow? next;
    for (final a in board.arrows.values) {
      if (_canEscape(board, a)) {
        next = a;
        break;
      }
    }
    if (next == null) return false; // stuck
    board.tryRemoveArrow(next.id);
  }
  return true;
}

void main() {
  group('GroqLevelGeneratorService.debugBuildArrows', () {
    final shapes = <String, List<List<int>>>{
      'rectangle 8x8': _rectangle(8, 8),
      'rectangle 16x16': _rectangle(16, 16),
      'diamond 13': _diamond(13),
      'tall 12x5': _rectangle(12, 5),
    };

    shapes.forEach((label, cells) {
      test('should_build_valid_complex_solvable_arrows_for_$label', () {
        // Run many seeds: the generator is randomized, so we assert the
        // invariants hold for every seed, not just a lucky one.
        for (int seed = 0; seed < 40; seed++) {
          final rng = Random(seed);
          final arrows =
              GroqLevelGeneratorService.debugBuildArrows(cells, rng);

          // Arrange — assemble a real board through the domain builder.
          final def = LevelDefinition.fromJson({
            'id': 'test_${label}_$seed',
            'name': label,
            'lives': 5,
            'cells': cells,
            'arrows': arrows,
          });

          // Act + Assert — the builder validates on-shape, adjacency, no overlap.
          // It throws ArgumentError on any invalid arrow, failing the test.
          final board = LevelBuilder().build(def);

          expect(arrows.length, greaterThanOrEqualTo(2),
              reason: '$label/$seed: too few arrows');

          // Complexity: most arrows should be more than a 2-cell stub.
          final complex =
              arrows.where((a) => (a['path'] as List).length >= 3).length;
          expect(complex, greaterThanOrEqualTo((arrows.length / 2).floor()),
              reason: '$label/$seed: arrows are too simple (one-tailed)');

          // Solvability: the puzzle can always be cleared.
          expect(_isSolvable(board), isTrue,
              reason: '$label/$seed: generated level is not solvable');
        }
      });
    });
  });
}
