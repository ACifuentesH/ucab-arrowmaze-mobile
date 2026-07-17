import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';

import '../../_support/mothers/level_definition_mother.dart';

void main() {
  group('LevelDefinition — contrato de niveles', () {
    test('should_parse_contract_fields_when_reading_flat_asset_json', () {
      // Arrange
      final json = LevelDefinitionMother.flatJson();
      // Act
      final def = LevelDefinition.fromJson(json);
      // Assert — { cells, arrows:[{id,path,color}], lives } intacto.
      expect(def.lives, equals(5));
      expect(def.timeLimitSeconds, equals(60));
      expect(def.difficulty, equals(Difficulty.medium));
      expect(def.cells, hasLength(3));
      expect(def.arrows, hasLength(1));
      expect(def.arrows.single.id, equals('a1'));
      expect(def.arrows.single.color, equals('#118AB2'));
    });

    test('should_unwrap_data_envelope_when_reading_backend_level_dto', () {
      final def = LevelDefinition.fromBackendJson(
        LevelDefinitionMother.backendDtoJson(),
      );
      expect(def.id, equals('level_1'));
      expect(def.parMoves, equals(10));
      // cells / arrows / lives salen de `data` — el contrato no se altera.
      expect(def.lives, equals(3));
      expect(def.cells, hasLength(3));
      expect(def.arrows.single.path, hasLength(2));
    });

    test('should_default_lives_when_json_omits_them', () {
      final json = LevelDefinitionMother.flatJson()..remove('lives');
      expect(LevelDefinition.fromJson(json).lives, equals(3));
    });

    test('should_preserve_contract_fields_when_round_tripping_to_json', () {
      final original = LevelDefinitionMother.flatJson();
      final def = LevelDefinition.fromJson(original);
      final restored = LevelDefinition.fromJson(def.toJson());
      expect(restored.cells, equals(def.cells));
      expect(restored.lives, equals(def.lives));
      expect(restored.arrows.single.path, equals(def.arrows.single.path));
    });
  });
}
