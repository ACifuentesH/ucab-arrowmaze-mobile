import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/move_count.dart';

void main() {
  group('MoveCount', () {
    test('should_start_at_zero_when_created_without_value', () {
      expect(MoveCount().value, equals(0));
    });

    test('should_reject_creation_when_value_is_negative', () {
      expect(() => MoveCount(-5), throwsArgumentError);
    });

    test('should_return_new_incremented_instance_when_increment_is_called',
        () {
      final moves = MoveCount(1);
      final after = moves.increment();
      expect(after.value, equals(2));
      expect(moves.value, equals(1));
    });

    test('should_be_equal_when_values_match', () {
      expect(MoveCount(4), equals(MoveCount(4)));
    });
  });
}
