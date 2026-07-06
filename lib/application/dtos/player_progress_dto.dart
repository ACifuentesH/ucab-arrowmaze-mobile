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
        completedLevels: (json['completedLevels'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        bestScores: (json['bestScores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        currentLevelId: json['currentLevelId'] as String,
      );
}
