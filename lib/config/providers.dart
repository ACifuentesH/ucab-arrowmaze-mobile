import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/commands/command_invoker.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';
import 'package:arrow_maze/application/ports/i_leaderboard_repository.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';
import 'package:arrow_maze/application/ports/i_progress_repository.dart';
import 'package:arrow_maze/application/ports/i_progress_sync_coordinator.dart';
import 'package:arrow_maze/application/proxies/use_case_logger_proxy.dart';
import 'package:arrow_maze/application/services/session_cleanup.dart';
import 'package:arrow_maze/application/services/session_expired_notifier.dart';
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
import 'package:arrow_maze/application/use_cases/progress/hydrate_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/push_progress_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';
import 'package:arrow_maze/config/api_config.dart';
import 'package:arrow_maze/config/progress_sync_coordinator.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/ports/i_time_service.dart';
import 'package:arrow_maze/infrastructure/api/dio_api_client.dart';
import 'package:arrow_maze/infrastructure/catalog/asset_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/composite_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/generated_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/repositories/asset_json_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/auth_repository_impl.dart';
import 'package:arrow_maze/infrastructure/repositories/composite_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/generated_json_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/remote_api_repositories.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_generated_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_player_progress_repository.dart';
import 'package:arrow_maze/infrastructure/storage/secure_storage_impl.dart';
import 'package:arrow_maze/infrastructure/services/audio_service.dart';
import 'package:arrow_maze/infrastructure/services/groq_level_generator_service.dart';
import 'package:arrow_maze/infrastructure/services/stopwatch_time_service.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_view_model.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_view_model.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_state.dart';
import 'package:arrow_maze/presentation/view_models/level_select_state.dart';
import 'package:arrow_maze/presentation/view_models/level_select_view_model.dart';

// ── Infraestructura: SharedPreferences ───────────────────────────────────────
// Sobreescrito en main() con la instancia real antes de runApp().

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

// ── Infraestructura: repositorios ─────────────────────────────────────────────

final levelBuilderProvider = Provider<LevelBuilder>(
  (_) => LevelBuilder(),
);

final generatedLevelRepositoryProvider = Provider<IGeneratedLevelRepository>(
  (ref) => SharedPrefsGeneratedLevelRepository(
    ref.read(sharedPreferencesProvider),
  ),
);

final playerProgressRepositoryProvider = Provider<IPlayerProgressRepository>(
  (ref) => SharedPrefsPlayerProgressRepository(
    ref.read(sharedPreferencesProvider),
  ),
);

// CompositeLevelRepository: Chain of Responsibility — assets → generated.
final levelRepositoryProvider = Provider<ILevelRepository>(
  (ref) => CompositeLevelRepository([
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

final audioServiceProvider = Provider<IAudioService>(
  (_) => AudioService(),
);

// ── Infraestructura: AI generator ────────────────────────────────────────────

/// La API key se inyecta vía --dart-define=GROQ_API_KEY=gsk_...
/// Ejemplo: flutter run --dart-define=GROQ_API_KEY=gsk_xxxx
const _groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

final levelGeneratorServiceProvider = Provider<ILevelGeneratorService>(
  (_) => GroqLevelGeneratorService(apiKey: _groqApiKey),
);

// ── Infraestructura: catálogo (Strategy + Composite) ─────────────────────────

final levelCatalogServiceProvider = Provider<ILevelCatalogService>(
  (ref) => CompositeLevelCatalogService([
    const AssetLevelCatalogService(),
    GeneratedLevelCatalogService(ref.read(generatedLevelRepositoryProvider)),
  ]),
);

// ── Aplicación: casos de uso ──────────────────────────────────────────────────

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
  ),
);

final getLevelCatalogUseCaseProvider =
    FutureProvider<List<LevelPreview>>((ref) {
  return GetLevelCatalogUseCase(
    catalog: ref.read(levelCatalogServiceProvider),
  ).execute();
});

// ── Notifier: generación de niveles ──────────────────────────────────────────

final generateLevelViewModelProvider =
    StateNotifierProvider<GenerateLevelViewModel, GenerateLevelState>(
  (ref) => GenerateLevelViewModel(ref.read(generateLevelUseCaseProvider)),
);

// ── Infraestructura: red (Dio + almacenamiento seguro) ───────────────────────

final sessionExpiredNotifierProvider = Provider<SessionExpiredNotifier>(
  (_) => SessionExpiredNotifier(),
);

final sessionCleanupProvider = Provider<ISessionCleanup>(
  (ref) => _RiverpodSessionCleanup(ref),
);

final localStorageProvider = Provider<ILocalStorage>(
  (_) => SecureStorageImpl(),
);

final dioProvider = Provider<Dio>((_) => Dio());

final apiClientProvider = Provider<IApiClient>(
  (ref) => DioApiClient(
    dio: ref.read(dioProvider),
    storage: ref.read(localStorageProvider),
    sessionExpired: ref.read(sessionExpiredNotifierProvider),
    baseUrl: ApiConfig.baseUrl,
  ),
);

final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => AuthRepositoryImpl(
    api: ref.read(apiClientProvider),
    storage: ref.read(localStorageProvider),
  ),
);

final progressRepositoryProvider = Provider<IProgressRepository>(
  (ref) => ProgressRepositoryImpl(
    api: ref.read(apiClientProvider),
    storage: ref.read(localStorageProvider),
  ),
);

final leaderboardRepositoryProvider = Provider<ILeaderboardRepository>(
  (ref) => LeaderboardRepositoryImpl(api: ref.read(apiClientProvider)),
);

// ── Aplicación: casos de uso remotos ─────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(auth: ref.read(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(auth: ref.read(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(auth: ref.read(authRepositoryProvider)),
);

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>(
  (ref) => RestoreSessionUseCase(auth: ref.read(authRepositoryProvider)),
);

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(
    login: ref.read(loginUseCaseProvider),
    register: ref.read(registerUseCaseProvider),
    logout: ref.read(logoutUseCaseProvider),
    restoreSession: ref.read(restoreSessionUseCaseProvider),
    progressSync: ref.read(progressSyncCoordinatorProvider),
    sessionExpired: ref.read(sessionExpiredNotifierProvider),
    sessionCleanup: ref.read(sessionCleanupProvider),
  ),
);

final authStatusProvider = Provider<AuthStatus>(
  (ref) => ref.watch(authViewModelProvider).status,
);

final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>(
  (ref) => GetLeaderboardUseCase(
    leaderboard: ref.read(leaderboardRepositoryProvider),
  ),
);

final syncProgressUseCaseProvider = Provider<SyncProgressUseCase>(
  (ref) => SyncProgressUseCase(
    progress: ref.read(progressRepositoryProvider),
  ),
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
    storage: ref.read(localStorageProvider),
  ),
);

final progressSyncCoordinatorProvider = Provider<IProgressSyncCoordinator>(
  (ref) => ProgressSyncCoordinator(
    hydrate: ref.read(hydrateProgressUseCaseProvider),
    push: ref.read(pushProgressUseCaseProvider),
    onHydrated: () => ref.invalidate(levelSelectViewModelProvider),
  ),
);

// ── GameViewModel ─────────────────────────────────────────────────────────

final gameViewModelProvider =
    StateNotifierProvider<GameViewModel, GameState>(
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

class _RiverpodSessionCleanup implements ISessionCleanup {
  const _RiverpodSessionCleanup(this._ref);

  final Ref _ref;

  @override
  void clearSessionState() {
    _ref.invalidate(gameViewModelProvider);
    _ref.invalidate(generateLevelViewModelProvider);
    _ref.invalidate(getLevelCatalogUseCaseProvider);
    _ref.invalidate(commandInvokerProvider);
    _ref.invalidate(levelSelectViewModelProvider);
  }
}
// ── LevelSelectViewModel ──────────────────────────────────────────────────

final levelSelectViewModelProvider =
    StateNotifierProvider<LevelSelectViewModel, LevelSelectState>(
  (ref) => LevelSelectViewModel(
    getSelection: ref.read(getLevelSelectionUseCaseProvider),
  ),
);
