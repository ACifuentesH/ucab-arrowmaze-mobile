import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

void main() {
  group('TopologyKind — parse', () {
    test('should_return_hex_when_raw_is_hex', () {
      expect(TopologyKind.parse('hex'), equals(TopologyKind.hex));
    });

    test('should_return_square_when_raw_is_square', () {
      expect(TopologyKind.parse('square'), equals(TopologyKind.square));
    });

    test('should_default_to_square_when_raw_is_null', () {
      expect(TopologyKind.parse(null), equals(TopologyKind.square));
    });

    test('should_default_to_square_when_raw_is_garbage', () {
      expect(TopologyKind.parse('triangle'), equals(TopologyKind.square));
      expect(TopologyKind.parse(''), equals(TopologyKind.square));
    });

    test('should_serialize_to_its_name_when_asked', () {
      expect(TopologyKind.hex.name, equals('hex'));
      expect(TopologyKind.square.name, equals('square'));
    });
  });
}
