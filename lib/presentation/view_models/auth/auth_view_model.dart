import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final RestoreSessionUseCase _restoreSession;
  final IProgressSyncCoordinator _progressSync;
  final ISessionCleanup? _sessionCleanup;

  AuthViewModel({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required RestoreSessionUseCase restoreSession,
    required IProgressSyncCoordinator progressSync,
    ISessionCleanup? sessionCleanup,
    bool restoreOnInit = true,
    AuthState initialState = const AuthState(status: AuthStatus.checking),
  })  : _login = login,
        _register = register,
        _logout = logout,
        _restoreSession = restoreSession,
        _progressSync = progressSync,
        _sessionCleanup = sessionCleanup,
        super(initialState) {
    if (restoreOnInit) {
      unawaited(_tryRestoreSession());
    }
  }

  Future<void> _tryRestoreSession() async {
    try {
      final user = await _restoreSession.execute();
      if (!mounted) return;

      if (user == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      await _syncProgressAfterAuth();
      if (!mounted) return;
      state = AuthState.authenticated(user);
    } on UnauthorizedError {
      if (!mounted) return;
      await _endSession();
    } catch (_) {
      if (!mounted) return;
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(
    String email,
    String password, {
    AppLocalizations? l10n,
  }) async {
    state = const AuthState.loading();

    try {
      final user = await _login.execute(email: email, password: password);
      // pull sobrescribe el progreso efímero de invitado con el remoto.
      await _syncProgressAfterAuth();
      state = AuthState.authenticated(user);
    } on ValidationError catch (e) {
      state = AuthState.unauthenticated(
        errorMessage: _localizeValidationError(e, l10n),
      );
    } on ApiError catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.toString());
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    AppLocalizations? l10n,
  }) async {
    state = const AuthState.loading();

    try {
      final user = await _register.execute(
        username: username,
        email: email,
        password: password,
      );
      await _syncProgressAfterAuth();
      state = AuthState.authenticated(user);
    } on ValidationError catch (e) {
      state = AuthState.unauthenticated(
        errorMessage: _localizeValidationError(e, l10n),
      );
    } on ApiError catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.toString());
    }
  }

  /// Traduce códigos de [ValidationError] (ej. `invalid_email`) a texto UI.
  ///
  /// [l10n] se inyecta desde la pantalla (sin acoplar el VM a BuildContext).
  String _localizeValidationError(
    ValidationError error,
    AppLocalizations? l10n,
  ) {
    if (l10n != null && error.message == 'invalid_email') {
      return l10n.error_invalid_email;
    }
    return error.message;
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> logout() async {
    final currentUser = state.user;
    state = AuthState(
      status: AuthStatus.loading,
      user: currentUser,
    );

    try {
      await _endSession();
    } on ApiError catch (e) {
      state = AuthState.authenticated(currentUser!).copyWith(
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState.authenticated(currentUser!).copyWith(
        errorMessage: e.toString(),
      );
    }
  }

  /// Token + usuario + progreso local, luego refresco de UI (invitado desde nivel 1).
  Future<void> _endSession({String? errorMessage}) async {
    await _logout.execute();
    _sessionCleanup?.clearSessionState();
    if (!mounted) return;
    state = AuthState.unauthenticated(errorMessage: errorMessage);
  }

  /// Hidrata el progreso remoto tras autenticar (login/register/restore).
  ///
  /// BUGFIX (progress-sync-integration): antes este método propagaba
  /// cualquier error que no fuera el 404 ya absorbido dentro de
  /// [IProgressSyncCoordinator.pullAndApplyLocal]. Como `login()`/`register()`
  /// llaman a este método dentro del MISMO try/catch que la llamada de auth,
  /// un GET /progress fallido (red, 401, 500, JSON malformado) hacía que un
  /// login/register con credenciales válidas se reportara como fallido. El
  /// contrato documentado en `IProgressSyncCoordinator` ya promete absorber
  /// fallos de red/servidor — aquí se cumple para pull igual que para push,
  /// y de paso deja de degradar una sesión restaurada válida a "no
  /// autenticado" solo porque la hidratación falló.
  Future<void> _syncProgressAfterAuth() async {
    try {
      await _progressSync.pullAndApplyLocal();
    } catch (_) {
      // Silencioso: el progreso local (vacío o desactualizado) se
      // sincronizará en el próximo pull/push exitoso; no debe tumbar la
      // autenticación que ya tuvo éxito.
    }
  }
}
