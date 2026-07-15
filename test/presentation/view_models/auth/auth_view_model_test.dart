import 'package:flutter_test/flutter_test.dart';

import '../../../_support/apis/auth_view_model_test_api.dart';

void main() {
  group('AuthViewModel — progress hydration', () {
    test('should_pull_progress_after_successful_login', () async {
      final api = AuthViewModelTestApi().givenLoginSucceeds();
      await api.whenLoggingIn();

      api.thenLoginShouldBeCalledBeforeProgressPull();
      api.thenSessionShouldBeAuthenticated();
    });

    test('should_pull_progress_after_successful_register', () async {
      final api = AuthViewModelTestApi().givenRegisterSucceeds();
      await api.whenRegistering();

      api.thenProgressShouldBePulled();
      api.thenSessionShouldBeAuthenticated();
    });

    test('should_pull_progress_after_session_restore', () async {
      final api = AuthViewModelTestApi()
          .givenRestoreSessionReturns(AuthViewModelTestApi.defaultUser);
      await api.whenRestoringSessionAtStartup();

      api.thenProgressShouldBePulled();
      api.thenSessionShouldBeAuthenticated();
    });

    test(
        'should_initialize_empty_progress_silently_when_pull_returns_404',
        () async {
      // El 404 ya se absorbe dentro de IProgressSyncCoordinator; aquí solo
      // confirmamos que un pull "vacío" no impide reportar un login exitoso.
      final api = AuthViewModelTestApi().givenLoginSucceeds();
      await api.whenLoggingIn();

      api.thenSessionShouldBeAuthenticated();
      api.thenThereShouldBeNoErrorMessage();
    });

    test('should_not_pull_progress_when_login_fails', () async {
      final api =
          AuthViewModelTestApi().givenLoginFailsWithInvalidCredentials();
      await api.whenLoggingIn();

      api.thenProgressShouldNotBePulled();
      api.thenSessionShouldBeUnauthenticated();
    });

    test('should_clear_progress_and_refresh_ui_when_logging_out', () async {
      final api = AuthViewModelTestApi().givenLoginSucceeds();
      await api.whenLoggingIn();
      await api.whenLoggingOut();

      api.thenLogoutShouldBeCalledBeforeSessionCleanup();
      api.thenSessionShouldBeUnauthenticated();
      api.thenUserShouldBeCleared();
    });
  });

  // Bug fix (progress-sync-integration): un GET /progress fallido justo tras
  // un login/register válido ya NO debe reportarse como fallo de sesión.
  group('AuthViewModel — transient progress hydration failure after auth', () {
    test(
        'should_stay_authenticated_when_post_login_hydration_fails_transiently',
        () async {
      final api = AuthViewModelTestApi()
          .givenLoginSucceeds()
          .givenProgressHydrationFailsWithATransientError();
      await api.whenLoggingIn();

      api.thenSessionShouldBeAuthenticated();
      api.thenThereShouldBeNoErrorMessage();
    });

    test(
        'should_stay_authenticated_when_post_register_hydration_fails_transiently',
        () async {
      final api = AuthViewModelTestApi()
          .givenRegisterSucceeds()
          .givenProgressHydrationFailsWithATransientError();
      await api.whenRegistering();

      api.thenSessionShouldBeAuthenticated();
      api.thenThereShouldBeNoErrorMessage();
    });
  });
}
