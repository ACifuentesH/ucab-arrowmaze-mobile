import 'package:flutter/material.dart';

import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';

/// HUD superior: vidas, cronómetro/cuenta regresiva, movimientos, flechas, mute.
class HudView extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onToggleMute;

  const HudView({
    super.key,
    required this.gameState,
    this.onToggleMute,
  });

  static const ThemeConfig _t = ThemeConfig.dark;
  static const int _maxLivesToShow = 5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final livesCount = gameState.lives.value;
    final limit = gameState.board?.timeLimitSeconds;
    final elapsed = gameState.elapsedSeconds;
    final displaySeconds =
        limit != null ? (limit - elapsed).clamp(0, limit) : elapsed;
    final isUrgent = limit != null && displaySeconds <= 10;

    return Container(
      color: _t.boardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Corazones
          Row(
            children: List.generate(_maxLivesToShow, (i) {
              final active = i < livesCount;
              return Icon(
                active ? Icons.favorite : Icons.favorite_border,
                color: active ? _t.lifeActive : _t.lifeEmpty,
                size: 22,
              );
            }),
          ),
          const Spacer(),
          // Cronómetro / cuenta regresiva
          Icon(
            limit != null ? Icons.timer : Icons.timer_outlined,
            color: isUrgent ? const Color(0xFFFF3D68) : _t.hudText,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            _fmt(displaySeconds),
            style: TextStyle(
              color: isUrgent ? const Color(0xFFFF3D68) : _t.hudText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 16),
          // Movimientos
          Icon(Icons.swap_horiz, color: _t.hudText, size: 18),
          const SizedBox(width: 4),
          Text(
            '${gameState.moves.value}',
            style: TextStyle(
              color: _t.hudText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          // Flechas restantes
          Icon(Icons.arrow_forward, color: _t.primary, size: 18),
          const SizedBox(width: 4),
          Text(
            '${gameState.arrowCount}',
            style: TextStyle(
              color: _t.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // Mute toggle
          IconButton(
            tooltip: gameState.isMuted ? l.unmuteTooltip : l.muteTooltip,
            icon: Icon(
              gameState.isMuted ? Icons.volume_off : Icons.volume_up,
              color: _t.hudText,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onToggleMute,
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
