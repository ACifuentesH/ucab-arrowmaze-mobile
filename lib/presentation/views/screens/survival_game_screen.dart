import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/presentation/view_models/survival/survival_state.dart';
import 'package:arrow_maze/presentation/views/widgets/board_view.dart';
import 'package:arrow_maze/presentation/views/widgets/hud_view.dart';

class SurvivalGameScreen extends ConsumerStatefulWidget {
  const SurvivalGameScreen({super.key, this.durationSeconds = 120});

  final int durationSeconds;

  @override
  ConsumerState<SurvivalGameScreen> createState() =>
      _SurvivalGameScreenState();
}

class _SurvivalGameScreenState extends ConsumerState<SurvivalGameScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(survivalViewModelProvider.notifier)
        .start(durationSeconds: widget.durationSeconds));
  }

  @override
  Widget build(BuildContext context) {
    final survival = ref.watch(survivalViewModelProvider);
    final gs = ref.watch(gameViewModelProvider);
    final ctrl = ref.read(gameViewModelProvider.notifier);

    final urgent = survival.timeLeft < 10 && survival.phase == SurvivalPhase.running;

    return Scaffold(
      backgroundColor: _t.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              _TopBar(
                timeLeftSeconds: survival.timeLeft,
                boardsCleared: survival.boardsCleared,
                isUrgent: urgent,
              ),
              Expanded(
                child: AbsorbPointer(
                  absorbing:
                      survival.phase == SurvivalPhase.submitting ||
                      survival.phase == SurvivalPhase.ended ||
                      survival.phase == SurvivalPhase.success ||
                      survival.phase == SurvivalPhase.error,
                  child: Column(
                    children: [
                      HudView(
                        gameState: gs,
                        onToggleMute: ctrl.toggleMute,
                        showLevelTimer: false,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: gs.board == null
                              ? const SizedBox.shrink()
                              : BoardView(
                                  board: gs.board!,
                                  escapingArrow: gs.escapingArrow,
                                  lastBlockedArrowId: gs.lastBlockedArrowId,
                                  onTapArrow: ctrl.tapArrow,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (survival.phase == SurvivalPhase.submitting ||
              survival.phase == SurvivalPhase.ended ||
              survival.phase == SurvivalPhase.success ||
              survival.phase == SurvivalPhase.error)
            _SurvivalOverlay(
              survival: survival,
              onBack: () => Navigator.pop(context),
              onRetrySubmit: () => ref
                  .read(survivalViewModelProvider.notifier)
                  .start(durationSeconds: widget.durationSeconds),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.timeLeftSeconds,
    required this.boardsCleared,
    required this.isUrgent,
  });

  final int timeLeftSeconds;
  final int boardsCleared;
  final bool isUrgent;

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _t.boardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.timer,
              color: isUrgent ? const Color(0xFFFF3D68) : _t.hudText, size: 18),
          const SizedBox(width: 6),
          Text(
            _fmt(timeLeftSeconds),
            style: TextStyle(
              color: isUrgent ? const Color(0xFFFF3D68) : _t.hudText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Icon(Icons.layers, color: _t.hudText, size: 18),
          const SizedBox(width: 6),
          Text(
            '$boardsCleared',
            style: TextStyle(
              color: _t.hudText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _SurvivalOverlay extends StatelessWidget {
  const _SurvivalOverlay({
    required this.survival,
    required this.onBack,
    required this.onRetrySubmit,
  });

  final SurvivalState survival;
  final VoidCallback onBack;
  final VoidCallback onRetrySubmit;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Icon(
        Icons.hourglass_bottom_rounded,
        size: 72,
        color: Colors.white.withValues(alpha: 0.95),
      ),
      const SizedBox(height: 16),
      Text(
        survival.phase == SurvivalPhase.success
            ? '¡Registro guardado!'
            : '¡Tiempo Agotado!',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tableros resueltos: ${survival.boardsCleared}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 15,
        ),
      ),
    ];

    if (survival.phase == SurvivalPhase.submitting) {
      children.addAll([
        const SizedBox(height: 24),
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ]);
    }

    if (survival.phase == SurvivalPhase.error && survival.errorMessage != null) {
      children.addAll([
        const SizedBox(height: 16),
        Text(
          survival.errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ]);
    }

    final actions = <Widget>[
      if (survival.phase == SurvivalPhase.success) ...[
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white),
          onPressed: onBack,
          child: const Text(
            'Volver',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ] else if (survival.phase == SurvivalPhase.error) ...[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
          ),
          onPressed: onRetrySubmit,
          child: const Text('Reintentar'),
        ),
      ] else ...[
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white),
          onPressed: onBack,
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ];

    return AbsorbPointer(
      absorbing: false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.58),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children,
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

