import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:arrow_maze/application/dtos/survival_entry_dto.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/survival/survival_leaderboard_provider.dart';

/// Clasificación pública del Modo Supervivencia (GET /survival/leaderboard).
class SurvivalLeaderboardScreen extends ConsumerWidget {
  const SurvivalLeaderboardScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;
  static const Color _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(survivalLeaderboardProvider);

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: _t.hudText),
        title: Text(
          l.survivalLeaderboardTitle,
          style: TextStyle(
            color: _t.hudText,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _accent),
        ),
        error: (error, _) => _ErrorBody(
          message: l.survivalLeaderboardError,
          retryLabel: l.survivalLeaderboardRetry,
          onRetry: () => ref.invalidate(survivalLeaderboardProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l.survivalLeaderboardEmpty,
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
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SurvivalTile(
                  rank: index + 1,
                  entry: entry,
                  locale: Localizations.localeOf(context).toString(),
                  boardsLabel: l.survivalBoardsSolved(entry.boardsSolved),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  static const ThemeConfig _t = ThemeConfig.dark;
  static const Color _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: _t.primary, fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _t.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurvivalTile extends StatelessWidget {
  const _SurvivalTile({
    required this.rank,
    required this.entry,
    required this.locale,
    required this.boardsLabel,
  });

  final int rank;
  final SurvivalEntryDto entry;
  final String locale;
  final String boardsLabel;

  static const ThemeConfig _t = ThemeConfig.dark;
  static const Color _accent = Color(0xFFFF6B35);

  bool get _isPodium => rank <= 3;

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd(locale).format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isPodium ? _t.exitCell : _t.hudText;

    return Material(
      color: _t.emptyCell,
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
                      color: _t.hudText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(entry.playedAt),
                    style: TextStyle(
                      color: _t.hudText.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.boardsSolved}',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  boardsLabel,
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
