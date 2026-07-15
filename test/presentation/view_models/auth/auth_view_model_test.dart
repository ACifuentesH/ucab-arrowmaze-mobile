import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/auth_test_api.dart';

void main() {
  group('AuthViewModel', () {
    test('should_be_unauthenticated_by_default', () {
      AuthTestApi()
          .whenCreatingViewModel()
          .thenViewModelShouldBeUnauthenticated();
    });

    test('should_transition_to_authenticated_when_login_succeeds', () async {
      (await AuthTestApi()
              .givenAuthAcceptsCredentials()
              .whenCreatingViewModel()
              .whenViewModelLogsIn())
          .thenViewModelShouldBeAuthenticatedAsAlice();
    });

    test('should_hydrate_progress_when_login_succeeds', () async {
      (await AuthTestApi()
              .givenAuthAcceptsCredentials()
              .whenCreatingViewModel()
              .whenViewModelLogsIn())
          .thenProgressShouldHaveBeenHydrated();
    });

    test('should_remain_authenticated_when_progress_hydration_fails',
        () async {
      (await AuthTestApi()
              .givenAuthAcceptsCredentials()
              .givenProgressHydrationFailsWithNetwork()
              .whenCreatingViewModel()
              .whenViewModelLogsIn())
          .thenViewModelShouldBeAuthenticatedAsAlice();
    });

    test('should_transition_to_unauthenticated_when_login_fails', () async {
      (await AuthTestApi()
              .givenAuthRejectsCredentials()
              .whenCreatingViewModel()
              .whenViewModelLogsIn())
          .thenViewModelShouldBeUnauthenticated(
            errorMessage: 'Invalid credentials',
          );
    });

    test('should_transition_to_unauthenticated_and_clear_state_on_logout',
        () async {
      final api = AuthTestApi()
          .givenAuthAcceptsCredentials()
          .givenALocalSessionExists()
          .whenCreatingViewModel();
      await api.whenViewModelLogsIn();
      (await api.whenViewModelLogsOut())
        ..thenViewModelShouldBeUnauthenticated()
        ..thenSessionCleanupShouldHaveBeenCalled();
    });

    test('should_transition_to_unauthenticated_when_session_expires',
        () async {
      final api = AuthTestApi()
          .givenAuthAcceptsCredentials()
          .whenCreatingViewModel();
      await api.whenViewModelLogsIn();
      api.whenSessionExpires()
        ..thenViewModelShouldBeUnauthenticated(
          errorMessage: 'Tu sesión expiró. Inicia sesión de nuevo.',
        )
        ..thenSessionCleanupShouldHaveBeenCalled();
    });

    test('should_ignore_session_expired_signal_when_not_authenticated', () {
      AuthTestApi()
          .whenCreatingViewModel()
          .whenSessionExpires()
        ..thenViewModelShouldBeUnauthenticated()
        ..thenSessionCleanupShouldNotHaveBeenCalled();
    });

    test('should_start_in_checking_state_when_session_restore_is_pending',
        () async {
      final api = AuthTestApi()
          .givenStoredSessionRestoresSlowly()
          .whenCreatingViewModel(restoreOnInit: true);
      api.thenViewModelShouldBeChecking();
      (await api.whenWaitingForSessionRestore())
          .thenViewModelShouldBeAuthenticatedAsAlice();
    });

    test('should_restore_authenticated_state_when_stored_session_exists',
        () async {
      (await AuthTestApi()
              .givenAStoredSessionExists()
              .whenCreatingViewModel(restoreOnInit: true)
              .whenFlushingMicrotasks())
          .thenViewModelShouldBeAuthenticatedAsAlice();
    });

    test('should_be_unauthenticated_when_no_stored_session_exists', () async {
      (await AuthTestApi()
              .givenNoStoredSession()
              .whenCreatingViewModel(restoreOnInit: true)
              .whenFlushingMicrotasks())
          .thenViewModelShouldBeUnauthenticated();
    });
  });
}
