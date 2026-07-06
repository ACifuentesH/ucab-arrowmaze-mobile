import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';

/// DTO: definición de un nivel según el nuevo esquema JSON.
/// El LevelBuilder lo consume para construir el Board.
///
/// La forma del tablero se define por la lista explícita de [cells] que existen.
/// No hay rows/cols globales ni walls: si una celda no está en [cells], no existe.
/// Esto permite tableros de cualquier forma (corazón, rombo, L, etc.).
class LevelDefinition {
  static const int _defaultLives = 3;

  final String id;
  final String name;
  final int lives;

  /// Celdas que existen en el tablero como lista de [row, col].
  /// Su conjunto define la forma arbitraria del tablero.
  final List<List<int>> cells;

  /// Especificaciones de flechas multi-casilla.
  final List<ArrowSpec> arrows;

  /// Tiempo límite en segundos; null = sin límite de tiempo.
  final int? timeLimitSeconds;

  /// null en niveles de assets sin campo "difficulty"; se interpreta como easy.
  final Difficulty? difficulty;

  const LevelDefinition({
    required this.id,
    required this.name,
    required this.lives,
    required this.cells,
    required this.arrows,
    this.timeLimitSeconds,
    this.difficulty,
  });

  /// Fila máxima presente en el tablero (útil para la UI al calcular el canvas).
  int get maxRow => cells.fold(0, (m, rc) => rc[0] > m ? rc[0] : m);

  /// Columna máxima presente en el tablero.
  int get maxCol => cells.fold(0, (m, rc) => rc[1] > m ? rc[1] : m);

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    return LevelDefinition(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? (json['id'] as String),
      lives: (json['lives'] as int?) ?? _defaultLives,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      cells: (json['cells'] as List<dynamic>)
          .map((e) => [
                (e as List<dynamic>)[0] as int,
                e[1] as int,
              ])
          .toList(),
      arrows: (json['arrows'] as List<dynamic>)
          .map((e) => ArrowSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lives': lives,
        if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
        if (difficulty != null) 'difficulty': difficulty!.name,
        'cells': cells,
        'arrows': arrows.map((a) => a.toJson()).toList(),
      };

  static Difficulty? _parseDifficulty(String? value) => switch (value) {
        'easy' => Difficulty.easy,
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => null,
      };
}
