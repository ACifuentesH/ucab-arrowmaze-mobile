import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/entities/cell/empty_cell.dart';
import 'package:arrow_maze/domain/entities/node.dart';
import 'package:arrow_maze/domain/factories/arrow_factory.dart';
import 'package:arrow_maze/domain/factories/hex_arrow_factory.dart';
import 'package:arrow_maze/domain/factories/i_arrow_factory.dart';
import 'package:arrow_maze/domain/ports/i_board_graph.dart';
import 'package:arrow_maze/domain/ports/i_topology_strategy.dart';
import 'package:arrow_maze/domain/services/hex_grid_topology.dart';
import 'package:arrow_maze/domain/services/square_grid_topology.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';

/// Patrón Builder (GoF): ensambla un Board a partir de una LevelDefinition.
/// Valida: todas las celdas del path pertenecen al tablero, no colisionan y
/// cada par consecutivo es adyacente SEGÚN LA TOPOLOGÍA (grafo ya construido).
///
/// La topología (y su fábrica de flechas) se elige según `def.topology`:
///   square → (SquareGridTopology, ArrowFactory)
///   hex    → (HexGridTopology,    HexArrowFactory)
/// Los parámetros del constructor son overrides OPCIONALES para tests: si se
/// inyectan, ganan sobre la selección automática.
class LevelBuilder {
  final IArrowFactory? _arrowFactoryOverride;
  final ITopologyStrategy? _topologyOverride;

  LevelBuilder({
    IArrowFactory? arrowFactory,
    ITopologyStrategy? topology,
  })  : _arrowFactoryOverride = arrowFactory,
        _topologyOverride = topology;

  Board build(LevelDefinition def) {
    // Selección automática por la forma del nivel; overrides ganan si existen.
    final topology = _topologyOverride ?? _topologyFor(def.topology);
    final arrowFactory = _arrowFactoryOverride ?? _arrowFactoryFor(def.topology);

    // Crear un nodo por cada celda explícita — la forma del tablero es su conjunto.
    final validCells = <CellId>{};
    final nodes = <Node>[];
    for (final rc in def.cells) {
      final cellId = CellId('r${rc[0]}c${rc[1]}');
      validCells.add(cellId);
      nodes.add(Node(id: cellId, content: EmptyCell(id: cellId)));
    }

    final graph = topology.buildConnections(nodes);

    // Construir flechas y mapa de ocupación
    final arrows = <String, Arrow>{};
    final occupancy = <CellId, String>{};

    for (final spec in def.arrows) {
      final arrow = arrowFactory.create(spec);
      _validate(arrow, validCells, occupancy, graph, topology);
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
      topologyKind: def.topology,
    );
  }

  ITopologyStrategy _topologyFor(TopologyKind kind) => switch (kind) {
        TopologyKind.square => const SquareGridTopology(),
        TopologyKind.hex => const HexGridTopology(),
      };

  IArrowFactory _arrowFactoryFor(TopologyKind kind) => switch (kind) {
        TopologyKind.square => ArrowFactory(),
        TopologyKind.hex => HexArrowFactory(),
      };

  void _validate(
    Arrow arrow,
    Set<CellId> validCells,
    Map<CellId, String> occupancy,
    IBoardGraph graph,
    ITopologyStrategy topology,
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
        // Adyacencia contra el grafo ya construido: el par (prev, cellId) es
        // válido si ALGUNA dirección permitida por la topología conecta prev
        // con cellId. Agnóstico a la forma (cuadrada, hex, ...).
        final prevNode = graph.nodeById(prev)!;
        final adjacent = topology
            .allowedDirections()
            .any((dir) => prevNode.neighborTowards(dir) == cellId);
        if (!adjacent) {
          throw ArgumentError(
              'Arrow "${arrow.id}": casillas $prev y $cellId no son adyacentes.');
        }
      }
    }
  }
}
