import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/config/app_router.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';

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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Arrow Escape',
      debugShowCheckedModeBanner: false,
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
      routerConfig: router,
    );
  }
}
