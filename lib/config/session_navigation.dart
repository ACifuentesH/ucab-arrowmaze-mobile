import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/views/screens/login_screen.dart';

/// Escucha [authViewModelProvider] y redirige a login cuando la sesión termina.
class SessionNavigationListener extends ConsumerWidget {
  const SessionNavigationListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authViewModelProvider, (previous, next) {
      final wasAuthenticated =
          previous?.status == AuthStatus.authenticated;
      final isUnauthenticated =
          next.status == AuthStatus.unauthenticated && !next.isLoading;

      if (wasAuthenticated && isUnauthenticated) {
        print(
          '--- ROUTER: Evaluando estado de autenticación. Redirigiendo a /login',
        );
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    });

    return child;
  }
}
