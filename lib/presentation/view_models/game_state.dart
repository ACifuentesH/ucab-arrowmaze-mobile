import 'package:arrow_maze/application/dtos/level_result.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/domain/value_objects/lives.dart';
import 'package:arrow_maze/domain/value_objects/move_count.dart';

/// Estado de vista inmutable que GameViewModel emite a la UI.
class GameState {
  final Board? board;
  final LevelId? currentLevelId;
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

  const GameState({
    this.board,
    this.currentLevelId,
    this.isLoading = false,
    this.errorMessage,
    this.escapingArrow,
    this.lastBlockedArrowId,
    this.elapsedSeconds = 0,
    this.isMuted = false,
    this.lastResult,
    this.hasNextLevel = false,
  });

  const GameState.initial() : this();

  GameStatus get status => board?.status ?? GameStatus.playing;
  Lives get lives => board?.lives ?? Lives();
  MoveCount get moves => board?.moves ?? MoveCount();
  int get arrowCount => board?.arrowCount ?? 0;

  GameState copyWith({
    Board? board,
    LevelId? currentLevelId,
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
  }) {
    return GameState(
      board: board ?? this.board,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      escapingArrow: clearEscaping ? null : (escapingArrow ?? this.escapingArrow),
      lastBlockedArrowId:
          clearBlocked ? null : (lastBlockedArrowId ?? this.lastBlockedArrowId),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isMuted: isMuted ?? this.isMuted,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      hasNextLevel: hasNextLevel ?? this.hasNextLevel,
    );
  }
}
