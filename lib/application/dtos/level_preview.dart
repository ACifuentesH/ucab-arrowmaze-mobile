import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

/// Resumen de un nivel para mostrarlo en el catálogo / pantalla de selección.
class LevelPreview {
  final String id;
  final String name;
  final LevelSource source;
  final Difficulty difficulty;
  final int? timeLimitSeconds;
  final int arrowCount;

  /// Celdas del tablero: permiten renderizar una miniatura.
  final List<List<int>> cells;

  /// Forma del tablero: la miniatura la usa para dibujar celdas cuadradas o hex.
  final TopologyKind topology;

  const LevelPreview({
    required this.id,
    required this.name,
    required this.source,
    required this.difficulty,
    required this.arrowCount,
    required this.cells,
    this.timeLimitSeconds,
    this.topology = TopologyKind.square,
  });

  factory LevelPreview.fromDefinition(
    LevelDefinition def, {
    required LevelSource source,
  }) {
    return LevelPreview(
      id: def.id,
      name: def.name,
      source: source,
      difficulty: def.difficulty ?? Difficulty.easy,
      timeLimitSeconds: def.timeLimitSeconds,
      arrowCount: def.arrows.length,
      cells: def.cells,
      topology: def.topology,
    );
  }
}
