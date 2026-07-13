import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/config/session_navigation.dart';
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

class ArrowMazeApp extends ConsumerStatefulWidget {
  const ArrowMazeApp({super.key});

  @override
  ConsumerState<ArrowMazeApp> createState() => _ArrowMazeAppState();
}

class _ArrowMazeAppState extends ConsumerState<ArrowMazeApp> {
  static const ThemeConfig _t = ThemeConfig.dark;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return SessionNavigationListener(
      navigatorKey: _navigatorKey,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
      ),
    );
  }
}
