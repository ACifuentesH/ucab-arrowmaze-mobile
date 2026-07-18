import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

import '../../_support/solvers/greedy_board_solver.dart';

/// Los niveles del MODO HEXAGONAL son datos, pero datos con invariantes duros:
/// deben declarar topología hex, ser construibles por el `LevelBuilder` real
/// (que valida forma y adyacencia contra el grafo odd-r) y ser RESOLUBLES.
/// El juego es monótono (extraer una flecha solo libera celdas), así que un
/// solver GREEDY es completo: si existe algún orden de extracción, greedy lo
/// encuentra. Estos tests protegen el diseño manual de los dos niveles hex.
void main() {
  final manifest = jsonDecode(
    File('assets/levels/hex_manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final ids = (manifest['levels'] as List<dynamic>).cast<String>();

  LevelDefinition load(String id) => LevelDefinition.fromJson(
        jsonDecode(File('assets/levels/$id.json').readAsStringSync())
            as Map<String, dynamic>,
      );

  int countInitiallyBlocked(Board board) {
    const solver = GreedyBoardSolver();
    return board.arrows.values
        .where((Arrow a) => !solver.canEscape(board, a))
        .length;
  }

  group('Modo hexagonal — assets/levels', () {
    test('should_list_exactly_the_three_hex_levels_when_manifest_is_read', () {
      expect(ids, equals(['hex_1', 'hex_2', 'hex_3']));
    });

    for (final id in ids) {
      test('should_build_a_hex_board_when_loading_$id', () {
        final definition = load(id);
        expect(definition.topology, equals(TopologyKind.hex),
            reason: '$id: debe declarar topology hex');
        expect(definition.cells, isNotEmpty);
        expect(definition.arrows, isNotEmpty);
        expect(definition.lives, greaterThan(0));

        final board = LevelBuilder().build(definition);
        expect(board.topologyKind, equals(TopologyKind.hex));
      });

      test('should_be_greedily_solvable_when_loading_$id', () {
        final board = LevelBuilder().build(load(id));

        expect(const GreedyBoardSolver().solve(board), isTrue,
            reason: '$id: el nivel no es resoluble');
        expect(board.isCleared(), isTrue);
        expect(board.arrowCount, equals(0));
        expect(board.status, equals(GameStatus.levelCleared));
      });
    }

    test('should_start_with_at_least_one_blocked_arrow_when_hex_1_is_built',
        () {
      final board = LevelBuilder().build(load('hex_1'));
      expect(countInitiallyBlocked(board), greaterThanOrEqualTo(1),
          reason: 'hex_1 necesita un mínimo de orden de resolución');
    });

    test('should_start_with_at_least_six_blocked_arrows_when_hex_2_is_built',
        () {
      final board = LevelBuilder().build(load('hex_2'));
      expect(countInitiallyBlocked(board), greaterThanOrEqualTo(6),
          reason: 'hex_2 (hard) exige dependencias encadenadas reales');
    });

    test('should_have_a_large_board_when_hex_3_is_loaded', () {
      final definition = load('hex_3');
      expect(definition.cells.length, greaterThanOrEqualTo(90),
          reason: 'hex_3 (Enjambre) es el tablero gigante del modo hex');
      expect(definition.arrows.length, inInclusiveRange(20, 24));
    });

    test('should_start_with_at_least_fifteen_blocked_arrows_when_hex_3_is_built',
        () {
      final board = LevelBuilder().build(load('hex_3'));
      expect(countInitiallyBlocked(board), greaterThanOrEqualTo(15),
          reason: 'hex_3 exige que la mayoría de flechas dependa de otras '
              '(cadenas profundas, orden de resolución casi único)');
    });
  });
}
