import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/use_cases/progress/hydrate_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/push_progress_use_case.dart';

/// Adapter de configuración: pull/push + invalidación de Riverpod tras hidratar.
class ProgressSyncCoordinator implements IProgressSyncCoordinator {
  final HydrateProgressUseCase _hydrate;
  final PushProgressUseCase _push;
  final void Function() _onHydrated;

  const ProgressSyncCoordinator({
    required HydrateProgressUseCase hydrate,
    required PushProgressUseCase push,
    required void Function() onHydrated,
  })  : _hydrate = hydrate,
        _push = push,
        _onHydrated = onHydrated;

  @override
  Future<void> pullAndApplyLocal() async {
    await _hydrate.execute();
    _onHydrated();
  }

  @override
  Future<void> pushCompletedLevel({
    required String lastLevelId,
    required int lastScore,
    required int lastMoves,
    required int lastTimeSeconds,
    required String currentLevelId,
  }) =>
      _push.execute(
        lastLevelId: lastLevelId,
        lastScore: lastScore,
        lastMoves: lastMoves,
        lastTimeSeconds: lastTimeSeconds,
        currentLevelId: currentLevelId,
      );
}
