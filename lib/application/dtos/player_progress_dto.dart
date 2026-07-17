/// Progreso remoto del jugador tal como lo expone GET/PUT /progress.
class PlayerProgressDto {
  final String userId;
  final List<String> completedLevels;

  /// `{ levelId: score }` — el backend lo modela como objeto JSON, no array.
  final Map<String, int> bestScores;
  final String currentLevelId;

  const PlayerProgressDto({
    required this.userId,
    required this.completedLevels,
    required this.bestScores,
    required this.currentLevelId,
  });

  factory PlayerProgressDto.fromJson(Map<String, dynamic> json) =>
      PlayerProgressDto(
        userId: json['userId'] as String,
        completedLevels: (json['completedLevels'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        bestScores: _parseBestScores(json['bestScores']),
        currentLevelId: json['currentLevelId'] as String,
      );

  /// Acepta el mapa JSON del backend aunque venga tipado como `Map<dynamic, dynamic>`.
  static Map<String, int> _parseBestScores(Object? raw) {
    if (raw == null) return {};
    if (raw is! Map) return {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): _asInt(entry.value) ?? 0,
    };
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
