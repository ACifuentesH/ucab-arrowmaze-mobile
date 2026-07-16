import 'package:arrow_maze/application/dtos/level_result.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/domain/value_objects/move_count.dart';

enum GamePlayMode { campaign, single, survival }

/// Estado de vista inmutable que GameViewModel emite a la UI.
class GameState {
  final Board? board;
  final LevelId? currentLevelId;

  /// Nombre para mostrar del nivel actual (título de GameScreen). Null para
  /// niveles legacy sin nombre propio — la UI cae de vuelta al id formateado.
  final String? currentLevelName;
  final bool isLoading;
  final String? errorMessage;

  /// Flecha que acaba de escapar; la UI la usa para la animación de salida.
  final Arrow? escapingArrow;

  /// ID de la flecha cuyo movimiento fue bloqueado; dispara la animación shake.
  final String? lastBlockedArrowId;

  /// Segundos transcurridos desde que inició el nivel actual.
  final int elapsedSeconds;

  /// Refleja el estado de silencio del IAudioService.
  final bool isMuted;

  /// Puntuación del nivel recién completado; null mientras se juega.
  final LevelResult? lastResult;

  /// true si en la cola de campaña hay un nivel después del actual.
  final bool hasNextLevel;

  /// Mientras es true, la transición observable a [GameStatus.levelCleared] se
  /// retiene: [status] reporta `playing` aunque el Board ya esté vacío. Da
  /// tiempo a que la animación de escape de la última flecha termine en
  /// BoardView antes de que GameScreen tape el tablero con el overlay de
  /// victoria. El estado de dominio (Board vacío, puntuación registrada) sigue
  /// siendo correcto y síncrono; solo se difiere lo que la UI observa.
  final bool deferLevelCleared;
  final GamePlayMode mode;

  const GameState({
    this.board,
    this.currentLevelId,
    this.currentLevelName,
    this.isLoading = false,
    this.errorMessage,
    this.escapingArrow,
    this.lastBlockedArrowId,
    this.elapsedSeconds = 0,
    this.isMuted = false,
    this.lastResult,
    this.hasNextLevel = false,
    this.deferLevelCleared = false,
    this.mode = GamePlayMode.single,
  });

  const GameState.initial() : this();

  /// Estado observable por la UI. Cuando [deferLevelCleared] está activo,
  /// enmascara `levelCleared` como `playing` durante la ventana de animación
  /// de escape, de modo que el overlay de victoria no aparezca antes de que la
  /// flecha termine de salir visualmente del tablero.
  GameStatus get status {
    final raw = board?.status ?? GameStatus.playing;
    if (deferLevelCleared && raw == GameStatus.levelCleared) {
      return GameStatus.playing;
    }
    return raw;
  }
  Lives get lives => board?.lives ?? Lives();
  MoveCount get moves => board?.moves ?? MoveCount();
  int get arrowCount => board?.arrowCount ?? 0;

  GameState copyWith({
    Board? board,
    LevelId? currentLevelId,
    String? currentLevelName,
    bool clearLevelName = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Arrow? escapingArrow,
    bool clearEscaping = false,
    String? lastBlockedArrowId,
    bool clearBlocked = false,
    int? elapsedSeconds,
    bool? isMuted,
    LevelResult? lastResult,
    bool clearResult = false,
    bool? hasNextLevel,
    bool? deferLevelCleared,
    GamePlayMode? mode,
  }) {
    return GameState(
      board: board ?? this.board,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      currentLevelName:
          clearLevelName ? null : (currentLevelName ?? this.currentLevelName),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      escapingArrow: clearEscaping ? null : (escapingArrow ?? this.escapingArrow),
      lastBlockedArrowId:
          clearBlocked ? null : (lastBlockedArrowId ?? this.lastBlockedArrowId),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isMuted: isMuted ?? this.isMuted,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      hasNextLevel: hasNextLevel ?? this.hasNextLevel,
      deferLevelCleared: deferLevelCleared ?? this.deferLevelCleared,
      mode: mode ?? this.mode,
    );
  }
}
