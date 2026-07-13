import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/views/screens/generate_level_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/login_screen.dart';

/// Pantalla de inicio: título del juego y botón de entrada.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  bool _userMenuOpen = false;

  ButtonStyle _primaryButtonStyle({Size minimumSize = const Size(200, 52)}) {
    return FilledButton.styleFrom(
      backgroundColor: _t.primary,
      foregroundColor: _t.onPrimary,
      minimumSize: minimumSize,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _userMenuOpen = false);
    await ref.read(authViewModelProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status != AuthStatus.authenticated && _userMenuOpen) {
        setState(() => _userMenuOpen = false);
      }
    });

    return Scaffold(
      backgroundColor: _t.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const SizedBox(height: 16),
                    Text(
                      'Despeja el tablero. Sobrevive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: _t.hudText.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 56),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: _primaryButtonStyle(
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LevelSelectScreen(),
                          ),
                        ),
                        child: const Text('JUGAR'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _t.primary,
                          side: BorderSide(
                            color: _t.primary.withValues(alpha: 0.6),
                          ),
                          minimumSize: const Size(0, 52),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GenerateLevelScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI LEVEL BUILDER'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_userMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _userMenuOpen = false),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: auth.status == AuthStatus.authenticated
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          iconSize: 36,
                          onPressed: auth.isLoading
                              ? null
                              : () => setState(
                                    () => _userMenuOpen = !_userMenuOpen,
                                  ),
                          icon: Icon(
                            Icons.person,
                            color: _t.hudText.withValues(alpha: 0.85),
                          ),
                          tooltip: 'Cuenta',
                        ),
                        if (_userMenuOpen)
                          _UserAccountCard(
                            username: auth.user!.username,
                            isLoading: auth.isLoading,
                            primaryButtonStyle: _primaryButtonStyle(
                              minimumSize: const Size(0, 52),
                            ),
                            onLogout: _logout,
                          ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _t.onPrimary,
                        side: BorderSide(
                          color: _t.primary.withValues(alpha: 0.75),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Login'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAccountCard extends StatelessWidget {
  final String username;
  final bool isLoading;
  final ButtonStyle primaryButtonStyle;
  final VoidCallback onLogout;

  const _UserAccountCard({
    required this.username,
    required this.isLoading,
    required this.primaryButtonStyle,
    required this.onLogout,
  });

  static const Color _cardBackground = Color(0xFF0A1628);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hola, $username',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: primaryButtonStyle,
                onPressed: isLoading ? null : onLogout,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('CERRAR SESIÓN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
