import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/lives.dart';

void main() {
  group('Lives', () {
    test('should_default_to_three_lives_when_created_without_value', () {
      expect(Lives().value, equals(3));
    });

    test('should_reject_creation_when_value_is_negative', () {
      expect(() => Lives(-1), throwsArgumentError);
    });

    test('should_return_new_decremented_instance_when_decrement_is_called',
        () {
      // Arrange
      final lives = Lives(2);
      // Act
      final after = lives.decrement();
      // Assert (inmutabilidad: la original no cambia)
      expect(after.value, equals(1));
      expect(lives.value, equals(2));
    });

    test('should_stay_at_zero_when_decrementing_exhausted_lives', () {
      expect(Lives(0).decrement().value, equals(0));
    });

    test('should_be_exhausted_when_value_reaches_zero', () {
      expect(Lives(1).decrement().isExhausted, isTrue);
      expect(Lives(1).isExhausted, isFalse);
    });

    test('should_be_equal_when_values_match', () {
      expect(Lives(2), equals(Lives(2)));
    });
  });
}
