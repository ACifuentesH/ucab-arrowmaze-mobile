import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/survival/survival_state.dart';
import 'package:arrow_maze/presentation/views/screens/survival_leaderboard_screen.dart';
import 'package:arrow_maze/presentation/views/widgets/board_view.dart';
import 'package:arrow_maze/presentation/views/widgets/hud_view.dart';

class SurvivalGameScreen extends ConsumerStatefulWidget {
  const SurvivalGameScreen({super.key, this.durationSeconds = 120});

  final int durationSeconds;

  @override
  ConsumerState<SurvivalGameScreen> createState() => _SurvivalGameScreenState();
}

class _SurvivalGameScreenState extends ConsumerState<SurvivalGameScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(survivalViewModelProvider.notifier)
          .start(durationSeconds: widget.durationSeconds),
    );
  }

  void _playAgain() {
    ref.invalidate(survivalViewModelProvider);
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(survivalViewModelProvider.notifier)
          .start(durationSeconds: widget.durationSeconds);
    });
  }

  void _viewRanking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SurvivalLeaderboardScreen()),
    );
  }

  void _exitToMenu() {
    ref.invalidate(survivalViewModelProvider);
    Navigator.of(context).pop();
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Abandonar partida?'),
        content: const Text('Perderás tu progreso'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (!mounted || shouldExit != true) return;
    _exitToMenu();
  }

  @override
  Widget build(BuildContext context) {
    final survival = ref.watch(survivalViewModelProvider);
    final gs = ref.watch(gameViewModelProvider);
    final ctrl = ref.read(gameViewModelProvider.notifier);

    final urgent =
        survival.timeLeft < 10 && survival.phase == SurvivalPhase.running;

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
                onExit: _confirmExit,
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
                        showLives: false,
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
              onPlayAgain: _playAgain,
              onViewRanking: _viewRanking,
              onExitToMenu: _exitToMenu,
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
    required this.onExit,
  });

  final int timeLeftSeconds;
  final int boardsCleared;
  final bool isUrgent;
  final VoidCallback onExit;

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _t.boardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Abandonar partida',
            onPressed: onExit,
            icon: Icon(Icons.arrow_back, color: _t.hudText),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.timer,
            color: isUrgent ? const Color(0xFFFF3D68) : _t.hudText,
            size: 18,
          ),
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

class _SurvivalOverlay extends ConsumerWidget {
  const _SurvivalOverlay({
    required this.survival,
    required this.onBack,
    required this.onRetrySubmit,
    required this.onPlayAgain,
    required this.onViewRanking,
    required this.onExitToMenu,
  });

  final SurvivalState survival;
  final VoidCallback onBack;
  final VoidCallback onRetrySubmit;
  final VoidCallback onPlayAgain;
  final VoidCallback onViewRanking;
  final VoidCallback onExitToMenu;

  static const ThemeConfig _t = ThemeConfig.dark;
  static const Color _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(authViewModelProvider).isAuthenticated;

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

    if (survival.phase == SurvivalPhase.success && !isAuthenticated) {
      children.addAll([
        const SizedBox(height: 8),
        Text(
          'Puntaje no guardado. Inicia sesión para entrar al ranking.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ]);
    }

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

    if (survival.phase == SurvivalPhase.error &&
        survival.errorMessage != null) {
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

    final Widget actions;
    if (survival.phase == SurvivalPhase.success) {
      actions = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _t.onPrimary,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPlayAgain,
              child: Text(l.survivalPlayAgain),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onViewRanking,
              child: Text(l.survivalViewRanking),
            ),
          ),
        ],
      );
    } else if (survival.phase == SurvivalPhase.error) {
      actions = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onRetrySubmit,
              child: Text(l.survivalLeaderboardRetry),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onExitToMenu,
              child: Text(l.survivalBackToMenu),
            ),
          ),
        ],
      );
    } else {
      actions = FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Colors.white),
        onPressed: onBack,
        child: const Text(
          'OK',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      );
    }

    return AbsorbPointer(
      absorbing: false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.58),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [...children, const SizedBox(height: 24), actions],
            ),
          ),
        ),
      ),
    );
  }
}
