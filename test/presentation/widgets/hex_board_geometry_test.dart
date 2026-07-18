import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/services/hex_grid_topology.dart';
import 'package:arrow_maze/presentation/views/widgets/board_geometry.dart';
import 'package:arrow_maze/presentation/views/widgets/hex_board_geometry.dart';

/// Verifica la geometría hexagonal pointy-top odd-r: el desplazamiento de media
/// celda en filas impares, los 6 vectores unitarios de dirección, la propiedad
/// clave `stepDistance == distancia real entre vecinas` en las 6 direcciones, y
/// el hit-test Voronoi (centro más cercano gana; fuera del tablero → null).
void main() {
  const IBoardGeometry geo = HexBoardGeometry();
  final double sqrt3 = math.sqrt(3);
  const double s = 10; // circumradio usado en las derivaciones

  group('HexBoardGeometry — cellCenter parity offset', () {
    test('should_shift_odd_rows_half_a_cell_right_when_compared_to_even', () {
      final even = geo.cellCenter(0, 0, s); // fila par
      final odd = geo.cellCenter(1, 0, s); //  fila impar
      // Media celda = √3·s/2 (medio ancho de hexágono pointy-top).
      expect(odd.dx - even.dx, closeTo(sqrt3 * s / 2, 1e-9));
      // Filas pares comparten la x de columna (sin desplazamiento).
      expect(geo.cellCenter(2, 0, s).dx, closeTo(even.dx, 1e-9));
    });

    test('should_space_rows_by_one_and_a_half_cells_when_asked', () {
      expect(geo.cellCenter(1, 0, s).dy - geo.cellCenter(0, 0, s).dy,
          closeTo(1.5 * s, 1e-9));
    });
  });

  group('HexBoardGeometry — directionVector', () {
    test('should_return_six_unit_vectors_when_asked', () {
      for (int i = 0; i < 6; i++) {
        expect(geo.directionVector(i).distance, closeTo(1.0, 1e-9),
            reason: 'dir $i debe ser unitario');
      }
    });

    test('should_match_the_hex_axes_when_asked', () {
      expect(geo.directionVector(1), const Offset(1, 0)); //  E
      expect(geo.directionVector(4), const Offset(-1, 0)); // W
      // NE apunta hacia arriba en pantalla → y negativa.
      expect(geo.directionVector(0).dy, lessThan(0));
      expect(geo.directionVector(2).dy, greaterThan(0)); // SE hacia abajo
    });
  });

  group('HexBoardGeometry — stepDistance', () {
    test('should_equal_center_to_center_distance_in_all_six_directions', () {
      final expected = sqrt3 * s;
      expect(geo.stepDistance(s), closeTo(expected, 1e-9));

      // Propiedad clave: para orígenes de fila PAR e IMPAR, la distancia real
      // entre el centro y el de cada vecino (tabla odd-r) es uniforme = √3·s.
      for (final origin in const [(2, 2), (3, 2)]) {
        final (or, oc) = origin;
        final center = geo.cellCenter(or, oc, s);
        for (int i = 0; i < 6; i++) {
          final (nr, nc) = HexGridTopology.neighborOffset(i, or, oc);
          final d = (geo.cellCenter(nr, nc, s) - center).distance;
          expect(d, closeTo(expected, 1e-9),
              reason: 'origen $origin dir $i');
        }
      }
    });
  });

  group('HexBoardGeometry — boardSize / cellScaleFor roundtrip', () {
    test('should_recover_the_scale_when_fed_its_own_board_size', () {
      final size = geo.boardSize(3, 3, s);
      // Derivados: ancho = √3·10·3 + √3/2·10; alto = 1.5·10·2 + 2·10.
      expect(size.width, closeTo(sqrt3 * 30 + sqrt3 * 5, 1e-9));
      expect(size.height, closeTo(50, 1e-9));
      expect(geo.cellScaleFor(size.width, size.height, 3, 3),
          closeTo(s, 1e-9));
    });
  });

  group('HexBoardGeometry — hitTest', () {
    test('should_hit_the_cell_when_tapping_its_exact_center', () {
      // Celdas de fila par e impar.
      for (final cell in const [(0, 0), (1, 1), (2, 0), (0, 2)]) {
        final (r, c) = cell;
        final center = geo.cellCenter(r, c, s);
        expect(geo.hitTest(center, s, 3, 3), cell,
            reason: 'centro exacto de $cell');
      }
    });

    test('should_resolve_to_the_nearer_hex_when_tap_is_near_a_border', () {
      // Frontera vertical entre (0,0) y (0,1) está en x = √3·s (≈17.32), y=10.
      final border = sqrt3 * s;
      expect(geo.hitTest(Offset(border - 0.5, 10), s, 3, 3), (0, 0));
      expect(geo.hitTest(Offset(border + 0.5, 10), s, 3, 3), (0, 1));
    });

    test('should_return_null_when_tap_is_outside_the_board', () {
      expect(geo.hitTest(const Offset(200, 200), s, 3, 3), isNull);
      expect(geo.hitTest(const Offset(-20, -20), s, 3, 3), isNull);
      // Justo encima del centro de (0,0) a más de un circumradio.
      expect(geo.hitTest(const Offset(8.66, -5), s, 3, 3), isNull);
    });
  });
}
