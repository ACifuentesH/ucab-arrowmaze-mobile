import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';

const _levels = [
  {'id': 'level_heart', 'name': 'Corazón', 'hint': '12 flechas · forma de corazón'},
];

/// Pantalla de selección de niveles.
/// La persistencia de progreso se añadirá en v2; por ahora muestra todos los niveles.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text('Niveles', style: TextStyle(color: _t.hudText)),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _levels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final level = _levels[i];
          return Material(
            color: _t.emptyCell,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await ref
                    .read(gameViewModelProvider.notifier)
                    .loadLevel(level['id']!);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level['name']!,
                              style: TextStyle(
                                  color: _t.hudText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(level['hint']!,
                              style: TextStyle(
                                  color: _t.hudText.withValues(alpha: 0.6),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _t.primary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
