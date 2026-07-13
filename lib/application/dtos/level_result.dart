/// Resultado de completar un nivel: lo que la pantalla de victoria muestra.
class LevelResult {
  final String levelId;
  final int score;

  /// Estrellas ganadas en ESTE intento (1–3).
  final int stars;

  /// true si este intento superó la mejor puntuación previa.
  final bool isNewBest;

  const LevelResult({
    required this.levelId,
    required this.score,
    required this.stars,
    required this.isNewBest,
  });
}
