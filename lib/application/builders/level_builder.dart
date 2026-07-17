import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/entities/cell/empty_cell.dart';
import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/factories/arrow_factory.dart';
import 'package:arrow_maze/domain/factories/i_arrow_factory.dart';
import 'package:arrow_maze/domain/ports/i_topology_strategy.dart';
import 'package:arrow_maze/domain/services/square_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';

/// Patrón Builder (GoF): ensambla un Board a partir de una LevelDefinition.
/// Valida: todas las celdas del path pertenecen al tablero y no colisionan.
class LevelBuilder {
  final IArrowFactory _arrowFactory;
  final ITopologyStrategy _topology;

  LevelBuilder({
    IArrowFactory? arrowFactory,
    ITopologyStrategy? topology,
  })  : _arrowFactory = arrowFactory ?? ArrowFactory(),
        _topology = topology ?? const SquareGridTopology();

  Board build(LevelDefinition def) {
    // Crear un nodo por cada celda explícita — la forma del tablero es su conjunto.
    final validCells = <CellId>{};
    final nodes = <Node>[];
    for (final rc in def.cells) {
      final cellId = CellId('r${rc[0]}c${rc[1]}');
      validCells.add(cellId);
      nodes.add(Node(id: cellId, content: EmptyCell(id: cellId)));
    }

    final graph = _topology.buildConnections(nodes);

    // Construir flechas y mapa de ocupación
    final arrows = <String, Arrow>{};
    final occupancy = <CellId, String>{};

    for (final spec in def.arrows) {
      final arrow = _arrowFactory.create(spec);
      _validate(arrow, validCells, occupancy);
      arrows[arrow.id] = arrow;
      for (final cell in arrow.path) {
        occupancy[cell] = arrow.id;
      }
    }

    return Board(
      levelId: LevelId(def.id),
      boundingRows: def.maxRow + 1,
      boundingCols: def.maxCol + 1,
      graph: graph,
      arrows: arrows,
      occupancy: occupancy,
      lives: Lives(def.lives),
      timeLimitSeconds: def.timeLimitSeconds,
    );
  }

  void _validate(
    Arrow arrow,
    Set<CellId> validCells,
    Map<CellId, String> occupancy,
  ) {
    for (int i = 0; i < arrow.path.length; i++) {
      final cellId = arrow.path[i];
      if (!validCells.contains(cellId)) {
        throw ArgumentError(
            'Arrow "${arrow.id}": celda $cellId no pertenece al tablero.');
      }
      if (occupancy.containsKey(cellId)) {
        throw ArgumentError(
            'Arrow "${arrow.id}": celda $cellId ya está ocupada por "${occupancy[cellId]}".');
      }
      if (i > 0) {
        final prev = arrow.path[i - 1];
        final prevRc = _parseId(prev.value)!;
        final rc = _parseId(cellId.value)!;
        final dr = (rc.$1 - prevRc.$1).abs();
        final dc = (rc.$2 - prevRc.$2).abs();
        if (dr + dc != 1) {
          throw ArgumentError(
              'Arrow "${arrow.id}": casillas $prev y $cellId no son adyacentes.');
        }
      }
    }
  }

  static (int, int)? _parseId(String id) {
    final m = RegExp(r'^r(\d+)c(\d+)$').firstMatch(id);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }
}
