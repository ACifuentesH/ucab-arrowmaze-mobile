/// Barrel del módulo de Dominio (Capa 1).
/// Pure Dart: sin Flutter, sin BD, sin red. Testeable en aislamiento total.
library;

export 'game_status.dart';
export 'value_objects/cell_id.dart';
export 'value_objects/direction.dart';
export 'value_objects/level_id.dart';
export 'value_objects/move_count.dart';
export 'value_objects/lives.dart';
export 'entities/arrow.dart';
export 'entities/user.dart';
export 'entities/cell/i_cell.dart';
export 'entities/cell/wall_cell.dart';
export 'entities/cell/empty_cell.dart';
export 'entities/node.dart';
export 'aggregates/board.dart';
export 'ports/i_board_graph.dart';
export 'ports/i_topology_strategy.dart';
export 'ports/i_level_repository.dart';
export 'interfaces/i_local_storage.dart';
export 'factories/arrow_spec.dart';
export 'factories/i_arrow_factory.dart';
export 'factories/arrow_factory.dart';
export 'services/adjacency_board_graph.dart';
export 'services/square_grid_topology.dart';
export 'events/domain_events.dart';
