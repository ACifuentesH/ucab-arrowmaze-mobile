import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/level_id.dart';

void main() {
  group('LevelId', () {
    test('should_expose_its_value_when_created_with_valid_text', () {
      final id = LevelId('level_1');
      expect(id.value, equals('level_1'));
    });

    test('should_reject_creation_when_value_is_blank', () {
      expect(() => LevelId(''), throwsArgumentError);
    });

    test('should_be_equal_when_values_match', () {
      expect(LevelId('level_1'), equals(LevelId('level_1')));
    });
  });
}
