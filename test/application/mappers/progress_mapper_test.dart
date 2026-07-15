import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/mappers/progress_mapper.dart';

void main() {
  group('PlayerProgressDto.fromJson — bestScores map', () {
    test('should_parse_best_scores_object_map_not_array', () {
      final dto = PlayerProgressDto.fromJson({
        'userId': 'u-1',
        'completedLevels': ['level_1', 'level_2'],
        'bestScores': {
          'level_1': 900,
          'level_2': 800,
        },
        'currentLevelId': 'level_3',
      });

      expect(dto.bestScores, isA<Map<String, int>>());
      expect(dto.bestScores['level_1'], 900);
      expect(dto.bestScores['level_2'], 800);
    });

    test('should_coerce_numeric_and_string_score_values', () {
      final dto = PlayerProgressDto.fromJson({
        'userId': 'u-1',
        'completedLevels': <String>['level_1'],
        'bestScores': <dynamic, dynamic>{
          'level_1': 900.0,
          'level_2': '750',
        },
        'currentLevelId': 'level_2',
      });

      expect(dto.bestScores['level_1'], 900);
      expect(dto.bestScores['level_2'], 750);
    });
  });

  group('ProgressMapper.toLocalEntries', () {
    test('should_map_scores_from_best_scores_map_and_derive_stars', () {
      const dto = PlayerProgressDto(
        userId: 'u-1',
        completedLevels: ['level_1'],
        bestScores: {'level_1': 900, 'level_2': 400},
        currentLevelId: 'level_3',
      );

      final entries = ProgressMapper.toLocalEntries(dto);

      expect(entries.map((e) => e.levelId), containsAll(['level_1', 'level_2']));
      final l1 = entries.firstWhere((e) => e.levelId == 'level_1');
      expect(l1.bestScore, 900);
      expect(l1.starsEarned, greaterThanOrEqualTo(2));
    });

    test('should_use_catalog_to_compute_stars_when_available', () {
      const dto = PlayerProgressDto(
        userId: 'u-1',
        completedLevels: ['level_1'],
        bestScores: {'level_1': 950},
        currentLevelId: 'level_2',
      );

      final entries = ProgressMapper.toLocalEntries(
        dto,
        catalogById: {
          'level_1': const LevelPreview(
            id: 'level_1',
            name: 'Tutorial',
            source: LevelSource.asset,
            difficulty: Difficulty.easy,
            arrowCount: 5,
            cells: [
              [0, 0],
            ],
          ),
        },
      );

      final l1 = entries.single;
      expect(l1.bestScore, 950);
      expect(l1.starsEarned, 3);
    });
  });
}
