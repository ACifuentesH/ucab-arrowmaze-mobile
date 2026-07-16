// Campos privados + parametros con nombre: Dart no permite inicializadores
// formales privados en parametros nombrados.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/submit_survival_input.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';
import 'package:arrow_maze/application/use_cases/survival/submit_survival_run_use_case.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';
import 'package:arrow_maze/presentation/view_models/survival/survival_state.dart';

class SurvivalViewModel extends StateNotifier<SurvivalState> {
  final GameViewModel _game;
  final SubmitSurvivalRunUseCase _submitSurvivalRun;
  final ILevelCatalogService _levelCatalog;
  final IAudioService _audioService;

  Timer? _timer;
  bool _advancingToNext = false;

  final math.Random _rng = math.Random();
  List<LevelPreview> _levels = const [];
  int _durationSeconds = 120;

  SurvivalViewModel({
    required GameViewModel game,
    required SubmitSurvivalRunUseCase submitSurvivalRun,
    required ILevelCatalogService levelCatalog,
    required IAudioService audioService,
  })  : _game = game,
        _submitSurvivalRun = submitSurvivalRun,
        _levelCatalog = levelCatalog,
        _audioService = audioService,
        super(const SurvivalState.initial());

  Future<void> start({
    int durationSeconds = 120,
    bool autoLoadFirstLevel = true,
  }) async {
    // Permitimos reiniciar si:
    // - aún no comenzó (initial)
    // - falló el submit (error)
    if (state.phase != SurvivalPhase.initial &&
        state.phase != SurvivalPhase.error) {
      return;
    }

    _durationSeconds = durationSeconds;
    _timer?.cancel();
    _timer = null;
    _advancingToNext = false;

    state = SurvivalState(
      timeLeft: durationSeconds,
      boardsCleared: 0,
      phase: SurvivalPhase.running,
      errorMessage: null,
    );

    // 1) Carga el pool de niveles (catálogo local + generados).
    final levels = await _levelCatalog.getLevels();
    _levels = levels;

    if (autoLoadFirstLevel && levels.isNotEmpty) {
      await _loadRandomLevel();
    }

    // 2) Timer global (120s).
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final left = state.timeLeft;

      if (left <= 1) {
        await _onTimeExpired();
        return;
      }

      state = state.copyWith(timeLeft: left - 1);
    });
  }

  void onGameStateChanged(GameState gameState) {
    if (state.phase != SurvivalPhase.running) return;
    if (_advancingToNext) return;

    if (gameState.status == GameStatus.levelCleared) {
      _advancingToNext = true;
      state = state.copyWith(boardsCleared: state.boardsCleared + 1);

      Future.delayed(GameViewModel.victoryRevealDelay, () async {
        if (!mounted || state.phase != SurvivalPhase.running) return;
        await _loadRandomLevel();
        _advancingToNext = false;
      });
      return;
    }

    // Derrota: cargamos otro tablero pero no incrementamos boardsCleared.
    if (gameState.status == GameStatus.gameOver) {
      _advancingToNext = true;

      Future.delayed(const Duration(milliseconds: 450), () async {
        if (!mounted || state.phase != SurvivalPhase.running) return;
        await _loadRandomLevel();
        _advancingToNext = false;
      });
    }
  }

  Future<void> _onTimeExpired() async {
    _timer?.cancel();
    _timer = null;

    // Detiene feedback musical; la pantalla ya no es interactiva.
    await _audioService.stopMusic();

    state = state.copyWith(phase: SurvivalPhase.submitting, errorMessage: null);

    final playedDurationSeconds = _durationSeconds; // llega a 0s siempre
    final input = SubmitSurvivalInput(
      boardsSolved: state.boardsCleared,
      durationSeconds: playedDurationSeconds,
      totalScore: null,
    );

    try {
      await _submitSurvivalRun.execute(input);
      if (!mounted) return;
      state = state.copyWith(phase: SurvivalPhase.success);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        phase: SurvivalPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _loadRandomLevel() async {
    if (!mounted) return;
    if (_levels.isEmpty) return;

    final level = _levels[_rng.nextInt(_levels.length)];
    // LevelPreview
    await _game.loadLevel(
      level.id,
      difficulty: level.difficulty,
      mode: GamePlayMode.survival,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

