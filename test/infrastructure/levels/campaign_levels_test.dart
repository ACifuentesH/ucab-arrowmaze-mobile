import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';

import '../../_support/solvers/greedy_board_solver.dart';

/// Los 15 niveles de la campaña son datos, pero datos con invariantes:
/// deben cumplir el contrato, ser construibles, ser RESOLUBLES y subir de
/// dificultad. Estos tests protegen el diseño manual de los niveles.
void main() {
  final manifest = jsonDecode(
    File('assets/levels/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final ids = (manifest['levels'] as List<dynamic>).cast<String>();

  LevelDefinition load(String id) => LevelDefinition.fromJson(
        jsonDecode(File('assets/levels/$id.json').readAsStringSync())
            as Map<String, dynamic>,
      );

  group('Campaña — assets/levels', () {
    test('should_have_fifteen_levels_when_manifest_is_read', () {
      expect(ids, hasLength(15));
    });

    for (final id in ids) {
      test('should_build_a_solvable_board_when_loading_$id', () {
        // Arrange — el JSON cumple el contrato { cells, arrows, lives }.
        final definition = load(id);
        expect(definition.cells, isNotEmpty);
        expect(definition.arrows, isNotEmpty);
        expect(definition.lives, greaterThan(0));
        expect(definition.difficulty, isNotNull,
            reason: '$id: todo nivel de campaña declara difficulty');

        // Act — el builder valida forma, adyacencia y solapamientos.
        final board = LevelBuilder().build(definition);

        // Assert — existe al menos un orden de extracción que lo resuelve.
        expect(const GreedyBoardSolver().solve(board), isTrue,
            reason: '$id: el nivel no es resoluble');
      });
    }

    test('should_increase_difficulty_when_advancing_through_the_campaign',
        () {
      final difficulties =
          ids.map((id) => load(id).difficulty!.index).toList();
      for (var i = 1; i < difficulties.length; i++) {
        expect(difficulties[i], greaterThanOrEqualTo(difficulties[i - 1]),
            reason: '${ids[i]} baja la dificultad respecto a ${ids[i - 1]}');
      }
      expect(difficulties.first, equals(Difficulty.easy.index));
      expect(difficulties.last, equals(Difficulty.hard.index));
    });

    test('should_have_unique_ids_when_manifest_is_read', () {
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
