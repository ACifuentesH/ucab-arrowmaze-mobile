import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_state.dart';
import 'package:arrow_maze/presentation/views/screens/home_screen.dart';

/// Composition root: inicializa dependencias asíncronas antes de arrancar.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ArrowMazeApp(),
    ),
  );
}

class ArrowMazeApp extends ConsumerWidget {
  const ArrowMazeApp({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El idioma vive en SettingsViewModel; la app se relocaliza al cambiarlo.
    final locale = ref.watch(
      settingsViewModelProvider.select((SettingsState s) => s.locale),
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: _t.primary,
          onPrimary: _t.onPrimary,
          surface: _t.boardBackground,
        ),
        scaffoldBackgroundColor: _t.background,
        fontFamily: 'Outfit',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
