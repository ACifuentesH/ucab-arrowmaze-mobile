import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/use_cases/get_hex_level_selection_use_case.dart';
import 'package:arrow_maze/presentation/view_models/level_select_state.dart';

/// Carga y refresca la lista de niveles del MODO HEXAGONAL con su estado de
/// progresión. Espejo de [LevelSelectViewModel] apoyado en el use case hex;
/// reutiliza [LevelSelectState] porque el estado es agnóstico a la topología
/// (opera sobre [LevelSelectEntry], no sobre la forma del tablero).
class HexLevelSelectViewModel extends StateNotifier<LevelSelectState> {
  final GetHexLevelSelectionUseCase _getSelection;

  HexLevelSelectViewModel({required GetHexLevelSelectionUseCase getSelection})
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
