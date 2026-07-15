import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/events/domain_events.dart';
import 'package:arrow_maze/domain/ports/i_time_service.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/application/dtos/playable_level.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/enums/sound_effect.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/use_cases/complete_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/i_remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/restart_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/undo_move_use_case.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';

/// Gestor de estado (Observer pattern): conecta casos de uso con la UI.
/// Observa los DomainEvents del Board para disparar audio y controlar el reloj.
class GameViewModel extends StateNotifier<GameState> {
  final LoadLevelUseCase _loadLevel;
  final IRemoveArrowUseCase _removeArrow;
  final RestartLevelUseCase _restart;
  final UndoMoveUseCase _undo;
  final CompleteLevelUseCase _completeLevel;
  final ITimeService _timeService;
  final IAudioService _audioService;
  final IProgressSyncCoordinator? _progressSync;

  StreamSubscription<int>? _timeSub;

  /// Cola de juego actual (campaña o nivel suelto) y posición dentro de ella.
  List<PlayableLevel> _queue = const [];
  int _queueIndex = 0;

  /// Foto del tablero al arrancar el nivel; alimenta la puntuación.
  int _initialArrowCount = 0;
  int _initialLives = 0;

  GameViewModel({
    required LoadLevelUseCase loadLevel,
    required IRemoveArrowUseCase removeArrow,
    required RestartLevelUseCase restart,
    required UndoMoveUseCase undo,
    required CompleteLevelUseCase completeLevel,
    required ITimeService timeService,
    required IAudioService audioService,
    IProgressSyncCoordinator? progressSync,
  })  : _loadLevel = loadLevel,
        _removeArrow = removeArrow,
        _restart = restart,
        _undo = undo,
        _completeLevel = completeLevel,
        _timeService = timeService,
        _audioService = audioService,
        _progressSync = progressSync,
        super(const GameState.initial());

  /// Juega una secuencia de niveles (la campaña): al completar uno, la UI
  /// puede pedir el siguiente con [playNext].
  Future<void> startCampaign(
    List<PlayableLevel> queue, {
    int startIndex = 0,
  }) {
    _queue = List.unmodifiable(queue);
    _queueIndex = startIndex;
    return _loadCurrent();
  }

  /// Juega un nivel suelto (ej. generado por IA).
  Future<void> loadLevel(
    String levelId, {
    Difficulty difficulty = Difficulty.easy,
  }) {
    _queue = [PlayableLevel(id: levelId, difficulty: difficulty)];
    _queueIndex = 0;
    return _loadCurrent();
  }

  bool get _hasNext => _queueIndex + 1 < _queue.length;

  /// Avanza al siguiente nivel de la cola (habilitado tras completar).
  Future<void> playNext() async {
    if (!_hasNext) return;
    _queueIndex++;
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final level = _queue[_queueIndex];
    _stopTimer();
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      final board = await _loadLevel.execute(LevelId(level.id));
      _initialArrowCount = board.arrowCount;
      _initialLives = board.lives.value;
      state = state.copyWith(
        board: board,
        currentLevelId: LevelId(level.id),
        isLoading: false,
        elapsedSeconds: 0,
        clearBlocked: true,
        clearEscaping: true,
        hasNextLevel: _hasNext,
      );
      _startTimer();
      await _audioService.playMusic();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Toca la flecha [arrowId]. La UI obtiene el arrowId via hit-test del Board.
  bool tapArrow(String arrowId) {
    final board = state.board;
    if (board == null) return false;

    final arrowSnapshot = board.arrowById(arrowId);
    final valid = _removeArrow.execute(board, arrowId);

    if (valid) {
      state = state.copyWith(
        board: board,
        escapingArrow: arrowSnapshot,
        clearBlocked: true,
      );
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) state = state.copyWith(clearEscaping: true);
      });
    } else {
      state = state.copyWith(
        board: board,
        lastBlockedArrowId: arrowId,
      );
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) state = state.copyWith(clearBlocked: true);
      });
    }

    // Observer: procesa los DomainEvents emitidos por Board → dispara audio.
    _processEvents(board);
    return valid;
  }

  Future<void> restart() async {
    _stopTimer();
    final id = state.currentLevelId;
    if (id == null) return;
    state = state.copyWith(
        isLoading: true, clearBlocked: true, clearEscaping: true, clearResult: true);
    try {
      final board = await _restart.execute(id);
      _initialArrowCount = board.arrowCount;
      _initialLives = board.lives.value;
      state = state.copyWith(board: board, isLoading: false, elapsedSeconds: 0);
      _startTimer();
      await _audioService.playMusic();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void undo() {
    final board = state.board;
    if (board == null) return;
    _undo.execute();
    state = state.copyWith(board: board, clearBlocked: true, clearEscaping: true);
  }

  void toggleMute() {
    _audioService.toggleMute();
    state = state.copyWith(isMuted: _audioService.isMuted);
  }

  @override
  void dispose() {
    _timeSub?.cancel();
    _timeService.stop();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timeSub?.cancel();
    _timeService.reset();
    _timeService.start();
    _timeSub = _timeService.elapsed.listen(_onTick);
  }

  void _stopTimer() {
    _timeSub?.cancel();
    _timeSub = null;
    _timeService.stop();
    _timeService.reset();
  }

  void _onTick(int seconds) {
    if (!mounted) return;
    final board = state.board;
    if (board == null) return;
    board.applyTimeTick(seconds);
    _processEvents(board);
    if (mounted) state = state.copyWith(elapsedSeconds: seconds);
  }

  // ── Observer: DomainEvents → audio ────────────────────────────────────────

  void _processEvents(Board board) {
    for (final event in board.pullEvents()) {
      if (event is ArrowEscaped) {
        _audioService.playSfx(SoundEffect.arrowEscaped);
      } else if (event is MoveBlocked) {
        _audioService.playSfx(SoundEffect.moveBlocked);
      } else if (event is LevelCleared) {
        _audioService.playSfx(SoundEffect.levelCleared);
        _audioService.stopMusic();
        _stopTimer();
        unawaited(_registerCompletion(board));
      } else if (event is GameOver) {
        _audioService.playSfx(SoundEffect.gameOver);
        _audioService.stopMusic();
        _stopTimer();
      }
    }
  }

  /// Puntúa el nivel completado y persiste el mejor intento (local).
  Future<void> _registerCompletion(Board board) async {
    if (_queue.isEmpty) return;
    final level = _queue[_queueIndex];
    final moves = board.moves.value;
    final elapsedSeconds = state.elapsedSeconds;

    final result = await _completeLevel.execute(
      levelId: level.id,
      difficulty: level.difficulty,
      initialArrowCount: _initialArrowCount,
      initialLives: _initialLives,
      livesRemaining: board.lives.value,
      elapsedSeconds: elapsedSeconds,
      timeLimitSeconds: board.timeLimitSeconds,
    );
    if (mounted) state = state.copyWith(lastResult: result);

    final sync = _progressSync;
    if (sync == null) return;

    final currentLevelId =
        _hasNext ? _queue[_queueIndex + 1].id : level.id;
    // Asíncrono y no bloqueante: fallos remotos no tumbarán la victoria.
    unawaited(sync.pushCompletedLevel(
      lastLevelId: level.id,
      lastScore: result.score,
      lastMoves: moves,
      lastTimeSeconds: elapsedSeconds,
      currentLevelId: currentLevelId,
    ));
  }
}
