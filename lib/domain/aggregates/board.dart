import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/entities/cell/wall_cell.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/domain/value_objects/direction.dart';
import 'package:arrow_maze/domain/value_objects/move_count.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/domain/ports/i_board_graph.dart';
import 'package:arrow_maze/domain/events/domain_events.dart';
import 'package:arrow_maze/domain/game_status.dart';

/// AGGREGATE ROOT del tablero de Arrow Maze.
///
/// Modelo de datos:
///   _arrows    → mapa arrowId → Arrow (flechas activas en el tablero).
///   _occupancy → mapa CellId → arrowId (qué casilla ocupa qué flecha).
///   _graph     → grafo estático del tablero (celdas vacías y paredes).
///
/// Invariantes:
///   - Solo opera mientras _status == playing.
///   - Una flecha sale si todas las casillas delante de su punta están libres.
///   - Movimiento inválido → (opcional) resta vida → si vidas=0 → gameOver.
///   - Sin flechas → levelCleared.
class Board {
  final LevelId levelId;

  /// Dimensiones del bounding box que contiene todas las celdas del tablero.
  /// No describen la forma — para formas arbitrarias muchas posiciones dentro
  /// de esta caja no existen. La UI las usa para calcular el tamaño de cada celda.
  final int boundingRows;
  final int boundingCols;

  /// Tiempo límite del nivel en segundos; null = sin límite.
  final int? timeLimitSeconds;

  final IBoardGraph _graph;

  final Map<String, Arrow> _arrows;
  final Map<CellId, String> _occupancy;

  GameStatus _status;
  MoveCount _moves;
  Lives _lives;
  final List<DomainEvent> _pendingEvents = [];

  Board({
    required this.levelId,
    required this.boundingRows,
    required this.boundingCols,
    required IBoardGraph graph,
    required Map<String, Arrow> arrows,
    required Map<CellId, String> occupancy,
    Lives? lives,
    this.timeLimitSeconds,
  })  : _graph = graph,
        _arrows = Map.from(arrows),
        _occupancy = Map.from(occupancy),
        _status = GameStatus.playing,
        _moves = MoveCount(),
        _lives = lives ?? Lives();

  GameStatus get status => _status;
  MoveCount get moves => _moves;
  Lives get lives => _lives;
  int get arrowCount => _arrows.length;
  IBoardGraph get graph => _graph;

  /// Vista de solo lectura para la capa de UI.
  Map<String, Arrow> get arrows => Map.unmodifiable(_arrows);
  Map<CellId, String> get occupancy => Map.unmodifiable(_occupancy);

  /// Devuelve la flecha cuyo cuerpo cubre [cellId], o null si está vacía.
  Arrow? arrowAt(CellId cellId) {
    final id = _occupancy[cellId];
    return id != null ? _arrows[id] : null;
  }

  Arrow? arrowById(String id) => _arrows[id];

  /// Intenta sacar la flecha [arrowId] del tablero.
  ///   - Camino libre → extrae flecha, emite ArrowEscaped. Devuelve true.
  ///   - Camino bloqueado → emite MoveBlocked. Devuelve false.
  ///     Si [applyLifePenalty] es true, resta una vida y puede pasar a gameOver.
  bool tryRemoveArrow(String arrowId, {bool applyLifePenalty = true}) {
    if (_status != GameStatus.playing) return false;
    final arrow = _arrows[arrowId];
    if (arrow == null) return false;

    if (_isPathClear(arrow.headCell, arrow.headDirection)) {
      for (final cell in arrow.path) {
        _occupancy.remove(cell);
      }
      _arrows.remove(arrowId);
      _moves = _moves.increment();
      _pendingEvents.add(ArrowEscaped(arrowId: arrowId));

      if (isCleared()) {
        _status = GameStatus.levelCleared;
        _pendingEvents.add(LevelCleared(levelId: levelId));
      }
      return true;
    } else {
      _pendingEvents.add(MoveBlocked(arrowId: arrowId));

      if (applyLifePenalty) {
        _lives = _lives.decrement();
        if (_lives.isExhausted) {
          _status = GameStatus.gameOver;
          _pendingEvents.add(GameOver(levelId: levelId));
        }
      }
      return false;
    }
  }

  /// Restaura una flecha al tablero (usado por RemoveArrowCommand.undo).
  /// Si el nivel estaba "completado" por esa flecha, vuelve a playing.
  void restoreArrow(Arrow arrow) {
    _arrows[arrow.id] = arrow;
    for (final cell in arrow.path) {
      _occupancy[cell] = arrow.id;
    }
    if (_status == GameStatus.levelCleared) {
      _status = GameStatus.playing;
    }
  }

  bool isCleared() => _arrows.isEmpty;

  /// Avanza celda a celda desde la punta de la flecha en su dirección.
  /// Devuelve true si llega al borde del tablero sin encontrar obstáculos.
  bool _isPathClear(CellId startId, Direction direction) {
    CellId? current = _graph.connectedNode(startId, direction);
    while (current != null) {
      if (_occupancy.containsKey(current)) return false;
      final node = _graph.nodeById(current);
      if (node == null) return true;
      if (node.content is WallCell) return false;
      current = _graph.connectedNode(current, direction);
    }
    return true;
  }

  /// Notifica al tablero el tiempo transcurrido (segundos).
  /// Si supera [timeLimitSeconds] emite GameOver (regla de dominio).
  /// El GameViewModel llama esto en cada tick del ITimeService.
  void applyTimeTick(int seconds) {
    if (_status != GameStatus.playing) return;
    if (timeLimitSeconds != null && seconds >= timeLimitSeconds!) {
      _status = GameStatus.gameOver;
      _pendingEvents.add(GameOver(levelId: levelId));
    }
  }

  List<DomainEvent> pullEvents() {
    final out = List<DomainEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    return out;
  }
}
