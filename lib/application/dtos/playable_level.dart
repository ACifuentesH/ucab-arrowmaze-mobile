import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';

/// Elemento de la cola de juego: lo mínimo que GameViewModel necesita para
/// cargar un nivel y puntuarlo (la dificultad afecta el multiplicador).
class PlayableLevel {
  final String id;
  final Difficulty difficulty;

  /// Nombre para mostrar (título de GameScreen). Null = usa el id formateado
  /// como respaldo (niveles legacy sin nombre propio).
  final String? name;

  const PlayableLevel({required this.id, required this.difficulty, this.name});

  factory PlayableLevel.fromPreview(LevelPreview preview) => PlayableLevel(
        id: preview.id,
        difficulty: preview.difficulty,
        name: preview.name,
      );
}
