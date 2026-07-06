import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze/domain/game_status.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/presentation/views/widgets/board_view.dart';
import 'package:arrow_maze/presentation/views/widgets/hud_view.dart';

/// Pantalla de juego: tablero + HUD + overlays de victoria/derrota.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            tooltip: 'Deshacer',
            icon: Icon(Icons.undo, color: _t.hudText),
            onPressed: ctrl.undo,
          ),
          IconButton(
            tooltip: 'Reiniciar',
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
          if (gs.status == GameStatus.levelCleared)
            _VictoryOverlay(onBack: () => Navigator.pop(context)),
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
  final VoidCallback onBack;
  const _VictoryOverlay({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return _Overlay(
      color: ThemeConfig.dark.victoryOverlay.withValues(alpha: 0.92),
      icon: Icons.star_rounded,
      title: '¡Nivel completado!',
      subtitle: 'Todas las flechas escaparon.',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white),
          onPressed: onBack,
          child: const Text('Siguiente',
              style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _DefeatOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _DefeatOverlay({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return _Overlay(
      color: ThemeConfig.dark.defeatOverlay.withValues(alpha: 0.92),
      icon: Icons.heart_broken_rounded,
      title: 'Game Over',
      subtitle: 'Sin vidas. ¡Inténtalo de nuevo!',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white),
          onPressed: onRetry,
          child: const Text('Reintentar',
              style: TextStyle(color: Color(0xFF7B1E3A), fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white)),
          onPressed: onBack,
          child: const Text('Inicio'),
        ),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const _Overlay({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Colors.white),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 15)),
              const SizedBox(height: 32),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
