import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/cell_id.dart';

void main() {
  group('CellId', () {
    test('should_expose_its_value_when_created_with_valid_text', () {
      // Arrange / Act
      final id = CellId('r1c2');
      // Assert
      expect(id.value, equals('r1c2'));
    });

    test('should_reject_creation_when_value_is_empty', () {
      expect(() => CellId('   '), throwsArgumentError);
    });

    test('should_be_equal_when_values_match', () {
      expect(CellId('r0c0'), equals(CellId('r0c0')));
      expect(CellId('r0c0').hashCode, equals(CellId('r0c0').hashCode));
    });

    test('should_not_be_equal_when_values_differ', () {
      expect(CellId('r0c0'), isNot(equals(CellId('r0c1'))));
    });
  });
}
