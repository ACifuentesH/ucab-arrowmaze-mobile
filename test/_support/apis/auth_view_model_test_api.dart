import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_view_model.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockRegisterUseCase extends Mock implements RegisterUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MockRestoreSessionUseCase extends Mock
    implements RestoreSessionUseCase {}

class _MockProgressSyncCoordinator extends Mock
    implements IProgressSyncCoordinator {}

class _MockSessionCleanup extends Mock implements ISessionCleanup {}

/// Testing API: AuthViewModel — login/register/logout/restore y su
/// orquestación de [IProgressSyncCoordinator]. La interacción con los
/// colaboradores (progressSync, logout, sessionCleanup) ES el comportamiento
/// observable, así que aquí sí usamos mocktail (docs/testing-architecture.md
/// §0.5); el `test(...)` solo llama métodos given/when/then encadenables.
class AuthViewModelTestApi {
  static const AuthUser defaultUser = AuthUser(
    id: 'u-1',
    username: 'alice',
    email: 'alice@example.com',
  );

  final _MockLoginUseCase _login = _MockLoginUseCase();
  final _MockRegisterUseCase _register = _MockRegisterUseCase();
  final _MockLogoutUseCase _logout = _MockLogoutUseCase();
  final _MockRestoreSessionUseCase _restoreSession =
      _MockRestoreSessionUseCase();
  final _MockProgressSyncCoordinator _progressSync =
      _MockProgressSyncCoordinator();
  final _MockSessionCleanup _sessionCleanup = _MockSessionCleanup();

  late AuthViewModel _viewModel;

  AuthViewModelTestApi() {
    when(() => _progressSync.pullAndApplyLocal()).thenAnswer((_) async {});
    when(
      () => _progressSync.pushCompletedLevel(
        lastLevelId: any(named: 'lastLevelId'),
        lastScore: any(named: 'lastScore'),
        lastMoves: any(named: 'lastMoves'),
        lastTimeSeconds: any(named: 'lastTimeSeconds'),
        currentLevelId: any(named: 'currentLevelId'),
      ),
    ).thenAnswer((_) async {});
    when(() => _logout.execute()).thenAnswer((_) async {});
    when(() => _sessionCleanup.clearSessionState()).thenReturn(null);

    _viewModel = AuthViewModel(
      login: _login,
      register: _register,
      logout: _logout,
      restoreSession: _restoreSession,
      progressSync: _progressSync,
      sessionCleanup: _sessionCleanup,
      restoreOnInit: false,
      initialState: const AuthState(),
    );
  }

  // ── Given ──────────────────────────────────────────────────────────────

  AuthViewModelTestApi givenLoginSucceeds({AuthUser user = defaultUser}) {
    when(
      () => _login.execute(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);
    return this;
  }

  AuthViewModelTestApi givenLoginFailsWithInvalidCredentials() {
    when(
      () => _login.execute(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const UnauthorizedError('Invalid credentials'));
    return this;
  }

  AuthViewModelTestApi givenRegisterSucceeds({AuthUser user = defaultUser}) {
    when(
      () => _register.execute(
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);
    return this;
  }

  AuthViewModelTestApi givenRestoreSessionReturns(AuthUser? user) {
    when(() => _restoreSession.execute()).thenAnswer((_) async => user);
    return this;
  }

  /// Simula un fallo transitorio (red/servidor) al hidratar progreso tras
  /// login/register/restore — el caso central del bug fix de esta rama.
  AuthViewModelTestApi givenProgressHydrationFailsWithATransientError() {
    when(() => _progressSync.pullAndApplyLocal())
        .thenThrow(const NetworkError('GET /progress timed out'));
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────

  Future<AuthViewModelTestApi> whenLoggingIn({
    String email = 'alice@example.com',
    String password = 'password123',
  }) async {
    await _viewModel.login(email, password);
    return this;
  }

  Future<AuthViewModelTestApi> whenRegistering({
    String username = 'alice',
    String email = 'alice@example.com',
    String password = 'password123',
  }) async {
    await _viewModel.register(
      username: username,
      email: email,
      password: password,
    );
    return this;
  }

  Future<AuthViewModelTestApi> whenLoggingOut() async {
    await _viewModel.logout();
    return this;
  }

  /// Reconstruye el ViewModel con `restoreOnInit: true` (comportamiento real
  /// de arranque) y espera a que la restauración asíncrona se complete.
  Future<AuthViewModelTestApi> whenRestoringSessionAtStartup() async {
    _viewModel = AuthViewModel(
      login: _login,
      register: _register,
      logout: _logout,
      restoreSession: _restoreSession,
      progressSync: _progressSync,
      sessionCleanup: _sessionCleanup,
    );
    await Future<void>.delayed(Duration.zero);
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────

  void thenLoginShouldBeCalledBeforeProgressPull() {
    verifyInOrder([
      () => _login.execute(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
      () => _progressSync.pullAndApplyLocal(),
    ]);
  }

  void thenProgressShouldBePulled() =>
      verify(() => _progressSync.pullAndApplyLocal()).called(1);

  void thenProgressShouldNotBePulled() =>
      verifyNever(() => _progressSync.pullAndApplyLocal());

  void thenSessionShouldBeAuthenticated() =>
      expect(_viewModel.state.status, AuthStatus.authenticated);

  void thenSessionShouldBeUnauthenticated() =>
      expect(_viewModel.state.status, AuthStatus.unauthenticated);

  void thenThereShouldBeNoErrorMessage() =>
      expect(_viewModel.state.errorMessage, isNull);

  void thenLogoutShouldBeCalledBeforeSessionCleanup() {
    verifyInOrder([
      () => _logout.execute(),
      () => _sessionCleanup.clearSessionState(),
    ]);
  }

  void thenUserShouldBeCleared() => expect(_viewModel.state.user, isNull);
}
