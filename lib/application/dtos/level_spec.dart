import 'package:arrow_maze/application/enums/difficulty.dart';

/// Parámetros que el usuario proporciona para generar un nivel con IA.
///
/// [shapeName] es texto libre — el modelo interpreta cualquier forma
/// ("corazón", "rinoceronte", "nave espacial", "letra A"…).
/// Nuestro código nunca valida ni enumera formas; eso es responsabilidad del AI.
class LevelSpec {
  final String shapeName;
  final int arrowCount;
  final Difficulty difficulty;

  /// null = sin límite de tiempo.
  final int? timeLimitSeconds;

  /// Tamaño del bounding box del grid (gridSize × gridSize).
  /// Rango recomendado: 8 (formas simples) – 25 (figuras detalladas).
  final int gridSize;

  const LevelSpec({
    required this.shapeName,
    required this.arrowCount,
    required this.difficulty,
    this.timeLimitSeconds,
    this.gridSize = 14,
  });

  /// Vidas derivadas de la dificultad.
  int get lives => switch (difficulty) {
        Difficulty.easy => 5,
        Difficulty.medium => 3,
        Difficulty.hard => 1,
      };
}
