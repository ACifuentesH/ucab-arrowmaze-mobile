import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_status.dart';

/// Entrada de la pantalla de selección: preview + estado de progresión.
class LevelSelectEntry {
  final LevelPreview preview;
  final LevelStatus status;

  /// Estrellas del mejor intento (0 si no se ha completado).
  final int stars;

  /// Mejor puntuación registrada; null si no se ha completado.
  final int? bestScore;

  const LevelSelectEntry({
    required this.preview,
    required this.status,
    this.stars = 0,
    this.bestScore,
  });

  bool get isPlayable => status != LevelStatus.locked;
}
