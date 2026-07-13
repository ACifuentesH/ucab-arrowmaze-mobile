import 'package:flutter/material.dart';

import 'package:arrow_maze/config/theme_config.dart';

/// Pantalla de arranque mientras se restaura la sesión desde almacenamiento seguro.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Arrow\nEscape',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: _t.primary,
                height: 1.05,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: _t.primary),
          ],
        ),
      ),
    );
  }
}
