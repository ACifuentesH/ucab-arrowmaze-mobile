import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/dtos/playable_level.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';

/// Ventana del MODO HEXAGONAL: lista los dos niveles hex (uno fácil, uno
/// difícil) como tarjetas grandes con su estado de progresión. Espeja los
/// patrones de [LevelSelectScreen] (initState + load, cola de campaña con
/// `PlayableLevel.fromPreview` + `startCampaign`, recarga al volver) pero sobre
/// el `hexLevelSelectViewModelProvider`. Sin requisito de login: los niveles
/// hex son locales (assets), no se generan contra el backend.
class HexLevelSelectScreen extends ConsumerStatefulWidget {
  const HexLevelSelectScreen({super.key});

  /// Key estable de la tarjeta del nivel hex número [number] (1-based) para
  /// las pruebas de navegación/interacción.
  static Key hexTileKey(int number) => Key('hex_tile_$number');

  @override
  ConsumerState<HexLevelSelectScreen> createState() =>
      _HexLevelSelectScreenState();
}

class _HexLevelSelectScreenState extends ConsumerState<HexLevelSelectScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(hexLevelSelectViewModelProvider.notifier).load(),
    );
  }

  /// Igual que `_playCampaign` de la campaña cuadrada: la cola arranca en el
  /// nivel tocado, de modo que completar "Panal" encadena automáticamente a
  /// "Colmena" y el progreso desbloquea/persiste con la infraestructura común.
  Future<void> _playHex(List<LevelSelectEntry> entries, int index) async {
    final queue = entries
        .skip(index)
        .map((e) => PlayableLevel.fromPreview(e.preview))
        .toList();
    await ref.read(gameViewModelProvider.notifier).startCampaign(queue);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    if (mounted) ref.read(hexLevelSelectViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(hexLevelSelectViewModelProvider);
    final entries = state.entries;

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text(l.hexModeTitle, style: TextStyle(color: _t.hudText)),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
      ),
      body: state.isLoading && entries.isEmpty
          ? Center(child: CircularProgressIndicator(color: _t.exitCell))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _HexModeHeader(theme: _t, subtitle: l.hexModeSubtitle),
                const SizedBox(height: 20),
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HexLevelTile(
                      key: HexLevelSelectScreen.hexTileKey(i + 1),
                      entry: entries[i],
                      number: i + 1,
                      theme: _t,
                      metaLabel: l.levelMeta(
                        entries[i].preview.arrowCount,
                        entries[i].preview.difficulty.name,
                      ),
                      playLabel: l.playButton,
                      bestScoreLabel: entries[i].bestScore == null
                          ? null
                          : l.victoryScore(entries[i].bestScore!),
                      onTap: entries[i].isPlayable
                          ? () => _playHex(entries, i)
                          : null,
                    ),
                  ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(state.errorMessage!,
                        style: TextStyle(color: _t.primary)),
                  ),
              ],
            ),
    );
  }
}

/// Cabecera con el icono de panal y la nota que explica la mecánica de las 6
/// direcciones.
class _HexModeHeader extends StatelessWidget {
  final ThemeConfig theme;
  final String subtitle;
  const _HexModeHeader({required this.theme, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.hexagon, color: theme.exitCell, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              color: theme.hudText.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta grande de un nivel hex: nombre, metadatos (flechas · dificultad),
/// estrellas, best score y estado (bloqueado/jugable/completado). Mantiene
/// `Icons.lock_rounded` para bloqueados y `Icons.check_rounded` para
/// completados (contrato de test, igual que la campaña cuadrada).
class _HexLevelTile extends StatelessWidget {
  final LevelSelectEntry entry;
  final int number;
  final ThemeConfig theme;
  final String metaLabel;
  final String playLabel;
  final String? bestScoreLabel;
  final VoidCallback? onTap;

  const _HexLevelTile({
    super.key,
    required this.entry,
    required this.number,
    required this.theme,
    required this.metaLabel,
    required this.playLabel,
    required this.bestScoreLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = entry.status == LevelStatus.locked;
    final completed = entry.status == LevelStatus.completed;
    final accent = theme.exitCell;

    return Material(
      color: theme.emptyCell.withValues(alpha: locked ? 0.5 : 1.0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: completed
                  ? accent.withValues(alpha: 0.6)
                  : theme.wallCell.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              _StatusBadge(
                number: number,
                locked: locked,
                completed: completed,
                theme: theme,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.preview.name,
                      style: TextStyle(
                        color: theme.hudText
                            .withValues(alpha: locked ? 0.55 : 1.0),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metaLabel,
                      style: TextStyle(
                        color: theme.hudText.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HexStarsRow(
                      stars: entry.stars,
                      dimmed: locked,
                      theme: theme,
                    ),
                    if (bestScoreLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        bestScoreLabel!,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrailingAction(
                locked: locked,
                playLabel: playLabel,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Insignia circular a la izquierda: candado si está bloqueado, check si está
/// completado, o el número del nivel si está por jugar.
class _StatusBadge extends StatelessWidget {
  final int number;
  final bool locked;
  final bool completed;
  final ThemeConfig theme;

  const _StatusBadge({
    required this.number,
    required this.locked,
    required this.completed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = locked
        ? theme.wallCell.withValues(alpha: 0.5)
        : completed
            ? theme.exitCell
            : theme.exitCell.withValues(alpha: 0.18);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
      alignment: Alignment.center,
      child: locked
          ? Icon(
              Icons.lock_rounded,
              size: 24,
              color: theme.hudText.withValues(alpha: 0.4),
            )
          : completed
              ? Icon(Icons.check_rounded, size: 28, color: theme.onPrimary)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: theme.exitCell,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
    );
  }
}

/// Acción a la derecha: chip "jugar" si es jugable, o nada si está bloqueado.
class _TrailingAction extends StatelessWidget {
  final bool locked;
  final String playLabel;
  final ThemeConfig theme;

  const _TrailingAction({
    required this.locked,
    required this.playLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Icon(
        Icons.lock_outline_rounded,
        color: theme.hudText.withValues(alpha: 0.3),
        size: 22,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.exitCell,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 16, color: theme.onPrimary),
          const SizedBox(width: 4),
          Text(
            playLabel,
            style: TextStyle(
              color: theme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HexStarsRow extends StatelessWidget {
  final int stars;
  final bool dimmed;
  final ThemeConfig theme;
  const _HexStarsRow({
    required this.stars,
    required this.theme,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: earned
              ? theme.exitCell
              : theme.hudText.withValues(alpha: dimmed ? 0.1 : 0.25),
        );
      }),
    );
  }
}
