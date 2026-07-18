import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

/// DTO: definición de un nivel según el esquema JSON del contrato con el
/// backend: `{ cells: [[r,c]], arrows: [{id, path, color}], lives }`.
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

  /// Movimientos "par" del nivel según el backend; null si no está definido.
  final int? parMoves;

  /// Celdas que existen en el tablero como lista de [row, col].
  /// Su conjunto define la forma arbitraria del tablero.
  final List<List<int>> cells;

  /// Especificaciones de flechas multi-casilla.
  final List<ArrowSpec> arrows;

  /// Tiempo límite en segundos; null = sin límite de tiempo.
  final int? timeLimitSeconds;

  /// null en niveles de assets sin campo "difficulty"; se interpreta como easy.
  final Difficulty? difficulty;

  /// Forma topológica del tablero. Default [TopologyKind.square]: los niveles
  /// que no declaran `topology` en el JSON siguen siendo cuadrados.
  final TopologyKind topology;

  const LevelDefinition({
    required this.id,
    required this.name,
    required this.lives,
    required this.cells,
    required this.arrows,
    this.parMoves,
    this.timeLimitSeconds,
    this.difficulty,
    this.topology = TopologyKind.square,
  });

  /// Fila máxima presente en el tablero (útil para la UI al calcular el canvas).
  int get maxRow => cells.fold(0, (m, rc) => rc[0] > m ? rc[0] : m);

  /// Columna máxima presente en el tablero.
  int get maxCol => cells.fold(0, (m, rc) => rc[1] > m ? rc[1] : m);

  /// Parsea el formato "plano" usado en assets/levels/*.json, donde los campos
  /// del contrato (cells, arrows, lives) viven al nivel raíz junto a id/name.
  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    return LevelDefinition(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? (json['id'] as String),
      lives: (json['lives'] as int?) ?? _defaultLives,
      parMoves: json['parMoves'] as int?,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      topology: TopologyKind.parse(json['topology'] as String?),
      cells: _parseCells(json['cells']),
      arrows: _parseArrows(json['arrows']),
    );
  }

  /// Parsea el LevelDto del backend, donde el contrato viaja envuelto:
  /// `{ id, name, difficulty, parMoves, data: { cells, arrows, lives } }`.
  /// El esquema de `data` es EXACTAMENTE el contrato — no se altera.
  factory LevelDefinition.fromBackendJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LevelDefinition(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? (json['id'] as String),
      lives: (data['lives'] as int?) ?? _defaultLives,
      parMoves: json['parMoves'] as int?,
      timeLimitSeconds: data['timeLimitSeconds'] as int?,
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      topology: TopologyKind.parse(data['topology'] as String?),
      cells: _parseCells(data['cells']),
      arrows: _parseArrows(data['arrows']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lives': lives,
        if (parMoves != null) 'parMoves': parMoves,
        if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
        if (difficulty != null) 'difficulty': difficulty!.name,
        // Solo se emite cuando ≠ square: retro-compatibilidad byte a byte con
        // los niveles cuadrados existentes (su JSON no cambia).
        if (topology != TopologyKind.square) 'topology': topology.name,
        'cells': cells,
        'arrows': arrows.map((a) => a.toJson()).toList(),
      };

  static List<List<int>> _parseCells(Object? raw) => (raw as List<dynamic>)
      .map((e) => [
            (e as List<dynamic>)[0] as int,
            e[1] as int,
          ])
      .toList();

  static List<ArrowSpec> _parseArrows(Object? raw) => (raw as List<dynamic>)
      .map((e) => ArrowSpec.fromJson(e as Map<String, dynamic>))
      .toList();

  static Difficulty? _parseDifficulty(String? value) => switch (value) {
        'easy' => Difficulty.easy,
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => null,
      };
}
