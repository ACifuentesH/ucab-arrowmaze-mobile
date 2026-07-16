import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze/application/dtos/level_result.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';
import 'package:arrow_maze/presentation/views/widgets/board_view.dart';
import 'package:arrow_maze/presentation/views/widgets/hud_view.dart';

/// Pantalla de juego: tablero + HUD + overlays de victoria/derrota.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final gs = ref.watch(gameViewModelProvider);
    final ctrl = ref.read(gameViewModelProvider.notifier);

    if (gs.isLoading) {
      return Scaffold(
        backgroundColor: _t.background,
        body: Center(child: CircularProgressIndicator(color: _t.primary)),
      );
    }

    if (gs.errorMessage != null) {
      return Scaffold(
        backgroundColor: _t.background,
        body: Center(
          child: Text(gs.errorMessage!,
              style: TextStyle(color: _t.primary, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text(
          gs.currentLevelId?.value.replaceAll('_', ' ').toUpperCase() ?? '',
          style: TextStyle(
              color: _t.hudText, fontSize: 14, letterSpacing: 1.5),
        ),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l.undoTooltip,
            icon: Icon(Icons.undo, color: _t.hudText),
            onPressed: ctrl.undo,
          ),
          IconButton(
            tooltip: l.restartTooltip,
            icon: Icon(Icons.refresh, color: _t.hudText),
            onPressed: ctrl.restart,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              HudView(gameState: gs, onToggleMute: ctrl.toggleMute),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
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
              ),
            ],
          ),
          if (gs.mode != GamePlayMode.survival &&
              gs.status == GameStatus.levelCleared)
            _VictoryOverlay(
              result: gs.lastResult,
              hasNext: gs.hasNextLevel,
              onNext: ctrl.playNext,
              onBack: () => Navigator.pop(context),
            ),
          if (gs.status == GameStatus.gameOver)
            _DefeatOverlay(
              onRetry: ctrl.restart,
              onBack: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ── Overlays ──────────────────────────────────────────────────────────────────

class _VictoryOverlay extends StatelessWidget {
  final LevelResult? result;
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _VictoryOverlay({
    required this.result,
    required this.hasNext,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final subtitle = result == null
        ? l.victorySubtitleDefault
        : l.victoryScore(result!.score) +
            (result!.isNewBest ? '  ·  ${l.newRecord}' : '');
    return _Overlay(
      color: ThemeConfig.dark.victoryOverlay.withValues(alpha: 0.92),
      icon: Icons.star_rounded,
      title: l.victoryTitle,
      subtitle: subtitle,
      header: result == null ? null : _StarsBanner(stars: result!.stars),
      actions: [
        if (hasNext) ...[
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white),
            onPressed: onNext,
            child: Text(l.nextLevelButton,
                style: TextStyle(
                    color: ThemeConfig.dark.victoryOverlay, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white)),
            onPressed: onBack,
            child: Text(l.levelsButton),
          ),
        ] else
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white),
            onPressed: onBack,
            child: Text(l.levelsButton,
                style: TextStyle(
                    color: ThemeConfig.dark.victoryOverlay, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

/// Fila de 3 estrellas del resultado, mostrada sobre el título de victoria.
/// Las estrellas ganadas aparecen en secuencia con un rebote escalonado
/// (efecto recompensa) en lugar de mostrarse todas de golpe.
class _StarsBanner extends StatefulWidget {
  final int stars;
  const _StarsBanner({required this.stars});

  @override
  State<_StarsBanner> createState() => _StarsBannerState();
}

class _StarsBannerState extends State<_StarsBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const int _totalStars = 3;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalStars, (i) {
        final earned = i < widget.stars;
        // Escalonado: cada estrella arranca un poco después que la anterior.
        final start = (i * 0.2).clamp(0.0, 1.0);
        final end = (start + 0.55).clamp(0.0, 1.0);
        final anim = CurvedAnimation(
          parent: _ctrl,
          curve: Interval(
            start,
            end,
            // Las ganadas rebotan (elasticOut); las vacías entran suave.
            curve: earned ? Curves.elasticOut : Curves.easeOut,
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ScaleTransition(
            scale: anim,
            child: FadeTransition(
              opacity: _ctrl.drive(
                CurveTween(curve: Interval(start, end, curve: Curves.easeOut)),
              ),
              child: Icon(
                earned ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 48,
                color: earned
                    ? const Color(0xFFFFB238)
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DefeatOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _DefeatOverlay({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Overlay(
      color: ThemeConfig.dark.defeatOverlay.withValues(alpha: 0.92),
      icon: Icons.heart_broken_rounded,
      title: l.gameOverTitle,
      subtitle: l.gameOverSubtitle,
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white),
          onPressed: onRetry,
          child: Text(l.retryButton,
              style: TextStyle(color: ThemeConfig.dark.defeatOverlay, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white)),
          onPressed: onBack,
          child: Text(l.homeButton),
        ),
      ],
    );
  }
}

/// Overlay de fin de partida (victoria/derrota) con entrada animada: el fondo
/// se desvanece rápido mientras la tarjeta de contenido aparece con un
/// pequeño rebote (scale + fade), para que se sienta como una pantalla de
/// recompensa en vez de un rectángulo de color que aparece de golpe.
class _Overlay extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  /// Widget opcional mostrado en lugar del icono (ej. estrellas ganadas).
  final Widget? header;

  const _Overlay({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.header,
  });

  @override
  State<_Overlay> createState() => _OverlayState();
}

class _OverlayState extends State<_Overlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // El fondo se desvanece primero y rápido; la tarjeta lo sigue con un
    // ligero rebote (easeOutBack) para dar sensación de "pop" de recompensa.
    _backdropOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _contentOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
    );
    _contentScale = Tween(begin: 0.82, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
    ));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _backdropOpacity,
              child: Container(color: widget.color),
            ),
            FadeTransition(
              opacity: _contentOpacity,
              child: Center(
                child: ScaleTransition(
                  scale: _contentScale,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.header ?? Icon(widget.icon, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 15)),
            const SizedBox(height: 32),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.actions),
          ],
        ),
      ),
    );
  }
}
