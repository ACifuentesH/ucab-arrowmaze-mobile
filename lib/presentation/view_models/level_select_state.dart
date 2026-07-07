import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/enums/level_source.dart';

/// Estado inmutable de la pantalla de selección de niveles.
class LevelSelectState {
  final List<LevelSelectEntry> entries;
  final bool isLoading;
  final String? errorMessage;

  const LevelSelectState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Niveles de la campaña (assets), en orden de progresión.
  List<LevelSelectEntry> get campaign => entries
      .where((e) => e.preview.source == LevelSource.asset)
      .toList(growable: false);

  /// Niveles generados con IA (nunca bloqueados).
  List<LevelSelectEntry> get generated => entries
      .where((e) => e.preview.source == LevelSource.generated)
      .toList(growable: false);

  LevelSelectState copyWith({
    List<LevelSelectEntry>? entries,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LevelSelectState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
