import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/config/providers.dart';
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

class ArrowMazeApp extends StatelessWidget {
  const ArrowMazeApp({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Escape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: _t.primary,
          onPrimary: _t.onPrimary,
          surface: _t.boardBackground,
        ),
        scaffoldBackgroundColor: _t.background,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
