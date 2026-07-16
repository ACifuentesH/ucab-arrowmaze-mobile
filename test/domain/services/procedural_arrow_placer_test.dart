import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/services/procedural_arrow_placer.dart';

void main() {
  group('ProceduralArrowPlacer', () {
    // Cuadrado 10x10 completo: espacio de sobra para probar solapamientos,
    // cobertura y validez de celdas sin flakiness.
    final bigSquare = <List<int>>[
      for (var r = 0; r < 10; r++)
        for (var c = 0; c < 10; c++) [r, c],
    ];

    // Forma irregular con partes de 1 celda de ancho (mástil de paraguas):
    // el caso que estresa la cobertura total.
    final umbrella = <List<int>>[
      [0, 1], [0, 2], [0, 3],
      [1, 0], [1, 1], [1, 2], [1, 3], [1, 4],
      [2, 2],
      [3, 2],
      [4, 2], [4, 3],
    ];

    /// Simula la mecánica exacta de Board: recorre las flechas en el orden
    /// devuelto y exige que cada una pueda escapar en su turno — el rayo
    /// desde la cabeza en su dirección, dentro de la forma, no puede tocar
    /// ninguna celda ocupada (las de su propia cola incluidas, igual que
    /// Board._isPathClear).
    void expectSolvableInReturnedOrder(
      List<List<int>> cells,
      List<ArrowSpec> arrows,
    ) {
      final shape = {for (final c in cells) '${c[0]},${c[1]}'};
      final occupancy = <String, String>{};
      for (final a in arrows) {
        for (final cell in a.path) {
          occupancy['${cell[0]},${cell[1]}'] = a.id;
        }
      }
      for (final a in arrows) {
        final head = a.path.last; // path es tail→head
        final behind = a.path[a.path.length - 2];
        final dr = head[0] - behind[0];
        final dc = head[1] - behind[1];
        for (var k = 1;; k++) {
          final key = '${head[0] + dr * k},${head[1] + dc * k}';
          if (!shape.contains(key)) break; // salió de la forma → escapó
          expect(occupancy.containsKey(key), isFalse,
              reason: 'arrow ${a.id} blocked at $key by '
                  '${occupancy[key]} when tapped in returned order');
        }
        for (final cell in a.path) {
          occupancy.remove('${cell[0]},${cell[1]}');
        }
      }
    }

    test('should_cover_every_cell_of_the_shape_with_no_gaps', () {
      final arrows =
          ProceduralArrowPlacer().place(bigSquare, random: Random(42));

      final covered = <String>{
        for (final a in arrows)
          for (final cell in a.path) '${cell[0]},${cell[1]}',
      };
      expect(covered, hasLength(bigSquare.length));
    });

    test('should_cover_a_shape_with_one_cell_wide_parts_completely', () {
      for (var seed = 0; seed < 10; seed++) {
        final arrows =
            ProceduralArrowPlacer().place(umbrella, random: Random(seed));

        final covered = <String>{
          for (final a in arrows)
            for (final cell in a.path) '${cell[0]},${cell[1]}',
        };
        expect(covered, hasLength(umbrella.length),
            reason: 'seed $seed left cells uncovered');
        expectSolvableInReturnedOrder(umbrella, arrows);
      }
    });

    test('should_be_solvable_in_the_returned_order', () {
      for (var seed = 0; seed < 10; seed++) {
        final arrows =
            ProceduralArrowPlacer().place(bigSquare, random: Random(seed));
        expectSolvableInReturnedOrder(bigSquare, arrows);
      }
    });

    test('should_not_overlap_any_two_arrow_paths', () {
      final arrows =
          ProceduralArrowPlacer().place(bigSquare, random: Random(42));

      final seen = <String>{};
      for (final a in arrows) {
        for (final cell in a.path) {
          final key = '${cell[0]},${cell[1]}';
          expect(seen.contains(key), isFalse,
              reason: 'cell $key used by more than one arrow');
          seen.add(key);
        }
      }
    });

    test('should_only_use_cells_that_belong_to_the_shape', () {
      final shapeKeys = umbrella.map((c) => '${c[0]},${c[1]}').toSet();
      final arrows =
          ProceduralArrowPlacer().place(umbrella, random: Random(7));

      for (final a in arrows) {
        for (final cell in a.path) {
          expect(shapeKeys.contains('${cell[0]},${cell[1]}'), isTrue);
        }
      }
    });

    test('should_give_every_arrow_a_contiguous_path_of_at_least_two_cells',
        () {
      final arrows =
          ProceduralArrowPlacer().place(bigSquare, random: Random(3));

      for (final a in arrows) {
        expect(a.path.length, greaterThanOrEqualTo(2));
        for (var i = 1; i < a.path.length; i++) {
          final dr = (a.path[i][0] - a.path[i - 1][0]).abs();
          final dc = (a.path[i][1] - a.path[i - 1][1]).abs();
          expect(dr + dc, equals(1),
              reason: 'arrow ${a.id} has non-adjacent path cells');
        }
      }
    });

    test('should_degrade_gracefully_on_a_shape_that_cannot_be_fully_tiled',
        () {
      // Cruz de 5 celdas: cualquier partición en caminos de ≥2 celdas deja
      // al menos 2 brazos sueltos — geométricamente imposible de cubrir.
      final plus = <List<int>>[
        [0, 1],
        [1, 0], [1, 1], [1, 2],
        [2, 1],
      ];
      final arrows = ProceduralArrowPlacer().place(plus, random: Random(1));

      expect(arrows, isNotEmpty);
      expectSolvableInReturnedOrder(plus, arrows);
    });

    test('should_place_nothing_on_a_single_cell_shape', () {
      final arrows = ProceduralArrowPlacer().place(
        const [
          [0, 0],
        ],
        random: Random(1),
      );

      expect(arrows, isEmpty);
    });

    test('should_assign_unique_ids_to_every_placed_arrow', () {
      final arrows =
          ProceduralArrowPlacer().place(bigSquare, random: Random(9));

      expect(arrows.map((a) => a.id).toSet(), hasLength(arrows.length));
    });
  });
}
