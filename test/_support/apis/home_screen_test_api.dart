import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_view_model.dart';
import 'package:arrow_maze/presentation/views/screens/home_screen.dart';
import 'package:arrow_maze/presentation/views/screens/level_select_screen.dart';
import 'package:arrow_maze/presentation/views/screens/settings_screen.dart';
import 'package:arrow_maze/presentation/views/widgets/animated_logo.dart';

import '../fakes/fake_audio_service.dart';
import '../fakes/fake_level_catalog_service.dart';
import '../fakes/fake_player_progress_repository.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockRegisterUseCase extends Mock implements RegisterUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MockRestoreSessionUseCase extends Mock
    implements RestoreSessionUseCase {}

class _MockProgressSyncCoordinator extends Mock
    implements IProgressSyncCoordinator {}

class _MockSessionCleanup extends Mock implements ISessionCleanup {}

/// Testing API (nivel medio) para las pruebas de render y navegación de la Home.
/// Oculta el `ProviderScope`, los fakes (audio, catálogo, progreso) y la
/// localización tras una interfaz encadenable given/when/then. Los `test(...)`
/// hablan solo el lenguaje de negocio de la pantalla de inicio.
class HomeScreenTestApi {
  static const AuthUser _authenticatedUser = AuthUser(
    id: 'u-1',
    username: 'alice',
    email: 'alice@example.com',
  );

  // Strings tal como las expone app_es.arb — la Home siempre se prueba en
  // español (mismo criterio que el resto de la suite, ej. find.text('JUGAR')).
  static const String _loginPromptTitle = '¿Quieres guardar tu progreso?';
  static const String _loginPromptGuestButton = 'Continuar como invitado';
  static const String _loginPromptLoginButton = 'Iniciar sesión';

  final WidgetTester _tester;
  final FakeAudioService _audio = FakeAudioService();
  final FakeLevelCatalogService _catalog = FakeLevelCatalogService();
  final FakePlayerProgressRepository _progress = FakePlayerProgressRepository();

  HomeScreenTestApi(this._tester);

  Future<HomeScreenTestApi> givenTheHomeScreenIsOpen() async {
    // HomeScreen observa authViewModelProvider (prompt de login / menú de
    // cuenta) → necesita sharedPreferencesProvider real para construir la
    // cadena tokenStorage/userStorage/restoreSession. Sin token guardado, la
    // restauración de sesión resuelve a "no autenticado" sin tocar la red.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pump(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    return this;
  }

  /// Abre la Home ya con una sesión autenticada, sustituyendo
  /// [authViewModelProvider] por un [AuthViewModel] cuyos casos de uso están
  /// mockeados (no se ejecutan) y cuyo estado inicial ya es "authenticated" —
  /// evita depender de una restauración de sesión real vía SharedPreferences.
  Future<HomeScreenTestApi> givenTheHomeScreenIsOpenWhileAuthenticated() async {
    final logout = _MockLogoutUseCase();
    final sessionCleanup = _MockSessionCleanup();
    when(() => logout.execute()).thenAnswer((_) async {});
    when(() => sessionCleanup.clearSessionState()).thenReturn(null);

    await _pump(
      overrides: [
        authViewModelProvider.overrideWith(
          (ref) => AuthViewModel(
            login: _MockLoginUseCase(),
            register: _MockRegisterUseCase(),
            logout: logout,
            restoreSession: _MockRestoreSessionUseCase(),
            progressSync: _MockProgressSyncCoordinator(),
            sessionCleanup: sessionCleanup,
            restoreOnInit: false,
            initialState: const AuthState.authenticated(_authenticatedUser),
          ),
        ),
      ],
    );
    return this;
  }

  Future<void> _pump({required List<Override> overrides}) async {
    await _tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(_audio),
          // La pantalla de selección (destino de "JUGAR") carga el catálogo al
          // abrirse; con catálogo vacío se pinta sin depender de assets/SharedPrefs.
          levelCatalogServiceProvider.overrideWithValue(_catalog),
          playerProgressRepositoryProvider.overrideWithValue(_progress),
          ...overrides,
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );
    await _tester.pumpAndSettle();
  }

  Future<HomeScreenTestApi> whenTheSettingsButtonIsTapped() async {
    await _tester.tap(find.byKey(HomeScreen.settingsButtonKey));
    await _tester.pumpAndSettle();
    return this;
  }

  Future<HomeScreenTestApi> whenThePlayButtonIsTapped() async {
    await _tester.tap(find.byKey(HomeScreen.playButtonKey));
    await _tester.pumpAndSettle();
    return this;
  }

  Future<HomeScreenTestApi> whenTheContinueAsGuestOptionIsTapped() async {
    await _tester.tap(find.text(_loginPromptGuestButton));
    await _tester.pumpAndSettle();
    return this;
  }

  Future<HomeScreenTestApi> whenTheLoginOptionIsTapped() async {
    await _tester.tap(find.text(_loginPromptLoginButton));
    await _tester.pumpAndSettle();
    return this;
  }

  void thenTheSettingsScreenShouldBeShown() =>
      expect(find.byType(SettingsScreen), findsOneWidget);

  void thenTheLevelSelectScreenShouldBeShown() =>
      expect(find.byType(LevelSelectScreen), findsOneWidget);

  void thenTheHomeScreenShouldBeShown() =>
      expect(find.byType(HomeScreen), findsOneWidget);

  void thenTheTitleAndPlayButtonShouldBeShown() {
    expect(find.byType(AnimatedLogo), findsOneWidget);
    expect(find.text('JUGAR'), findsOneWidget);
  }

  void thenTheLoginPromptShouldBeShown() =>
      expect(find.text(_loginPromptTitle), findsOneWidget);

  void thenTheLoginPromptShouldNotBeShown() =>
      expect(find.text(_loginPromptTitle), findsNothing);

  void thenTheAccountButtonShouldBeShown() =>
      expect(find.byKey(HomeScreen.accountButtonKey), findsOneWidget);

  void thenTheAccountButtonShouldNotBeShown() =>
      expect(find.byKey(HomeScreen.accountButtonKey), findsNothing);
}
