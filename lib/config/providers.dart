import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/ports/i_token_storage.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';
import 'package:arrow_maze/application/ports/i_survival_repository.dart';
import 'package:arrow_maze/application/proxies/caching_use_case_proxy.dart';
import 'package:arrow_maze/application/proxies/exception_handling_proxy.dart';
import 'package:arrow_maze/application/proxies/use_case_logger_proxy.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/use_cases/complete_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/generate_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/get_level_catalog_use_case.dart';
import 'package:arrow_maze/application/use_cases/get_level_selection_use_case.dart';
import 'package:arrow_maze/application/use_cases/i_remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/load_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/remove_arrow_use_case.dart';
import 'package:arrow_maze/application/use_cases/restart_level_use_case.dart';
import 'package:arrow_maze/application/use_cases/save_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/undo_move_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';
import 'package:arrow_maze/application/use_cases/survival/get_survival_leaderboard_use_case.dart';
import 'package:arrow_maze/application/use_cases/survival/submit_survival_run_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/hydrate_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/push_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';
import 'package:arrow_maze/config/api_config.dart';
import 'package:arrow_maze/config/progress_sync_coordinator.dart';
import 'package:arrow_maze/domain/ports/i_arrow_placer.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/ports/i_time_service.dart';
import 'package:arrow_maze/domain/services/procedural_arrow_placer.dart';
import 'package:arrow_maze/infrastructure/api/http_api_client.dart';
import 'package:arrow_maze/infrastructure/catalog/asset_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/composite_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/generated_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/repositories/asset_json_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/chained_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/generated_json_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_generated_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_player_progress_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_token_storage.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_user_storage.dart';
import 'package:arrow_maze/infrastructure/repositories/survival_repository_impl.dart';
import 'package:arrow_maze/infrastructure/services/api_level_generator_service.dart';
import 'package:arrow_maze/infrastructure/services/audio_service.dart';
import 'package:arrow_maze/infrastructure/services/stopwatch_time_service.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_view_model.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_view_model.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_state.dart';
import 'package:arrow_maze/presentation/view_models/leaderboard/leaderboard_view_model.dart';
import 'package:arrow_maze/presentation/view_models/level_select_state.dart';
import 'package:arrow_maze/presentation/view_models/level_select_view_model.dart';
import 'package:arrow_maze/presentation/view_models/survival/survival_state.dart';
import 'package:arrow_maze/presentation/view_models/survival/survival_view_model.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_state.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_view_model.dart';

// --- Infraestructura: SharedPreferences ---
// Sobreescrito en main() con la instancia real antes de runApp().

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

// ?? Infraestructura: repositorios ?????????????????????????????????????????????

final levelBuilderProvider = Provider<LevelBuilder>((_) => LevelBuilder());

final generatedLevelRepositoryProvider = Provider<IGeneratedLevelRepository>(
  (ref) =>
      SharedPrefsGeneratedLevelRepository(ref.read(sharedPreferencesProvider)),
);

final playerProgressRepositoryProvider = Provider<IPlayerProgressRepository>(
  (ref) =>
      SharedPrefsPlayerProgressRepository(ref.read(sharedPreferencesProvider)),
);

// ChainedLevelRepository: Chain of Responsibility ? assets ? generated.
final levelRepositoryProvider = Provider<ILevelRepository>(
  (ref) => ChainedLevelRepository([
    AssetJsonLevelRepository(builder: ref.read(levelBuilderProvider)),
    GeneratedJsonLevelRepository(
      source: ref.read(generatedLevelRepositoryProvider),
      builder: ref.read(levelBuilderProvider),
    ),
  ]),
);

final timeServiceProvider = Provider<ITimeService>(
  (_) => StopwatchTimeService(),
);

final audioServiceProvider = Provider<IAudioService>((_) => AudioService());

// ── Infraestructura: AI generator ────────────────────────────────────────────
// Delega en el backend (POST /levels/generate) vía apiClientProvider: el
// frontend no ve ningún proveedor de IA ni API key directamente (DIP).

final levelGeneratorServiceProvider = Provider<ILevelGeneratorService>(
  (ref) => ApiLevelGeneratorService(apiClient: ref.read(apiClientProvider)),
);

/// Strategy de dominio: coloca las flechas de forma determinista sobre la
/// silueta que devuelve la IA (ver GenerateLevelUseCase).
final arrowPlacerProvider = Provider<IArrowPlacer>(
  (_) => ProceduralArrowPlacer(),
);

// ?? Infraestructura: cat?logo (Strategy + Composite) ?????????????????????????

final levelCatalogServiceProvider = Provider<ILevelCatalogService>(
  (ref) => CompositeLevelCatalogService([
    const AssetLevelCatalogService(),
    GeneratedLevelCatalogService(ref.read(generatedLevelRepositoryProvider)),
  ]),
);

// --- Aplicacion: casos de uso remotos (auth + leaderboard + progress-sync) ---

final commandInvokerProvider = Provider<CommandInvoker>(
  (_) => CommandInvoker(),
);

final removeArrowUseCaseProvider = Provider<IRemoveArrowUseCase>(
  (ref) => UseCaseLoggerProxy(
    delegate: RemoveArrowUseCase(invoker: ref.read(commandInvokerProvider)),
  ),
);

final loadLevelUseCaseProvider = Provider<LoadLevelUseCase>(
  (ref) => LoadLevelUseCase(repository: ref.read(levelRepositoryProvider)),
);

final restartLevelUseCaseProvider = Provider<RestartLevelUseCase>(
  (ref) => RestartLevelUseCase(
    repository: ref.read(levelRepositoryProvider),
    invoker: ref.read(commandInvokerProvider),
  ),
);

final undoMoveUseCaseProvider = Provider<UndoMoveUseCase>(
  (ref) => UndoMoveUseCase(invoker: ref.read(commandInvokerProvider)),
);

final saveProgressUseCaseProvider = Provider<SaveProgressUseCase>(
  (ref) => SaveProgressUseCase(
    repository: ref.read(playerProgressRepositoryProvider),
  ),
);

final completeLevelUseCaseProvider = Provider<CompleteLevelUseCase>(
  (ref) => CompleteLevelUseCase(
    repository: ref.read(playerProgressRepositoryProvider),
  ),
);

final getLevelSelectionUseCaseProvider = Provider<GetLevelSelectionUseCase>(
  (ref) => GetLevelSelectionUseCase(
    catalog: ref.read(levelCatalogServiceProvider),
    progress: ref.read(playerProgressRepositoryProvider),
  ),
);

final generateLevelUseCaseProvider = Provider<GenerateLevelUseCase>(
  (ref) => GenerateLevelUseCase(
    generator: ref.read(levelGeneratorServiceProvider),
    repository: ref.read(generatedLevelRepositoryProvider),
    builder: ref.read(levelBuilderProvider),
    arrowPlacer: ref.read(arrowPlacerProvider),
  ),
);

final getLevelCatalogUseCaseProvider = FutureProvider<List<LevelPreview>>((
  ref,
) {
  return GetLevelCatalogUseCase(
    catalog: ref.read(levelCatalogServiceProvider),
  ).execute();
});

// ?? Notifier: generaci?n de niveles ??????????????????????????????????????????

final generateLevelViewModelProvider =
    StateNotifierProvider<GenerateLevelViewModel, GenerateLevelState>(
      (ref) => GenerateLevelViewModel(ref.read(generateLevelUseCaseProvider)),
    );

// --- Infraestructura: apiClient ---
final httpClientProvider = Provider<http.Client>((_) => http.Client());

final tokenStorageProvider = Provider<ITokenStorage>(
  (ref) => SharedPrefsTokenStorage(ref.read(sharedPreferencesProvider)),
);

final userStorageProvider = Provider<IUserStorage>(
  (ref) => SharedPrefsUserStorage(ref.read(sharedPreferencesProvider)),
);

// AOP: ExceptionHandlingApiClientProxy centraliza el manejo de errores de red
// (mapeo uniforme a ApiError + reintento de fallos transitorios) sobre el
// adapter HTTP real, de forma transparente para todos los casos de uso.
final apiClientProvider = Provider<IApiClient>(
  (ref) => ExceptionHandlingApiClientProxy(
    delegate: HttpApiClient(
      httpClient: ref.read(httpClientProvider),
      tokenStorage: ref.read(tokenStorageProvider),
      baseUrl: ApiConfig.baseUrl,
    ),
  ),
);

// --- Aplicacion: casos de uso remotos (auth + leaderboard + progress-sync) ---

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(
    api: ref.read(apiClientProvider),
    userStorage: ref.read(userStorageProvider),
  ),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(
    api: ref.read(apiClientProvider),
    userStorage: ref.read(userStorageProvider),
  ),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(
    api: ref.read(apiClientProvider),
    userStorage: ref.read(userStorageProvider),
    progress: ref.read(playerProgressRepositoryProvider),
  ),
);

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>(
  (ref) => RestoreSessionUseCase(
    tokenStorage: ref.read(tokenStorageProvider),
    userStorage: ref.read(userStorageProvider),
  ),
);

final sessionCleanupProvider = Provider<ISessionCleanup>(
  (ref) => _RiverpodSessionCleanup(ref),
);

// AOP: CachingUseCaseProxy memoiza el leaderboard por (levelId, limit) durante
// un TTL corto, evitando golpear la red en cada refresco de la pantalla.
final getLeaderboardUseCaseProvider = Provider<CachingUseCaseProxy>(
  (ref) => CachingUseCaseProxy(
    delegate: GetLeaderboardUseCase(api: ref.read(apiClientProvider)),
    ttl: const Duration(seconds: 30),
  ),
);

final leaderboardViewModelProvider =
    StateNotifierProvider<LeaderboardViewModel, LeaderboardState>(
      (ref) => LeaderboardViewModel(
        getLeaderboard: ref.read(getLeaderboardUseCaseProvider),
      ),
    );

// --- Survival (modo supervivencia) ---

final survivalRepositoryProvider = Provider<ISurvivalRepository>(
  (ref) => SurvivalRepositoryImpl(api: ref.read(apiClientProvider)),
);

final submitSurvivalRunUseCaseProvider = Provider<SubmitSurvivalRunUseCase>(
  (ref) => SubmitSurvivalRunUseCase(
    repository: ref.read(survivalRepositoryProvider),
  ),
);

final getSurvivalLeaderboardUseCaseProvider =
    Provider<GetSurvivalLeaderboardUseCase>(
      (ref) => GetSurvivalLeaderboardUseCase(
        repository: ref.read(survivalRepositoryProvider),
      ),
    );

final syncProgressUseCaseProvider = Provider<SyncProgressUseCase>(
  (ref) => SyncProgressUseCase(api: ref.read(apiClientProvider)),
);

final hydrateProgressUseCaseProvider = Provider<HydrateProgressUseCase>(
  (ref) => HydrateProgressUseCase(
    sync: ref.read(syncProgressUseCaseProvider),
    local: ref.read(playerProgressRepositoryProvider),
    catalog: ref.read(levelCatalogServiceProvider),
  ),
);

final pushProgressUseCaseProvider = Provider<PushProgressUseCase>(
  (ref) => PushProgressUseCase(
    sync: ref.read(syncProgressUseCaseProvider),
    local: ref.read(playerProgressRepositoryProvider),
    tokens: ref.read(tokenStorageProvider),
  ),
);

final progressSyncCoordinatorProvider = Provider<IProgressSyncCoordinator>(
  (ref) => ProgressSyncCoordinator(
    hydrate: ref.read(hydrateProgressUseCaseProvider),
    push: ref.read(pushProgressUseCaseProvider),
    onHydrated: () => ref.invalidate(levelSelectViewModelProvider),
    onLeaderboardUpdated: (levelId) =>
        ref.read(getLeaderboardUseCaseProvider).invalidate(levelId: levelId),
  ),
);

// --- AuthViewModel ---

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(
    login: ref.read(loginUseCaseProvider),
    register: ref.read(registerUseCaseProvider),
    logout: ref.read(logoutUseCaseProvider),
    restoreSession: ref.read(restoreSessionUseCaseProvider),
    progressSync: ref.read(progressSyncCoordinatorProvider),
    sessionCleanup: ref.read(sessionCleanupProvider),
  ),
);

// --- GameViewModel ---

final gameViewModelProvider = StateNotifierProvider<GameViewModel, GameState>(
  (ref) => GameViewModel(
    loadLevel: ref.read(loadLevelUseCaseProvider),
    removeArrow: ref.read(removeArrowUseCaseProvider),
    restart: ref.read(restartLevelUseCaseProvider),
    undo: ref.read(undoMoveUseCaseProvider),
    completeLevel: ref.read(completeLevelUseCaseProvider),
    timeService: ref.read(timeServiceProvider),
    audioService: ref.read(audioServiceProvider),
    progressSync: ref.read(progressSyncCoordinatorProvider),
  ),
);

// --- SurvivalViewModel ---

final survivalViewModelProvider =
    StateNotifierProvider<SurvivalViewModel, SurvivalState>((ref) {
      final game = ref.read(gameViewModelProvider.notifier);
      final vm = SurvivalViewModel(
        game: game,
        submitSurvivalRun: ref.read(submitSurvivalRunUseCaseProvider),
        levelCatalog: ref.read(levelCatalogServiceProvider),
        audioService: ref.read(audioServiceProvider),
        isAuthenticated: () =>
            ref.read(authViewModelProvider).status == AuthStatus.authenticated,
      );

      // Orquestacion: ante victoria del tablero, el superviviente carga
      // automaticamente el siguiente nivel (sin overlays de campana).
      ref.listen<GameState>(gameViewModelProvider, (_, next) {
        vm.onGameStateChanged(next);
      });

      return vm;
    });

// --- LevelSelectViewModel ---

final levelSelectViewModelProvider =
    StateNotifierProvider<LevelSelectViewModel, LevelSelectState>(
      (ref) => LevelSelectViewModel(
        getSelection: ref.read(getLevelSelectionUseCaseProvider),
      ),
    );

// --- SettingsViewModel (idioma + mute) ---

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>(
      (ref) => SettingsViewModel(audioService: ref.read(audioServiceProvider)),
    );

/// Adapter Riverpod: invalida estado en memoria al cerrar sesi?n, para que
/// la UI refleje progreso vac?o (invitado) sin acoplar el ViewModel de auth
/// a Riverpod directamente (DIP v?a [ISessionCleanup]).
class _RiverpodSessionCleanup implements ISessionCleanup {
  const _RiverpodSessionCleanup(this._ref);

  final Ref _ref;

  @override
  void clearSessionState() {
    _ref.invalidate(levelSelectViewModelProvider);
    _ref.invalidate(gameViewModelProvider);
  }
}
