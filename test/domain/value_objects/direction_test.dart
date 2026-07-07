import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/direction.dart';

void main() {
  group('Direction', () {
    test('should_expose_index_and_total_when_created_within_range', () {
      final dir = Direction(index: 1, total: 4);
      expect(dir.index, equals(1));
      expect(dir.total, equals(4));
    });

    test('should_reject_creation_when_index_is_out_of_range', () {
      expect(() => Direction(index: 4, total: 4), throwsArgumentError);
      expect(() => Direction(index: -1, total: 4), throwsArgumentError);
    });

    test('should_reject_creation_when_total_is_not_positive', () {
      expect(() => Direction(index: 0, total: 0), throwsArgumentError);
    });

    test('should_advance_clockwise_when_next_is_called', () {
      final north = Direction(index: 0, total: 4);
      expect(north.next(), equals(Direction(index: 1, total: 4)));
    });

    test('should_wrap_to_first_port_when_next_passes_the_last_one', () {
      final west = Direction(index: 3, total: 4);
      expect(west.next(), equals(Direction(index: 0, total: 4)));
    });

    test('should_be_equal_when_index_and_total_match', () {
      expect(Direction(index: 2, total: 4), equals(Direction(index: 2, total: 4)));
      expect(Direction(index: 2, total: 4),
          isNot(equals(Direction(index: 2, total: 6))));
    });
  });
}
