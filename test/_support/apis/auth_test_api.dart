import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/domain/entities/user.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_view_model.dart';

import '../mothers/user_mother.dart';

class _MockAuthRepository extends Mock implements IAuthRepository {}

class _MockProgressSyncCoordinator extends Mock
    implements IProgressSyncCoordinator {}

class _MockSessionCleanup extends Mock implements ISessionCleanup {}

/// Testing API: autenticación contra [IAuthRepository] y [AuthViewModel].
class AuthTestApi {
  final _MockAuthRepository _auth = _MockAuthRepository();
  final _MockProgressSyncCoordinator _progressSync =
      _MockProgressSyncCoordinator();
  final _MockSessionCleanup _sessionCleanup = _MockSessionCleanup();

  Object? _user;
  Object? _error;
  AuthViewModel? _viewModel;

  AuthTestApi() {
    when(() => _sessionCleanup.clearSessionState()).thenReturn(null);
    when(() => _progressSync.pullAndApplyLocal()).thenAnswer((_) async {});
  }

  AuthTestApi givenAuthAcceptsCredentials() {
    when(() => _auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => UserMother.alice());
    when(() => _auth.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => UserMother.alice());
    return this;
  }

  AuthTestApi givenAuthRejectsCredentials() {
    when(() => _auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const UnauthorizedError('Invalid credentials'));
    return this;
  }

  AuthTestApi givenEmailIsAlreadyRegistered() {
    when(() => _auth.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const ConflictError('Email already registered'));
    return this;
  }

  AuthTestApi givenALocalSessionExists() {
    when(() => _auth.logout()).thenAnswer((_) async {});
    return this;
  }

  AuthTestApi givenAStoredSessionExists() {
    when(() => _auth.restoreSession())
        .thenAnswer((_) async => UserMother.alice());
    return this;
  }

  AuthTestApi givenNoStoredSession() {
    when(() => _auth.restoreSession()).thenAnswer((_) async => null);
    return this;
  }

  AuthTestApi givenStoredSessionRestoresSlowly() {
    when(() => _auth.restoreSession()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return UserMother.alice();
    });
    return this;
  }

  AuthTestApi givenProgressHydrationFailsWithNetwork() {
    when(() => _progressSync.pullAndApplyLocal())
        .thenThrow(const NetworkError('No connection'));
    return this;
  }

  Future<AuthTestApi> whenLoggingIn() async {
    try {
      _user = await LoginUseCase(auth: _auth)
          .execute(email: 'alice@example.com', password: 'password123');
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<AuthTestApi> whenRegistering() async {
    try {
      _user = await RegisterUseCase(auth: _auth).execute(
        username: 'alice',
        email: 'alice@example.com',
        password: 'password123',
      );
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<AuthTestApi> whenLoggingOut() async {
    await LogoutUseCase(auth: _auth).execute();
    return this;
  }

  Future<AuthTestApi> whenRestoringSession() async {
    try {
      _user = await RestoreSessionUseCase(auth: _auth).execute();
    } catch (e) {
      _error = e;
    }
    return this;
  }

  AuthTestApi whenCreatingViewModel({
    bool restoreOnInit = false,
    AuthState? initialState,
  }) {
    _viewModel = AuthViewModel(
      login: LoginUseCase(auth: _auth),
      register: RegisterUseCase(auth: _auth),
      logout: LogoutUseCase(auth: _auth),
      restoreSession: RestoreSessionUseCase(auth: _auth),
      progressSync: _progressSync,
      sessionCleanup: _sessionCleanup,
      restoreOnInit: restoreOnInit,
      initialState: initialState ??
          (restoreOnInit
              ? const AuthState(status: AuthStatus.checking)
              : const AuthState()),
    );
    return this;
  }

  Future<AuthTestApi> whenViewModelLogsIn() async {
    await _requireViewModel().login('alice@example.com', 'password123');
    return this;
  }

  Future<AuthTestApi> whenViewModelLogsOut() async {
    await _requireViewModel().logout();
    return this;
  }

  AuthTestApi whenSessionExpires() {
    _requireViewModel().handleSessionExpired();
    return this;
  }

  Future<AuthTestApi> whenWaitingForSessionRestore() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return this;
  }

  Future<AuthTestApi> whenFlushingMicrotasks() async {
    await Future<void>.delayed(Duration.zero);
    return this;
  }

  void thenUserShouldBeActiveWithId(String userId) {
    expect(_error, isNull);
    expect((_user as User).id, equals(userId));
  }

  void thenRestoredUserShouldBeAlice() {
    expect(_error, isNull);
    expect(_user, UserMother.alice());
  }

  void thenRestoredUserShouldBeAbsent() {
    expect(_error, isNull);
    expect(_user, isNull);
  }

  void thenAuthShouldFailWith<T>() => expect(_error, isA<T>());

  void thenSessionShouldBeClosed() => verify(() => _auth.logout()).called(1);

  void thenViewModelShouldBeUnauthenticated({String? errorMessage}) {
    final vm = _requireViewModel();
    expect(vm.state.status, AuthStatus.unauthenticated);
    expect(vm.state.user, isNull);
    if (errorMessage != null) {
      expect(vm.state.errorMessage, errorMessage);
    }
  }

  void thenViewModelShouldBeAuthenticatedAsAlice() {
    final vm = _requireViewModel();
    expect(vm.state.status, AuthStatus.authenticated);
    expect(vm.state.user?.id, 'u-1');
    expect(vm.state.user?.username, 'alice');
    expect(vm.state.user?.email, 'alice@example.com');
    expect(vm.state.errorMessage, isNull);
  }

  void thenViewModelShouldBeChecking() {
    expect(_requireViewModel().state.status, AuthStatus.checking);
  }

  void thenSessionCleanupShouldHaveBeenCalled() {
    verify(() => _sessionCleanup.clearSessionState()).called(1);
  }

  void thenSessionCleanupShouldNotHaveBeenCalled() {
    verifyNever(() => _sessionCleanup.clearSessionState());
  }

  void thenProgressShouldHaveBeenHydrated() {
    verify(() => _progressSync.pullAndApplyLocal()).called(1);
  }

  AuthViewModel _requireViewModel() {
    final vm = _viewModel;
    if (vm == null) {
      throw StateError('Call whenCreatingViewModel() before view-model assertions');
    }
    return vm;
  }
}
