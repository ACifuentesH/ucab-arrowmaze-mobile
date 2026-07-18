import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/presentation/views/widgets/board_geometry.dart';

/// REGRESIÓN: la geometría cuadrada extraída debe reproducir EXACTAMENTE los
/// valores que el `BoardPainter`/`BoardView` calculaban en línea antes del
/// refactor a `IBoardGeometry`. Los valores esperados están derivados a mano y
/// fijados como constantes para que cualquier desviación de píxel falle aquí.
///
/// Contrato original reproducido:
///   - escala de celda: min(w/cols, h/rows)
///   - centro:          ((c+0.5)·cs, (r+0.5)·cs)
///   - outline:         Rect.fromLTWH(c·cs, r·cs, cs, cs)
///   - direcciones:     N(0,-1) E(1,0) S(0,1) O(-1,0)
///   - paso:            cs
///   - hit-test:        ((dy/cs).floor(), (dx/cs).floor()), null fuera de rango
void main() {
  const IBoardGeometry geo = SquareBoardGeometry();
  const double cs = 40; // lado de celda usado en las derivaciones

  group('SquareBoardGeometry — cellScaleFor', () {
    test('should_fit_by_the_smaller_axis_when_container_is_not_square', () {
      // 3×3: contenedor cuadrado justo → 120/3 = 40.
      expect(geo.cellScaleFor(120, 120, 3, 3), 40);
      // Ancho limita: min(120/3, 200/3) = 40.
      expect(geo.cellScaleFor(120, 200, 3, 3), 40);
      // Alto limita: min(200/3, 120/3) = 40.
      expect(geo.cellScaleFor(200, 120, 3, 3), 40);
    });
  });

  group('SquareBoardGeometry — boardSize', () {
    test('should_span_cols_by_rows_cells_when_scaled', () {
      expect(geo.boardSize(3, 4, cs), const Size(160, 120));
      expect(geo.boardSize(2, 2, cs), const Size(80, 80));
    });
  });

  group('SquareBoardGeometry — cellCenter', () {
    test('should_place_center_at_half_cell_offsets_when_asked', () {
      expect(geo.cellCenter(0, 0, cs), const Offset(20, 20));
      expect(geo.cellCenter(1, 2, cs), const Offset(100, 60));
      expect(geo.cellCenter(2, 1, cs), const Offset(60, 100));
    });
  });

  group('SquareBoardGeometry — cellOutline', () {
    test('should_bound_the_exact_cell_rect_when_asked', () {
      expect(geo.cellOutline(0, 0, cs).getBounds(),
          const Rect.fromLTWH(0, 0, 40, 40));
      expect(geo.cellOutline(1, 2, cs).getBounds(),
          const Rect.fromLTWH(80, 40, 40, 40));
    });
  });

  group('SquareBoardGeometry — directionVector', () {
    test('should_return_the_four_unit_axes_when_asked', () {
      expect(geo.directionVector(0), const Offset(0, -1)); // N
      expect(geo.directionVector(1), const Offset(1, 0)); //  E
      expect(geo.directionVector(2), const Offset(0, 1)); //  S
      expect(geo.directionVector(3), const Offset(-1, 0)); // O
    });
  });

  group('SquareBoardGeometry — stepDistance', () {
    test('should_equal_the_cell_side_when_asked', () {
      expect(geo.stepDistance(cs), 40);
    });
  });

  group('SquareBoardGeometry — hitTest', () {
    test('should_map_taps_to_the_containing_cell_when_inside', () {
      expect(geo.hitTest(const Offset(20, 20), cs, 3, 3), (0, 0));
      expect(geo.hitTest(const Offset(100, 60), cs, 3, 3), (1, 2));
      // Justo dentro de la última celda.
      expect(geo.hitTest(const Offset(119, 119), cs, 3, 3), (2, 2));
    });

    test('should_return_null_when_tap_is_outside_the_grid', () {
      expect(geo.hitTest(const Offset(-1, 10), cs, 3, 3), isNull);
      expect(geo.hitTest(const Offset(10, -1), cs, 3, 3), isNull);
      expect(geo.hitTest(const Offset(130, 10), cs, 3, 3), isNull); // col 3
      expect(geo.hitTest(const Offset(10, 130), cs, 3, 3), isNull); // fila 3
    });
  });
}
