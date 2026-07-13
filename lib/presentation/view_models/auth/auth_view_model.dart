import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/services/session_expired_notifier.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final SessionExpiredNotifier? _sessionExpired;
  final ISessionCleanup? _sessionCleanup;

  AuthViewModel({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    SessionExpiredNotifier? sessionExpired,
    ISessionCleanup? sessionCleanup,
  })  : _login = login,
        _register = register,
        _logout = logout,
        _sessionExpired = sessionExpired,
        _sessionCleanup = sessionCleanup,
        super(const AuthState()) {
    _sessionExpired?.onSessionExpired = handleSessionExpired;
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();

    try {
      final user = await _login.execute(email: email, password: password);
      state = AuthState.authenticated(user);
    } on ApiError catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.toString());
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();

    try {
      final user = await _register.execute(
        username: username,
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user);
    } on ApiError catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthState.loading().copyWith(user: state.user);

    try {
      await _logout.execute();
      _endSession();
    } on ApiError catch (e) {
      state = AuthState.authenticated(state.user!).copyWith(
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState.authenticated(state.user!).copyWith(
        errorMessage: e.toString(),
      );
    }
  }

  /// Invocado por [SessionExpiredNotifier] cuando el cliente HTTP detecta un 401.
  void handleSessionExpired() {
    if (state.status != AuthStatus.authenticated) return;
    print(
      '--- RIVERPOD: Ejecutando logout y cambiando estado a unauthenticated',
    );
    _endSession(
      errorMessage: 'Tu sesión expiró. Inicia sesión de nuevo.',
    );
  }

  void _endSession({String? errorMessage}) {
    _sessionCleanup?.clearSessionState();
    state = AuthState.unauthenticated(errorMessage: errorMessage);
  }

  @override
  void dispose() {
    _sessionExpired?.onSessionExpired = null;
    super.dispose();
  }
}
