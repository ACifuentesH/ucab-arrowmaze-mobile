import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/factories/arrow_factory.dart';

import '../../_support/mothers/arrow_mother.dart';

void main() {
  final factory = ArrowFactory();

  group('ArrowFactory', () {
    test('should_derive_east_direction_when_last_segment_goes_right', () {
      final arrow = factory.create(ArrowMother.eastwardSpec());
      expect(arrow.headDirection.index, equals(1)); // E
    });

    test('should_derive_south_direction_when_last_segment_goes_down', () {
      final arrow = factory.create(ArrowMother.southwardSpec());
      expect(arrow.headDirection.index, equals(2)); // S
    });

    test('should_use_only_the_last_segment_when_path_bends', () {
      final arrow = factory.create(ArrowMother.lShapedSpec());
      expect(arrow.headDirection.index, equals(1)); // termina yendo al Este
    });

    test('should_translate_row_col_pairs_into_cell_ids_when_creating', () {
      final arrow = factory.create(ArrowMother.eastwardSpec());
      expect(arrow.path.map((c) => c.value), equals(['r1c0', 'r1c1']));
    });

    test('should_reject_creation_when_path_has_a_single_cell', () {
      expect(
        () => factory.create(ArrowMother.singleCellSpec()),
        throwsArgumentError,
      );
    });

    test('should_reject_creation_when_cells_are_not_orthogonally_adjacent',
        () {
      expect(
        () => factory.create(ArrowMother.nonAdjacentSpec()),
        throwsArgumentError,
      );
    });
  });
}
