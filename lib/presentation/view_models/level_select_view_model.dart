import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/use_cases/get_level_selection_use_case.dart';
import 'package:arrow_maze/presentation/view_models/level_select_state.dart';

/// Carga y refresca la lista de niveles con su estado de progresión.
class LevelSelectViewModel extends StateNotifier<LevelSelectState> {
  final GetLevelSelectionUseCase _getSelection;

  LevelSelectViewModel({required GetLevelSelectionUseCase getSelection})
      : _getSelection = getSelection,
        super(const LevelSelectState());

  /// Se llama al abrir la pantalla y al volver de un nivel (el progreso
  /// pudo haber desbloqueado el siguiente).
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _getSelection.execute();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
