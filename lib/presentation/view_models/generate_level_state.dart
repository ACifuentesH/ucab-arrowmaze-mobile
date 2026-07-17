import 'package:flutter/foundation.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';

enum GenerateStatus { idle, loading, success, error }

@immutable
class GenerateLevelState {
  final String shapeName;
  final Difficulty difficulty;
  final bool hasTimeLimit;
  final int timeLimitSeconds;
  final GenerateStatus status;
  final LevelPreview? result;
  final String? errorMessage;

  const GenerateLevelState({
    required this.shapeName,
    required this.difficulty,
    required this.hasTimeLimit,
    required this.timeLimitSeconds,
    required this.status,
    this.result,
    this.errorMessage,
  });

  factory GenerateLevelState.initial() => const GenerateLevelState(
        shapeName: '',
        difficulty: Difficulty.easy,
        hasTimeLimit: false,
        timeLimitSeconds: 60,
        status: GenerateStatus.idle,
      );

  GenerateLevelState copyWith({
    String? shapeName,
    Difficulty? difficulty,
    bool? hasTimeLimit,
    int? timeLimitSeconds,
    GenerateStatus? status,
    LevelPreview? result,
    String? errorMessage,
  }) =>
      GenerateLevelState(
        shapeName: shapeName ?? this.shapeName,
        difficulty: difficulty ?? this.difficulty,
        hasTimeLimit: hasTimeLimit ?? this.hasTimeLimit,
        timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get canGenerate =>
      shapeName.trim().isNotEmpty && status != GenerateStatus.loading;
}
