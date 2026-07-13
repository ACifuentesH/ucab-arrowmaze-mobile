import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_view_model.dart';

import '../../../_support/mothers/user_mother.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockSessionCleanup extends Mock implements ISessionCleanup {}

/// Pruebas de caja negra sobre el estado público de [AuthViewModel].
void main() {
  group('AuthViewModel', () {
    late MockAuthRepository auth;
    late MockSessionCleanup sessionCleanup;
    late AuthViewModel viewModel;

    setUp(() {
      auth = MockAuthRepository();
      sessionCleanup = MockSessionCleanup();
      when(() => sessionCleanup.clearSessionState()).thenReturn(null);

      viewModel = AuthViewModel(
        login: LoginUseCase(auth: auth),
        register: RegisterUseCase(auth: auth),
        logout: LogoutUseCase(auth: auth),
        restoreSession: RestoreSessionUseCase(auth: auth),
        sessionCleanup: sessionCleanup,
        restoreOnInit: false,
        initialState: const AuthState(),
      );
    });

    test('should_be_unauthenticated_by_default', () {
      expect(viewModel.state.status, AuthStatus.unauthenticated);
      expect(viewModel.state.user, isNull);
    });

    test('should_transition_to_authenticated_when_login_succeeds', () async {
      when(
        () => auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => UserMother.alice());

      await viewModel.login('alice@example.com', 'password123');

      expect(viewModel.state.status, AuthStatus.authenticated);
      expect(viewModel.state.user?.id, 'u-1');
      expect(viewModel.state.user?.username, 'alice');
      expect(viewModel.state.user?.email, 'alice@example.com');
      expect(viewModel.state.errorMessage, isNull);
    });

    test('should_transition_to_unauthenticated_when_login_fails', () async {
      when(
        () => auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const UnauthorizedError('Invalid credentials'));

      await viewModel.login('alice@example.com', 'wrong');

      expect(viewModel.state.status, AuthStatus.unauthenticated);
      expect(viewModel.state.user, isNull);
      expect(viewModel.state.errorMessage, 'Invalid credentials');
    });

    test('should_transition_to_unauthenticated_and_clear_state_on_logout',
        () async {
      when(
        () => auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => UserMother.alice());
      when(() => auth.logout()).thenAnswer((_) async {});

      await viewModel.login('alice@example.com', 'password123');
      await viewModel.logout();

      expect(viewModel.state.status, AuthStatus.unauthenticated);
      expect(viewModel.state.user, isNull);
      verify(() => sessionCleanup.clearSessionState()).called(1);
    });

    test('should_transition_to_unauthenticated_when_session_expires',
        () async {
      when(
        () => auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => UserMother.alice());

      await viewModel.login('alice@example.com', 'password123');
      viewModel.handleSessionExpired();

      expect(viewModel.state.status, AuthStatus.unauthenticated);
      expect(viewModel.state.user, isNull);
      expect(
        viewModel.state.errorMessage,
        'Tu sesión expiró. Inicia sesión de nuevo.',
      );
      verify(() => sessionCleanup.clearSessionState()).called(1);
    });

    test('should_ignore_session_expired_signal_when_not_authenticated', () {
      viewModel.handleSessionExpired();

      expect(viewModel.state.status, AuthStatus.unauthenticated);
      verifyNever(() => sessionCleanup.clearSessionState());
    });

    test('should_start_in_checking_state_when_session_restore_is_pending',
        () async {
      when(() => auth.restoreSession()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return UserMother.alice();
      });

      final restoringViewModel = AuthViewModel(
        login: LoginUseCase(auth: auth),
        register: RegisterUseCase(auth: auth),
        logout: LogoutUseCase(auth: auth),
        restoreSession: RestoreSessionUseCase(auth: auth),
      );

      expect(restoringViewModel.state.status, AuthStatus.checking);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(restoringViewModel.state.status, AuthStatus.authenticated);
      expect(restoringViewModel.state.user?.username, 'alice');
    });

    test('should_restore_authenticated_state_when_stored_session_exists',
        () async {
      when(() => auth.restoreSession()).thenAnswer((_) async => UserMother.alice());

      final restoringViewModel = AuthViewModel(
        login: LoginUseCase(auth: auth),
        register: RegisterUseCase(auth: auth),
        logout: LogoutUseCase(auth: auth),
        restoreSession: RestoreSessionUseCase(auth: auth),
      );

      await Future<void>.delayed(Duration.zero);

      expect(restoringViewModel.state.status, AuthStatus.authenticated);
      expect(restoringViewModel.state.user?.username, 'alice');
    });

    test('should_be_unauthenticated_when_no_stored_session_exists', () async {
      when(() => auth.restoreSession()).thenAnswer((_) async => null);

      final restoringViewModel = AuthViewModel(
        login: LoginUseCase(auth: auth),
        register: RegisterUseCase(auth: auth),
        logout: LogoutUseCase(auth: auth),
        restoreSession: RestoreSessionUseCase(auth: auth),
      );

      await Future<void>.delayed(Duration.zero);

      expect(restoringViewModel.state.status, AuthStatus.unauthenticated);
      expect(restoringViewModel.state.user, isNull);
    });
  });
}
