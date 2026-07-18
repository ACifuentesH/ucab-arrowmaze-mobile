import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/factories/hex_arrow_factory.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';

void main() {
  final factory = HexArrowFactory();

  ArrowSpec spec(List<List<int>> path) =>
      ArrowSpec(id: 'hex', path: path, color: '#118AB2');

  Direction dirOf(List<List<int>> path) => factory.create(spec(path)).headDirection;

  group('HexArrowFactory — head direction from EVEN source row (odd-r)', () {
    // Segmentos que parten de (2,2), fila PAR.
    test('should_point_ne_when_last_segment_goes_up_same_column', () {
      expect(dirOf(const [[2, 2], [1, 2]]), equals(Direction(index: 0, total: 6)));
    });

    test('should_point_e_when_last_segment_goes_right', () {
      expect(dirOf(const [[2, 2], [2, 3]]), equals(Direction(index: 1, total: 6)));
    });

    test('should_point_se_when_last_segment_goes_down_same_column', () {
      expect(dirOf(const [[2, 2], [3, 2]]), equals(Direction(index: 2, total: 6)));
    });

    test('should_point_sw_when_last_segment_goes_down_left', () {
      expect(dirOf(const [[2, 2], [3, 1]]), equals(Direction(index: 3, total: 6)));
    });

    test('should_point_w_when_last_segment_goes_left', () {
      expect(dirOf(const [[2, 2], [2, 1]]), equals(Direction(index: 4, total: 6)));
    });

    test('should_point_nw_when_last_segment_goes_up_left', () {
      expect(dirOf(const [[2, 2], [1, 1]]), equals(Direction(index: 5, total: 6)));
    });
  });

  group('HexArrowFactory — head direction from ODD source row (odd-r)', () {
    // Segmentos que parten de (1,2), fila IMPAR (desplazada media celda).
    test('should_point_ne_when_last_segment_goes_up_right', () {
      expect(dirOf(const [[1, 2], [0, 3]]), equals(Direction(index: 0, total: 6)));
    });

    test('should_point_e_when_last_segment_goes_right', () {
      expect(dirOf(const [[1, 2], [1, 3]]), equals(Direction(index: 1, total: 6)));
    });

    test('should_point_se_when_last_segment_goes_down_right', () {
      expect(dirOf(const [[1, 2], [2, 3]]), equals(Direction(index: 2, total: 6)));
    });

    test('should_point_sw_when_last_segment_goes_down_same_column', () {
      expect(dirOf(const [[1, 2], [2, 2]]), equals(Direction(index: 3, total: 6)));
    });

    test('should_point_w_when_last_segment_goes_left', () {
      expect(dirOf(const [[1, 2], [1, 1]]), equals(Direction(index: 4, total: 6)));
    });

    test('should_point_nw_when_last_segment_goes_up_same_column', () {
      expect(dirOf(const [[1, 2], [0, 2]]), equals(Direction(index: 5, total: 6)));
    });
  });

  group('HexArrowFactory — invalid specs', () {
    test('should_throw_when_path_has_less_than_two_cells', () {
      expect(() => factory.create(spec(const [[0, 0]])), throwsArgumentError);
    });

    test('should_throw_when_segment_is_not_hex_adjacent_from_odd_row', () {
      // (r-1, c-1) desde fila IMPAR es NW en fila PAR, pero NO existe en impar.
      expect(() => factory.create(spec(const [[1, 2], [0, 1]])),
          throwsArgumentError);
    });

    test('should_throw_when_segment_jumps_two_columns', () {
      expect(() => factory.create(spec(const [[0, 0], [0, 2]])),
          throwsArgumentError);
    });
  });
}
