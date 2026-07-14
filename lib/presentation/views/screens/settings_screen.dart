import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';

/// Pantalla de ajustes (criterios 5.1.1 y 5.1.10): silenciar el audio
/// (reutiliza `IAudioService`) y elegir el idioma de la interfaz.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  /// Keys estables para las pruebas de widget.
  static const Key muteSwitchKey = Key('settings_mute_switch');
  static const Key spanishOptionKey = Key('settings_language_es');
  static const Key englishOptionKey = Key('settings_language_en');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(settingsViewModelProvider);
    final controller = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text(l.settingsTitle, style: TextStyle(color: _t.hudText)),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionTitle(l.settingsSoundSection),
          SwitchListTile(
            key: muteSwitchKey,
            value: state.isMuted,
            onChanged: (_) => controller.toggleMute(),
            title: Text(
              l.settingsMuteLabel,
              style: TextStyle(color: _t.hudText),
            ),
            secondary: Icon(
              state.isMuted ? Icons.volume_off : Icons.volume_up,
              color: _t.hudText,
            ),
            activeThumbColor: _t.primary,
          ),
          const SizedBox(height: 8),
          _SectionTitle(l.settingsLanguageSection),
          _LanguageOption(
            key: spanishOptionKey,
            label: l.languageSpanish,
            selected: state.locale.languageCode == 'es',
            onTap: () => controller.setLocale(const Locale('es')),
          ),
          _LanguageOption(
            key: englishOptionKey,
            label: l.languageEnglish,
            selected: state.locale.languageCode == 'en',
            onTap: () => controller.setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

/// Fila de idioma seleccionable con marca de verificación cuando está activa.
class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = SettingsScreen._t;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected ? t.primary : t.hudText.withValues(alpha: 0.5),
      ),
      title: Text(label, style: TextStyle(color: t.hudText)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: SettingsScreen._t.hudText.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
