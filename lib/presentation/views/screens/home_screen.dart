import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/views/screens/generate_level_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/login_screen.dart';
import 'package:arrow_maze/presentation/views/screens/register_screen.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';
import 'package:arrow_maze/presentation/views/screens/survival_game_screen.dart';
import 'package:arrow_maze/presentation/views/widgets/animated_logo.dart';
import 'package:arrow_maze/presentation/views/widgets/login_prompt_dialog.dart';

/// Pantalla de inicio: logo animado, botón de entrada (con prompt de login
/// al iniciar partida sin sesión), acceso a ajustes y — arriba a la
/// izquierda — el menú de cuenta cuando ya hay una sesión activa.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// Key estable del botón de ajustes para las pruebas de navegación.
  static const Key settingsButtonKey = Key('home_settings_button');

  /// Key estable del botón "JUGAR" para las pruebas de navegación.
  static const Key playButtonKey = Key('home_play_button');

  /// Key estable del botón "MODO SUPERVIVENCIA" para las pruebas de navegación.
  static const Key survivalButtonKey = Key('home_survival_button');

  /// Key estable del ícono de cuenta (menú de usuario autenticado).
  static const Key accountButtonKey = Key('home_account_button');

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  bool _accountMenuOpen = false;

  /// Una vez que el usuario elige "continuar como invitado" en esta sesión
  /// de la app, no se lo volvemos a preguntar — evita que el prompt se
  /// vuelva molesto en partidas repetidas. Se reinicia si cierra sesión,
  /// para volver a ofrecer login la próxima vez que toque "JUGAR".
  bool _guestPromptDismissed = false;

  Future<void> _logout() async {
    setState(() => _accountMenuOpen = false);
    await ref.read(authViewModelProvider.notifier).logout();
  }

  void _goToLevelSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
    );
  }

  void _goToSurvival() {
    // Nueva partida limpia: evita reutilizar un SurvivalViewModel ya finalizado.
    ref.invalidate(survivalViewModelProvider);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SurvivalGameScreen()),
    );
  }

  Future<void> _onPlayPressed() async {
    final auth = ref.read(authViewModelProvider);
    if (auth.isAuthenticated || _guestPromptDismissed) {
      _goToLevelSelect();
      return;
    }

    final choice = await showLoginPromptSheet(context);
    if (!mounted) return;

    switch (choice) {
      case LoginPromptChoice.guest:
        setState(() => _guestPromptDismissed = true);
        _goToLevelSelect();
        break;
      case LoginPromptChoice.login:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (!mounted) return;
        if (ref.read(authViewModelProvider).isAuthenticated) {
          _goToLevelSelect();
        }
        break;
      case LoginPromptChoice.register:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        if (!mounted) return;
        if (ref.read(authViewModelProvider).isAuthenticated) {
          _goToLevelSelect();
        }
        break;
      case null:
        // Cerrado sin elegir (deslizado hacia abajo / toque fuera): se queda
        // en Home, se le volverá a preguntar la próxima vez que toque JUGAR.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authViewModelProvider);

    // Si la sesión se cierra (o expira) mientras el menú está abierto, ciérralo,
    // y vuelve a habilitar el prompt de login para la próxima partida.
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status != AuthStatus.authenticated) {
        if (_accountMenuOpen) setState(() => _accountMenuOpen = false);
        if (previous?.status == AuthStatus.authenticated) {
          setState(() => _guestPromptDismissed = false);
        }
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
            if (auth.isAuthenticated)
              Positioned(
                top: 4,
                left: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      key: HomeScreen.accountButtonKey,
                      tooltip: l.accountTooltip,
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(
                              () => _accountMenuOpen = !_accountMenuOpen),
                      icon: Icon(Icons.person,
                          color: _t.hudText.withValues(alpha: 0.85)),
                    ),
                    if (_accountMenuOpen)
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
                  const AnimatedLogo(),
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
                    onPressed: _onPlayPressed,
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
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: HomeScreen.survivalButtonKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B35),
                      side: const BorderSide(color: Color(0xFFFF6B35)),
                      minimumSize: const Size(200, 48),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _goToSurvival,
                    icon: const Icon(Icons.local_fire_department, size: 20),
                    label: Text(l.survivalModeButton),
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
