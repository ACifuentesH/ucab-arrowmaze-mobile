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
import 'package:arrow_maze/application/ports/i_token_storage.dart';
import 'package:arrow_maze/application/proxies/use_case_logger_proxy.dart';
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
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';
import 'package:arrow_maze/application/use_cases/progress/sync_progress_use_case.dart';
import 'package:arrow_maze/config/api_config.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/ports/i_time_service.dart';
import 'package:arrow_maze/infrastructure/api/http_api_client.dart';
import 'package:arrow_maze/infrastructure/catalog/asset_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/composite_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/generated_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/repositories/asset_json_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/composite_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/generated_json_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_generated_level_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_player_progress_repository.dart';
import 'package:arrow_maze/infrastructure/repositories/shared_prefs_token_storage.dart';
import 'package:arrow_maze/infrastructure/services/audio_service.dart';
import 'package:arrow_maze/infrastructure/services/groq_level_generator_service.dart';
import 'package:arrow_maze/infrastructure/services/stopwatch_time_service.dart';
import 'package:arrow_maze/presentation/view_models/game_view_model.dart';
import 'package:arrow_maze/presentation/view_models/game_state.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_view_model.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_state.dart';
import 'package:arrow_maze/presentation/view_models/level_select_state.dart';
import 'package:arrow_maze/presentation/view_models/level_select_view_model.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_state.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_view_model.dart';

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

// ── Infraestructura: apiClient (puerto en application, adapter http) ─────────

final httpClientProvider = Provider<http.Client>((_) => http.Client());

final tokenStorageProvider = Provider<ITokenStorage>(
  (ref) => SharedPrefsTokenStorage(ref.read(sharedPreferencesProvider)),
);

final apiClientProvider = Provider<IApiClient>(
  (ref) => HttpApiClient(
    httpClient: ref.read(httpClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
    baseUrl: ApiConfig.baseUrl,
  ),
);

// ── Aplicación: casos de uso remotos (stubs para feature/auth y
//    feature/leaderboard — ver división de trabajo) ──────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(api: ref.read(apiClientProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(api: ref.read(apiClientProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(api: ref.read(apiClientProvider)),
);

final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>(
  (ref) => GetLeaderboardUseCase(api: ref.read(apiClientProvider)),
);

final syncProgressUseCaseProvider = Provider<SyncProgressUseCase>(
  (ref) => SyncProgressUseCase(api: ref.read(apiClientProvider)),
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
  ),
);

// ── LevelSelectViewModel ──────────────────────────────────────────────────

final levelSelectViewModelProvider =
    StateNotifierProvider<LevelSelectViewModel, LevelSelectState>(
  (ref) => LevelSelectViewModel(
    getSelection: ref.read(getLevelSelectionUseCaseProvider),
  ),
);

// ── SettingsViewModel (idioma + mute) ─────────────────────────────────────

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>(
  (ref) => SettingsViewModel(
    audioService: ref.read(audioServiceProvider),
  ),
);
