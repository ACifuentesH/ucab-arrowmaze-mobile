/// Progreso del jugador en un nivel específico.
class LevelProgress {
  final String levelId;
  final int bestScore;

  /// Tiempo (segundos) del mejor intento completado.
  final int bestTimeSeconds;

  /// Estrellas ganadas (1–3).
  final int starsEarned;

  final DateTime completedAt;

  const LevelProgress({
    required this.levelId,
    required this.bestScore,
    required this.bestTimeSeconds,
    required this.starsEarned,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'bestScore': bestScore,
        'bestTimeSeconds': bestTimeSeconds,
        'starsEarned': starsEarned,
        'completedAt': completedAt.toIso8601String(),
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as String,
        bestScore: _asInt(json['bestScore']) ?? 0,
        bestTimeSeconds: _asInt(json['bestTimeSeconds']) ?? 0,
        starsEarned: (_asInt(json['starsEarned']) ?? 1).clamp(1, 3),
        completedAt: DateTime.parse(json['completedAt'] as String),
      );

  LevelProgress copyWith({
    int? bestScore,
    int? bestTimeSeconds,
    int? starsEarned,
  }) =>
      LevelProgress(
        levelId: levelId,
        bestScore: bestScore ?? this.bestScore,
        bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
        starsEarned: starsEarned ?? this.starsEarned,
        completedAt: completedAt,
      );

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
