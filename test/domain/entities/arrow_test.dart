import 'package:flutter_test/flutter_test.dart';

import '../../_support/mothers/arrow_mother.dart';

void main() {
  group('Arrow', () {
    test('should_expose_tail_and_head_when_path_is_straight', () {
      // Arrange / Act
      final arrow = ArrowMother.eastward();
      // Assert
      expect(arrow.tailCell.value, equals('r1c0'));
      expect(arrow.headCell.value, equals('r1c1'));
    });

    test('should_point_along_last_segment_when_path_bends', () {
      final arrow = ArrowMother.lShaped();
      // El último segmento (1,0)→(1,1) va hacia el Este (index 1).
      expect(arrow.headDirection.index, equals(1));
      expect(arrow.path, hasLength(3));
    });

    test('should_keep_path_immutable_when_exposed', () {
      final arrow = ArrowMother.eastward();
      expect(
        () => arrow.path.removeLast(),
        throwsUnsupportedError,
      );
    });
  });
}
