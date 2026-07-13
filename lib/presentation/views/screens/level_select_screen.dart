import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/dtos/playable_level.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/config/app_router.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';

/// Pantalla de selección: campaña con progresión (el siguiente nivel se
/// desbloquea al completar el anterior) + niveles generados con IA.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(levelSelectViewModelProvider.notifier).load(),
    );
  }

  Future<void> _playCampaign(List<LevelSelectEntry> campaign, int index) async {
    // La cola arranca en el nivel tocado; los siguientes se van
    // desbloqueando a medida que se completan.
    final queue = campaign
        .skip(index)
        .map((e) => PlayableLevel.fromPreview(e.preview))
        .toList();
    await ref.read(gameViewModelProvider.notifier).startCampaign(queue);
    if (!mounted) return;
    await context.push(AppRoutes.game);
    if (mounted) ref.read(levelSelectViewModelProvider.notifier).load();
  }

  Future<void> _playGenerated(LevelSelectEntry entry) async {
    await ref.read(gameViewModelProvider.notifier).loadLevel(
          entry.preview.id,
          difficulty: entry.preview.difficulty,
        );
    if (!mounted) return;
    await context.push(AppRoutes.game);
    if (mounted) ref.read(levelSelectViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelSelectViewModelProvider);
    final campaign = state.campaign;
    final generated = state.generated;

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text('Niveles', style: TextStyle(color: _t.hudText)),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
      ),
      body: state.isLoading && state.entries.isEmpty
          ? Center(child: CircularProgressIndicator(color: _t.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionTitle('Campaña', theme: _t),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: campaign.length,
                  itemBuilder: (context, i) => _CampaignTile(
                    entry: campaign[i],
                    number: i + 1,
                    theme: _t,
                    onTap: campaign[i].isPlayable
                        ? () => _playCampaign(campaign, i)
                        : null,
                  ),
                ),
                if (generated.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionTitle('Generados con IA', theme: _t),
                  const SizedBox(height: 12),
                  ...generated.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GeneratedTile(
                          entry: entry,
                          theme: _t,
                          onTap: () => _playGenerated(entry),
                        ),
                      )),
                ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final ThemeConfig theme;
  const _SectionTitle(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: theme.hudText.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      );
}

/// Casilla de campaña: número + estrellas; candado cuando está bloqueada.
class _CampaignTile extends StatelessWidget {
  final LevelSelectEntry entry;
  final int number;
  final ThemeConfig theme;
  final VoidCallback? onTap;

  const _CampaignTile({
    required this.entry,
    required this.number,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = entry.status == LevelStatus.locked;
    final completed = entry.status == LevelStatus.completed;

    return Material(
      color: locked
          ? theme.emptyCell.withValues(alpha: 0.35)
          : theme.emptyCell,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: completed
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.primary.withValues(alpha: 0.7), width: 2),
                )
              : null,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                Icon(Icons.lock_rounded,
                    size: 28, color: theme.hudText.withValues(alpha: 0.35))
              else
                Text(
                  '$number',
                  style: TextStyle(
                    color: theme.hudText,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                entry.preview.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.hudText
                      .withValues(alpha: locked ? 0.3 : 0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              _StarsRow(stars: entry.stars, dimmed: locked),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int stars;
  final bool dimmed;
  const _StarsRow({required this.stars, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: earned
              ? const Color(0xFFFFB238)
              : Colors.white.withValues(alpha: dimmed ? 0.1 : 0.25),
        );
      }),
    );
  }
}

class _GeneratedTile extends StatelessWidget {
  final LevelSelectEntry entry;
  final ThemeConfig theme;
  final VoidCallback onTap;

  const _GeneratedTile({
    required this.entry,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.emptyCell,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.preview.name,
                        style: TextStyle(
                            color: theme.hudText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.preview.arrowCount} flechas · '
                      '${entry.preview.difficulty.name}',
                      style: TextStyle(
                          color: theme.hudText.withValues(alpha: 0.6),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StarsRow(stars: entry.stars),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: theme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
