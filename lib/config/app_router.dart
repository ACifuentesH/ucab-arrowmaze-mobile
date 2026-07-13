import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';
import 'package:arrow_maze/presentation/views/screens/generate_level_screen.dart';
import 'package:arrow_maze/presentation/views/screens/home_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/login_screen.dart';
import 'package:arrow_maze/presentation/views/screens/register_screen.dart';
import 'package:arrow_maze/presentation/views/screens/splash_screen.dart';

/// Rutas nombradas de la aplicación.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const levels = '/levels';
  static const generate = '/generate';
  static const game = '/game';

  static const _publicRoutes = {login, register};

  static bool isPublic(String location) => _publicRoutes.contains(location);
}

/// Notifica a GoRouter cuando cambia el estado de autenticación.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen<AuthState>(authViewModelProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      final location = state.matchedLocation;

      if (auth.status == AuthStatus.checking) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (auth.status == AuthStatus.loading) return null;

      final isAuthenticated = auth.status == AuthStatus.authenticated;
      final isPublic = AppRoutes.isPublic(location);

      if (!isAuthenticated) {
        if (location == AppRoutes.splash) return AppRoutes.login;
        if (!isPublic) return AppRoutes.login;
        return null;
      }

      if (isPublic || location == AppRoutes.splash) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.levels,
        builder: (_, __) => const LevelSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.generate,
        builder: (_, __) => const GenerateLevelScreen(),
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (_, __) => const GameScreen(),
      ),
    ],
  );
});
