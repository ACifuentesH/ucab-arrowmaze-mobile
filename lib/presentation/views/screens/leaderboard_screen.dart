import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/presentation/view_models/leaderboard/leaderboard_view_model.dart';

/// Clasificación global de un nivel (GET /leaderboard/:levelId).
class LeaderboardScreen extends ConsumerStatefulWidget {
  final String levelId;

  const LeaderboardScreen({super.key, required this.levelId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(leaderboardViewModelProvider.notifier)
          .load(widget.levelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardViewModelProvider);

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: _t.hudText),
        title: Text(
          'Clasificación',
          style: TextStyle(
            color: _t.hudText,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(LeaderboardState state) {
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator(color: _t.primary));
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: _t.primary, fontSize: 15),
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Aún no hay puntuaciones para este nivel.\n¡Sé el primero!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _t.hudText.withValues(alpha: 0.7),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        final rank = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LeaderboardTile(rank: rank, entry: entry, theme: _t),
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntryDto entry;
  final ThemeConfig theme;

  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.theme,
  });

  bool get _isPodium => rank <= 3;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isPodium ? theme.exitCell : theme.hudText;

    return Material(
      color: theme.emptyCell,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: _isPodium
                  ? Icon(Icons.emoji_events_rounded, color: accent, size: 26)
                  : Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: TextStyle(
                      color: theme.hudText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.moves} mov · ${_formatTime(entry.timeSeconds)}',
                    style: TextStyle(
                      color: theme.hudText.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.score}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
