import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';
import 'package:arrow_maze/application/use_cases/generate_level_use_case.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_state.dart';

class GenerateLevelViewModel extends StateNotifier<GenerateLevelState> {
  final GenerateLevelUseCase _useCase;

  /// Tablero grande y fijo: figuras a gran escala, reconocibles.
  /// El usuario ya no decide el tamaño ni el número de flechas.
  static const int _gridSize = 22;

  GenerateLevelViewModel(this._useCase) : super(GenerateLevelState.initial());

  void setShapeName(String v) =>
      state = state.copyWith(shapeName: v, status: GenerateStatus.idle);

  void setDifficulty(Difficulty v) => state = state.copyWith(difficulty: v);

  void setHasTimeLimit(bool v) => state = state.copyWith(hasTimeLimit: v);

  void setTimeLimitSeconds(int v) =>
      state = state.copyWith(timeLimitSeconds: v);

  Future<void> generate() async {
    if (!state.canGenerate) return;

    state = state.copyWith(
      status: GenerateStatus.loading,
      result: null,
      errorMessage: null,
    );

    try {
      final spec = LevelSpec(
        shapeName: state.shapeName.trim(),
        difficulty: state.difficulty,
        timeLimitSeconds: state.hasTimeLimit ? state.timeLimitSeconds : null,
        gridSize: _gridSize,
      );
      final preview = await _useCase.execute(spec);
      state = state.copyWith(status: GenerateStatus.success, result: preview);
    } on LevelGenerationException catch (e) {
      state = state.copyWith(
        status: GenerateStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: GenerateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = GenerateLevelState.initial();
}
