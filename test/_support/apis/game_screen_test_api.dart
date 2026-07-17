import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/use_cases/complete_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/restart_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/undo_move_use_case.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';
import 'package:arrow_maze/presentation/views/widgets/board_view.dart';

import '../fakes/fake_audio_service.dart';
import '../fakes/fake_level_repository.dart';
import '../fakes/fake_player_progress_repository.dart';
import '../fakes/fake_time_service.dart';
import '../mothers/level_definition_mother.dart';

/// Testing API (nivel medio) para GameScreen: oculta el wiring del
/// GameViewModel con fakes (repositorio, progreso, audio, reloj) tras una
/// interfaz encadenable given/when/then. El tap se simula sobre el
/// `GestureDetector` real de `BoardView` (comportamiento observable de la
/// UI), no llamando al controller directamente — así la interacción probada
/// es la que el usuario realmente dispara.
class GameScreenTestApi {
  final WidgetTester _tester;
  final FakeLevelRepository _levels = FakeLevelRepository();
  final FakePlayerProgressRepository _progress =
      FakePlayerProgressRepository();
  final CommandInvoker _invoker = CommandInvoker();
  final FakeTimeService _time = FakeTimeService();
  final FakeAudioService _audio = FakeAudioService();

  late final GameViewModel _viewModel = GameViewModel(
    loadLevel: LoadLevelUseCase(repository: _levels),
    removeArrow: RemoveArrowUseCase(invoker: _invoker),
    restart: RestartLevelUseCase(repository: _levels, invoker: _invoker),
    undo: UndoMoveUseCase(invoker: _invoker),
    completeLevel: CompleteLevelUseCase(repository: _progress),
    timeService: _time,
    audioService: _audio,
  );

  GameScreenTestApi(this._tester);

  // ── Given ──────────────────────────────────────────────────────────────────

  /// Tablero 3×3 canónico con una sola flecha 'a1' con el carril despejado:
  /// escapa en un tap y vacía el nivel (levelCleared).
  GameScreenTestApi givenALevelWithAnEscapableArrow({
    String id = 'level_test',
  }) {
    _levels.seed(LevelDefinitionMother.withEscapableArrow(id: id));
    return this;
  }

  /// Tablero 3×3 canónico con 'a1' bloqueada por 'a2': el tap sobre 'a1'
  /// resta una vida en vez de sacarla.
  GameScreenTestApi givenALevelWithABlockedArrow({
    String id = 'level_blocked',
    int lives = 3,
  }) {
    _levels.seed(LevelDefinitionMother.withBlockedArrow(id: id, lives: lives));
    return this;
  }

  Future<GameScreenTestApi> givenTheGameScreenIsOpenAt(String levelId) async {
    await _viewModel.loadLevel(levelId);
    await _tester.pumpWidget(
      ProviderScope(
        overrides: [gameViewModelProvider.overrideWith((ref) => _viewModel)],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      ),
    );
    await _tester.pumpAndSettle();
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  /// Toca el centro del tablero: en el tablero 3×3 canónico de
  /// `LevelDefinitionMother` esa celda (r1c1) siempre es la punta de 'a1'.
  Future<GameScreenTestApi> whenTheBoardIsTappedAtItsCenter() async {
    final gesture = find.descendant(
      of: find.byType(BoardView),
      matching: find.byType(GestureDetector),
    );
    await _tester.tap(gesture);
    await _tester.pumpAndSettle();
    return this;
  }

  /// Igual que [whenTheBoardIsTappedAtItsCenter] pero bombea un único frame en
  /// vez de agotar temporizadores/animaciones: deja el estado justo después
  /// del tap, antes de que expire el retraso de `GameViewModel.tapArrow` que
  /// oculta la transición a `levelCleared` mientras la flecha escapa.
  Future<GameScreenTestApi> whenTheBoardIsTappedWithoutSettling() async {
    final gesture = find.descendant(
      of: find.byType(BoardView),
      matching: find.byType(GestureDetector),
    );
    await _tester.tap(gesture);
    await _tester.pump();
    return this;
  }

  /// Avanza el reloj (fake) del test más allá de
  /// `GameViewModel.victoryRevealDelay`, dejando que la transición observable
  /// a `levelCleared` finalmente ocurra.
  Future<GameScreenTestApi> whenTheEscapeAnimationDelayElapses() async {
    await _tester.pump(
      GameViewModel.victoryRevealDelay + const Duration(milliseconds: 50),
    );
    await _tester.pumpAndSettle();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenTheBoardShouldBeShown() =>
      expect(find.byType(BoardView), findsOneWidget);

  void thenTheArrowShouldHaveEscaped(String arrowId) =>
      expect(_viewModel.state.board!.arrowById(arrowId), isNull);

  void thenLivesShouldBe(int lives) =>
      expect(_viewModel.state.lives.value, equals(lives));

  void thenTheVictoryOverlayShouldBeShown() =>
      expect(find.text('¡Nivel completado!'), findsOneWidget);

  void thenTheVictoryOverlayShouldNotBeShownYet() =>
      expect(find.text('¡Nivel completado!'), findsNothing);

  void thenTheGameOverOverlayShouldBeShown() =>
      expect(find.text('Game Over'), findsOneWidget);

  /// No dispone `_viewModel`: al pasarlo como override a `ProviderScope`,
  /// Riverpod toma posesión y lo dispone al desmontar el árbol de widgets.
  /// Disponerlo aquí también causaría un doble-dispose.
  void dispose() => _time.dispose();
}
