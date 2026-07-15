import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/views/screens/generate_level_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/login_screen.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';

/// Pantalla de inicio: título del juego, botón de entrada, acceso a ajustes
/// y — arriba a la izquierda — la entrada de cuenta (login / menú de usuario).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// Key estable del botón de ajustes para las pruebas de navegación.
  static const Key settingsButtonKey = Key('home_settings_button');

  /// Key estable del botón "JUGAR" para las pruebas de navegación.
  static const Key playButtonKey = Key('home_play_button');

  /// Key estable del botón/ícono de cuenta (login o menú de usuario).
  static const Key accountButtonKey = Key('home_account_button');

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  bool _accountMenuOpen = false;

  Future<void> _logout() async {
    setState(() => _accountMenuOpen = false);
    await ref.read(authViewModelProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authViewModelProvider);

    // Si la sesión se cierra (o expira) mientras el menú está abierto, ciérralo.
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status != AuthStatus.authenticated && _accountMenuOpen) {
        setState(() => _accountMenuOpen = false);
      }
    });

    return Scaffold(
      backgroundColor: _t.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: HomeScreen.settingsButtonKey,
                tooltip: l.settingsTooltip,
                icon: Icon(Icons.settings, color: _t.hudText),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            if (_accountMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _accountMenuOpen = false),
                ),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccountEntryPoint(
                    key: HomeScreen.accountButtonKey,
                    auth: auth,
                    isMenuOpen: _accountMenuOpen,
                    onToggleMenu: () =>
                        setState(() => _accountMenuOpen = !_accountMenuOpen),
                    onLoginTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                  if (_accountMenuOpen && auth.isAuthenticated)
                    _UserAccountCard(
                      username: auth.user!.username,
                      isLoading: auth.isLoading,
                      onLogout: _logout,
                    ),
                ],
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
                    key: HomeScreen.playButtonKey,
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

/// Ícono de cuenta arriba a la izquierda: abre el login si no hay sesión,
/// o alterna el menú de usuario si ya hay una activa.
class _AccountEntryPoint extends StatelessWidget {
  final AuthState auth;
  final bool isMenuOpen;
  final VoidCallback onToggleMenu;
  final VoidCallback onLoginTap;

  const _AccountEntryPoint({
    super.key,
    required this.auth,
    required this.isMenuOpen,
    required this.onToggleMenu,
    required this.onLoginTap,
  });

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (auth.isAuthenticated) {
      return IconButton(
        tooltip: l.accountTooltip,
        onPressed: auth.isLoading ? null : onToggleMenu,
        icon: Icon(Icons.person, color: _t.hudText.withValues(alpha: 0.85)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: OutlinedButton(
        onPressed: auth.isLoading ? null : onLoginTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _t.hudText,
          disabledForegroundColor: _t.hudText.withValues(alpha: 0.55),
          side: BorderSide(color: _t.primary.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(l.loginButton),
      ),
    );
  }
}

/// Tarjeta del menú de usuario: saludo + cerrar sesión.
class _UserAccountCard extends StatelessWidget {
  final String username;
  final bool isLoading;
  final VoidCallback onLogout;

  const _UserAccountCard({
    required this.username,
    required this.isLoading,
    required this.onLogout,
  });

  static const ThemeConfig _t = ThemeConfig.dark;
  static const Color _cardBackground = Color(0xFF0A1628);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.accountGreeting(username),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _t.primary,
                  foregroundColor: _t.onPrimary,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : onLogout,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.logoutButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
