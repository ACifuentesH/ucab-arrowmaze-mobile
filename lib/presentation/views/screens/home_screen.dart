import 'package:flutter/material.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/generate_level_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';

/// Pantalla de inicio: título del juego, botón de entrada y acceso a ajustes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  /// Key estable del botón de ajustes para las pruebas de navegación.
  static const Key settingsButtonKey = Key('home_settings_button');

  /// Key estable del botón "JUGAR" para las pruebas de navegación.
  static const Key playButtonKey = Key('home_play_button');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _t.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: settingsButtonKey,
                tooltip: l.settingsTooltip,
                icon: Icon(Icons.settings, color: _t.hudText),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Arrow\nEscape',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: _t.primary,
                      height: 1.05,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.homeTagline,
                    style: TextStyle(
                        fontSize: 15,
                        color: _t.hudText.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 72),
                  FilledButton(
                    key: playButtonKey,
                    style: FilledButton.styleFrom(
                      backgroundColor: _t.primary,
                      foregroundColor: _t.onPrimary,
                      minimumSize: const Size(200, 52),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LevelSelectScreen()),
                    ),
                    child: Text(l.playButton),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _t.primary,
                      side: BorderSide(
                          color: _t.primary.withValues(alpha: 0.6)),
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GenerateLevelScreen()),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l.aiLevelBuilderButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
