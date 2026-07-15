# AI Usage Documentation

**Repository:** ucab-arrowmaze-mobile — Arrow Maze Escape Puzzle (Flutter client)
**Course:** Desarrollo de Software NRC 25783
**Last updated:** 2026-07-07

---

## Tools Used

| Tool | Model | Role |
|------|-------|------|
| Claude Code (Anthropic) | Claude Fable 5 | Primary development assistant — architecture restructuring, apiClient, test suite, CI, level design, code review |
| Claude Code (Anthropic) | Claude Sonnet 4.6 | Used in the legacy client repo (see its own AI_USAGE.md); that code was the input ported into this repo |

---

## Usage Log

### Entry 001 — Repository restructure to MVVM + Clean Architecture

**Task:** Port the working legacy client (functional game, misplaced architecture) into a new repository with correct layering, without changing behavior or visual design.

**Prompt (paraphrase):** "Audit the legacy repo first (read-only source of truth). Create the new repo and restructure everything into domain / application / infrastructure / presentation{views, view_models} / config. Move and adapt, do not rewrite. domain/ and application/ must be pure Dart. Verify with dart analyze and by running the app."

**Result obtained:** Full `lib/` tree in MVVM + Clean layers; imports fixed; app compiles and behaves identically. File-by-file map "old location → new layer" produced during the audit and applied.

**Team modifications:** Branch/commit strategy and the layer boundaries were decided by the team; the AI executed the moves and fixed imports.

**Lessons learned:** Auditing before moving avoided breaking the board hit-test logic that was easy to misplace between view and view model.

### Entry 002 — Level contract and backend LevelDto support

**Task:** Keep the level schema `{ cells, arrows:[{id,path,color}], lives }` as the untouchable contract with the backend; support the backend envelope (`data`) without altering it.

**Prompt (paraphrase):** "The contract must not change. Add `LevelDefinition.fromBackendJson` that unwraps `{ id, name, difficulty, parMoves, data:{cells,arrows,lives} }`."

**Result obtained:** `fromJson` (flat assets) + `fromBackendJson` (backend DTO) parsing the exact same contract; round-trip `toJson`.

**Team modifications:** None beyond naming.

### Entry 003 — apiClient (port + HTTP adapter)

**Task:** Implement `/auth`, `/progress` (JWT), `/leaderboard/:levelId`, `/levels` per docs/backend-context.md.

**Prompt (paraphrase):** "Port `IApiClient` in application, adapter `HttpApiClient` in infrastructure (DIP). Unwrap the `{success,data,message}` envelope, normalize `user.id` vs `user.userId`, map 401/404/409/422/500 to typed errors, store and attach the Bearer token."

**Result obtained:** `IApiClient`, `HttpApiClient`, `ITokenStorage` + SharedPreferences adapter, sealed `ApiError` hierarchy, auth/leaderboard/progress use-case stubs for the auth/leaderboard feature branches.

**Team modifications:** Error taxonomy (which HTTP codes map to which app errors) reviewed against the backend docs by the team.

### Entry 004 — Three-level testing architecture

**Task:** Apply the mandatory course testing architecture (docs/testing-architecture.md) with full unit coverage.

**Prompt (paraphrase):** "Object Mothers, chainable Testing APIs (given/when/then) hiding mocks and fakes, in-memory fakes for every port, mocktail only where interaction is the observable behavior. AAA, names `should_[outcome]_when_[condition]`, coverage for every VO, entity, aggregate, domain service and application service."

**Result obtained:** `test/_support/{mothers,apis,fakes,solvers}` plus one test file per unit; legacy tests rewritten onto the new architecture; 169 tests as of 2026-07-13 (`flutter test`), all passing.

**Team modifications:** The team defined which interactions count as "observable behavior" (apiClient calls, logger decorator) and kept everything else state-based.

**Lessons learned:** The Testing API layer paid off immediately: when `GameViewModel` later gained a constructor dependency, only the support layer changed.

### Entry 005 — CI pipeline

**Task:** Mirror the backend GitHub Actions pipeline for Flutter.

**Prompt (paraphrase):** "Same triggers (push main/develop/feature/**, PR main/develop), concurrency cancelling stale runs, steps install (strict lockfile) → analyze → test → build."

**Result obtained:** `.github/workflows/ci.yml` with `flutter pub get --enforce-lockfile`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build web --release`, pinned Flutter 3.44.2. All steps validated locally before committing.

### Entry 006 — feature/levels-gameplay: 15 campaign levels + progression

**Task:** Design 15 hand-crafted levels with progressive difficulty and varied board shapes; level-select screen with locked levels; victory screen with score, stars and next level; local progress persistence.

**Prompt (paraphrase):** "Levels are data under the backend contract (level creation/persistence belongs to the backend; assets are the bundled campaign). Design 15 solvable levels with rising difficulty (blocking-chain depth, board shapes, lives, time limits) and PROVE solvability with a test. Add locked/unlocked/completed progression driven by local progress, and score/stars on the victory overlay. Everything through MVVM + Clean (use cases: GetLevelSelection, CompleteLevel)."

**Result obtained:**
- `assets/levels/level_1..level_14.json` + `level_heart` as finale (squares, diamond, L, ring, T, plus, heart shapes); difficulty easy→medium→hard, deeper blocking chains and time limits in hard levels.
- `GreedyBoardSolver` test helper + `campaign_levels_test.dart` proving every level is buildable and solvable and difficulty is monotonic.
- `GetLevelSelectionUseCase` (gating rule), `CompleteLevelUseCase` (score via `ScoreCalculator`, stars vs. theoretical max, best-score persistence), `LevelSelectViewModel`, rebuilt level-select screen (grid with locks/stars), campaign queue + "next level" in `GameViewModel`/victory overlay.

**Team modifications:** Difficulty curve parameters (lives per tier, time limits, par moves) tuned by the team; visual style kept identical to the legacy design.

**Lessons learned:** Hand-designed puzzle data is code: without the solvability test, one wrong cell coordinate silently produces an unwinnable level. Encoding the invariant as a test caught design mistakes during iteration.

### Entry 007 — feature/audio-assets: background music and SFX

**Task:** Fill the audio asset paths `audio_service.dart` already expected but that only had `.gitkeep` placeholders (`assets/audio/background.{mp3,wav}`, `assets/audio/sfx/{arrow_escaped,button_tap,game_over,level_cleared,move_blocked}.wav`), per `docs/DEVELOPMENT_PLAN.md`'s `feature/audio-assets` item.

**Prompt (paraphrase):** Requested in an earlier session (exact prompt not recoverable from this session); the ask was to produce a background loop and 5 SFX matching the paths `AudioService` already referenced.

**Result obtained:** 6 procedurally-generated PCM WAV files (44.1kHz mono), not sourced from an external sample library — verified in this session by inspecting the raw waveforms: each SFX has a real attack/decay envelope rather than a flat tone, with pitch chosen to match its semantic role (bright ~809Hz ping for `arrow_escaped`, low ~171Hz thud for `move_blocked`, somber ~345Hz tone for `game_over`, a repeating two-note ~668Hz fanfare shape for `level_cleared`, short ~943Hz click for `button_tap`); `background.wav` is a 24s loop with varying dynamics (~110Hz base), not a static drone. Since the audio is self-synthesized rather than a third-party sample, there is no external license to attribute.

**Team modifications:** None; wiring (`_musicPath` updated from `.mp3` to `.wav` to match the actual generated file) done in this session, files staged and committed on `feature/audio-assets`.

**Lessons learned:** Because this entry's generating session wasn't captured live, the original prompt couldn't be quoted verbatim — a reminder to log AI_USAGE entries in the same session the artifact is produced, not retroactively. Verifying "AI-generated" claims by actually inspecting the artifact (waveform envelope/frequency here) rather than trusting a label is what caught a wrong initial assumption in this session (assumed "placeholder beeps" from file duration alone; waveform analysis showed real envelope/pitch design instead).

### Entry 008 — feature/pattern-hardening: fix mislabeled design patterns in code comments

**Task:** Harden the "Design Patterns" rubric criterion for the oral defense by making every pattern claim in code comments match what the code actually does (per `docs/DEVELOPMENT_PLAN.md`, section B). The repo already has 8 solid, defensible GoF patterns; the goal was to remove three mislabels that a professor reading the code closely could exploit — no new patterns invented, no functional behavior changed.

**Prompt (paraphrase):** "Rename/relabel `CompositeLevelRepository`/`CompositeLevelCatalogService` (they're really Chain of Responsibility, not Composite); change the `domain_events.dart` 'Observer pattern' comment to 'Domain Events pattern (DDD)' since it's pull-based (`Board.pullEvents()`), not GoF Observer; make sure the Riverpod StateNotifier comments don't also mislabel Observer (Riverpod IS the real Observer). Optionally soften the fake 'State pattern' comment on the `GameStatus` enum — but don't force a fake State hierarchy. Keep all 169 tests green and `flutter analyze` clean of new issues."

**Result obtained:**
- Renamed `CompositeLevelRepository` → `ChainedLevelRepository` (file `composite_level_repository.dart` → `chained_level_repository.dart`) and updated the import/usage in `lib/config/providers.dart`. Its `loadLevel` tries each source in order and stops at the first success — genuine Chain of Responsibility; the class doc comment already said so, only the name was wrong.
- `lib/domain/events/domain_events.dart`: replaced the "Observer pattern" comment with "patrón Domain Events (DDD)" and an explicit note that it is a *pull* mechanism (`pullEvents()`), not GoF Observer.
- `lib/presentation/view_models/game_view_model.dart`: kept the accurate "Observer pattern" label on the `StateNotifier` class (Riverpod IS the real Observer — screens `ref.watch` it), but relabeled the two inner comments that were calling the pull-based DomainEvents consumption "Observer" to "Domain Events (pull)".
- `lib/domain/game_status.dart`: softened the misleading "Sirve de base al patrón State" comment to state plainly that it is a simple enum, not GoF State, and that the team deliberately chose not to force an artificial hierarchy (documented decision).

**Team modifications / decisions:**
- **Deliberate deviation from the plan on the catalog service:** `docs/DEVELOPMENT_PLAN.md` lumps `CompositeLevelCatalogService` with the repository as "Chain of Responsibility". But its `getLevels()` aggregates *all* sources (`Future.wait` + flatten) and treats N catalogs as one — that is genuinely the **Composite** pattern, and its comment already labels it correctly. Renaming it to CoR would have introduced a *new* mislabel and violated the definition of done ("every pattern claim matches the code"), so it was left as Composite. Net effect: the repo actually has a real Composite pattern too, alongside the corrected Chain of Responsibility.
- **State hierarchy not implemented** (chose the low-risk option the plan explicitly recommended): no `GameStateBehavior`/`PlayingBehavior`/... hierarchy was added, so no new tests were needed. The enum comment was corrected instead.

**Result verification:** `flutter analyze --no-fatal-infos` → 0 new issues (the 39 remaining are pre-existing `info`-level lints). `flutter test` → 169/169 passing. No test behavior changed; the rename touched no test file (no test referenced the renamed class).

**Lessons learned:** "Mislabeled pattern" is not always "wrong pattern in the wrong place" — sometimes only the *name* is wrong while the doc comment is already right (the repository), and sometimes the audit doc itself over-generalizes and the code is actually correct (the catalog was real Composite). Verifying each claim against the concrete method body — fallback-until-success vs. aggregate-all — was what separated the two, and following the audit blindly would have swapped one mislabel for another.

### Entry 009 — feature/settings-i18n: settings screen + real i18n (ES/EN)

**Task:** Add a settings screen reachable from Home (mute toggle + language selector) and bootstrap real localization so the whole app is playable in Spanish and English. Satisfies rubric criteria 5.1.1 ("access to settings") and 5.1.10 ("support for at least two languages").

**Prompt (paraphrase):** "New `settings_screen.dart` with a mute toggle (reuse `IAudioService`, do not build a new audio abstraction) and a Spanish/English language selector; add a settings icon on `home_screen.dart` that navigates to it. Stand up real `l10n` infrastructure from scratch (there was zero l10n in the repo): `flutter gen-l10n`, `lib/l10n/app_es.arb` + `app_en.arb`, wire `MaterialApp(localizationsDelegates:, supportedLocales:, locale:)` in `main.dart`. Replace the hardcoded UI strings in `home_screen.dart`, `hud_view.dart`, `game_screen.dart` and `level_select_screen.dart` with `AppLocalizations.of(context)!.xxx`. Tests must follow the 3-level testing architecture: a `SettingsScreenTestApi` with an `IAudioService` fake (cases `should_toggle_mute_when_switch_is_tapped`, `should_change_locale_when_language_is_selected`) plus a `home_screen_test.dart` covering navigation to Settings."

**Result obtained:**
- l10n bootstrap: added `flutter_localizations` + `intl` and `generate: true` to `pubspec.yaml`, `l10n.yaml` (arb-dir `lib/l10n`, output committed to `lib/l10n`), and the ARB catalogs `app_en.arb` (template) + `app_es.arb` with 29 messages including two parameterised ones (`victoryScore(score)`, `levelMeta(count, difficulty)`). Generated `AppLocalizations` is committed so CI/tests work without a codegen step.
- `SettingsViewModel`/`SettingsState` (Riverpod `StateNotifier`, MVVM) holding the active `Locale` and the mute flag; `toggleMute()` delegates to the shared `IAudioService`, `setLocale()` drives the UI language. `ArrowMazeApp` is now a `ConsumerWidget` that watches `settingsViewModelProvider.select((s) => s.locale)` and feeds `MaterialApp`.
- New `SettingsScreen` (mute `SwitchListTile` + language rows) reachable from a settings icon on the Home screen; all hardcoded Spanish strings in home/HUD/game/level-select replaced with `AppLocalizations` lookups.
- Tests (3-level): `SettingsScreenTestApi` and `HomeScreenTestApi` wrapping `ProviderScope` + a localized `MaterialApp` harness and hiding the `FakeAudioService`; `settings_screen_test.dart` (mute on/off, locale change, and an assertion that visible text actually relocalizes from "Ajustes" to "Settings") and `home_screen_test.dart` (navigation to Settings). Suite went from 169 to 176 tests, all green; `flutter analyze --no-fatal-infos` added zero new issues (still 39 pre-existing info-level lints).

**Team modifications:** Default language (Spanish, the project's original language) and the exact English wording of the catalog were reviewed by the team; the brand title "Arrow Escape" was intentionally left untranslated.

**Lessons learned:** Two things that were tricky and where the plan was adjusted: (1) `synthetic-package` in `l10n.yaml` is deprecated in Flutter 3.44 and now a no-op — instead of the legacy `package:flutter_gen/...` synthetic import, generation was pointed at `lib/l10n` with `output-dir` and the result committed, which also makes the `AppLocalizations` import unambiguous for tests. (2) `RadioListTile`'s `groupValue`/`onChanged` API is on the deprecation path (Radio → RadioGroup migration), so the language selector was built from plain `ListTile`s with a check indicator to avoid introducing new analyzer warnings. The mute state is intentionally shared through the single `IAudioService` instance rather than duplicated, so the Settings toggle and the in-game HUD toggle act on the same source of truth.

### Entry 010 — feature/game-widget-tests: widget/UI test coverage for home, level select and game screens

**Task:** Add the repo's first `testWidgets` coverage (there was zero widget-test coverage before this branch) for the three core screens — Home, Level Select, Game — closing `docs/DEVELOPMENT_PLAN.md`'s `feature/game-widget-tests` item (rubric §3.5, "Pruebas de Widget/UI"), building on `feature/settings-i18n`'s `HomeScreenTestApi`/`SettingsScreenTestApi` as the reference Testing API style.

**Prompt (paraphrase):** "Read `docs/testing-architecture.md`, the `feature/game-widget-tests` entry in `docs/DEVELOPMENT_PLAN.md`, and the existing `settings_screen_test_api.dart`/`home_screen_test_api.dart` for conventions. `home_screen_test.dart` already exists from `settings-i18n` (covers only navigation to Settings) — extend it, don't duplicate; it must also cover rendering the title/play button and tapping 'JUGAR' navigating to `LevelSelectScreen`. Add `level_select_screen_test.dart` (locked levels not tappable, an unlocked level navigates to `GameScreen`, stars/lock icons render per `LevelSelectViewModel` state) and `game_screen_test.dart` (tapping a removable arrow triggers the remove-arrow flow, victory overlay on `GameStatus.levelCleared`, game-over overlay on `GameStatus.gameOver`), reusing existing fakes in `test/_support/fakes/` and following the 3-level Testing API architecture throughout. At least 1 render + 1 interaction + 1 navigation test per screen. `flutter analyze --no-fatal-infos` clean of new issues; `flutter test` fully green, growing the suite from 176."

**Result obtained:**
- Extended `HomeScreenTestApi`/`home_screen_test.dart` with a render test (title + "JUGAR" button visible) and a play-button navigation test (`whenThePlayButtonIsTapped` → `LevelSelectScreen`). Added a stable `HomeScreen.playButtonKey`. Overrode `levelCatalogServiceProvider`/`playerProgressRepositoryProvider` with empty fakes in the harness so `LevelSelectScreen` (the navigation target) can open and load without touching real assets/SharedPreferences.
- New `LevelSelectScreenTestApi` + `level_select_screen_test.dart`: render tests for the lock icon on a still-locked campaign level and for filled stars on a completed one; an interaction test asserting a locked tile's `onTap` stays `null` (tapping it leaves `LevelSelectScreen` shown, no navigation); a navigation test for an unlocked tile pushing `GameScreen`. Added `LevelSelectScreen.campaignTileKey(number)` and threaded a `key` through `_CampaignTile` so each grid tile is individually addressable in tests. Wired via the existing `FakeLevelCatalogService` + `FakePlayerProgressRepository`, plus `FakeLevelRepository`/`FakeTimeService` so the downstream navigation to `GameScreen` can actually load a board.
- New `GameScreenTestApi` + `game_screen_test.dart`: a render test for the board; interaction tests for both `tryRemoveArrow` outcomes (escapable arrow removed vs. blocked arrow costing a life), driven by an actual `tester.tap` on `BoardView`'s real `GestureDetector` (found via `find.descendant`) rather than calling `GameViewModel.tapArrow` directly — the interaction under test is the user's tap, not an internal method call, per testing-architecture.md's "state over interaction" rule. Since every `LevelDefinitionMother` board is the same canonical 3×3 grid with `'a1'` occupying cell r1c1, tapping the board's geometric center deterministically hits `'a1'` regardless of level. Overlay tests cover `GameStatus.levelCleared` (victory) and `GameStatus.gameOver` (defeat, via a 1-life blocked-arrow board). Reused the `GameSessionTestApi` pattern (construct a real `GameViewModel` wired to fakes) but exposed it to the widget tree via `gameViewModelProvider.overrideWith((ref) => _viewModel)` instead of driving it headless.
- Suite grew from 176 to 187 tests (11 new), all green; `flutter analyze --no-fatal-infos` stayed at 39 issues (same pre-existing info-level lints, zero new).

**Team modifications:** None on scope. The tap-target strategy (tap the board's geometric center instead of hardcoding pixel offsets against `BoardPainter`'s internals) was a deliberate design choice to keep the test resistant to refactors of the board's rendering/sizing logic, consistent with testing-architecture.md's "must not break on internal refactors" rule.

**Lessons learned:** When a Testing API constructs a `StateNotifier` by hand *and* also hands it to `ProviderScope(overrides: [...overrideWith(...)])`, only one side may own disposal. Riverpod takes ownership of any notifier supplied via `overrideWith` and disposes it automatically when the widget tree unmounts; disposing it again manually in the Testing API's `dispose()` throws `Bad state: Tried to use GameViewModel after 'dispose' was called` — and because Flutter tears down the previous test's element tree lazily, the exception actually surfaced attached to the *next* test's run, which briefly looked like an unrelated failure. Fixed by having `GameScreenTestApi.dispose()` only close the resource it actually owns outright (`FakeTimeService`'s `StreamController`), never the `GameViewModel` handed to `ProviderScope`.

### Entry 012 — feature/progress-sync-integration: port teammate's real backend-connected auth + progress sync onto the current Home/AOP/l10n baseline

**Task:** A teammate (Zarah) built genuine, backend-connected auth (login/register/logout/session-restore) and bidirectional progress sync (`GET`/`PUT /progress`, leaderboard `last*` fields) on her own branch `feature/progress-sync`, cut from an old `develop` commit before real l10n, the redesigned Home screen, and the AOP logging proxy existed. Her branch also independently rewrote `home_screen.dart` (different design: user menu, login entry point), which would conflict badly with the Home screen `develop` has now. Team decision: keep `develop`'s current Home/AOP/l10n untouched, port only her *auth and progress-sync logic*, and add a login/profile entry point to the *existing* Home screen instead of replacing it. Closes (or substantially advances) rubric criterion 7, "Backend y API REST" — this is the first branch in the repo where the app actually authenticates against and exchanges progress with the real backend end-to-end, not just a stubbed `IApiClient` port.

**Prompt (paraphrase):** "Create `feature/progress-sync-integration` off `origin/develop`. Read Zarah's `feature/progress-sync` via `git show`/`git diff` against its merge-base (don't check it out). Port the genuinely-new ports/use-cases/view-model/screens (`i_progress_sync_coordinator`, `i_user_storage`, `session_cleanup`, `restore_session_use_case`, `hydrate_progress_use_case`, `push_progress_use_case`, `progress_sync_coordinator`, `shared_prefs_user_storage`, `auth_state`/`auth_view_model` — replacing the stub — `login_screen`/`register_screen`), merge her intent into files `develop` has since modified (tolerant JSON parsing on the progress DTOs, `userStorage`-aware auth use cases, `clear()`/`replaceAll()` on the progress repository, null-safe best-score comparison in `complete_level_use_case`, a `progressSync` fire-and-forget hook in `game_view_model` — check develop's current version first, `pattern-hardening` touched its comments). Do NOT port `home_screen.dart` wholesale; read her version to understand the logged-in/logged-out UI, then build an equivalent entry point inside develop's current Home layout, keeping `HomeScreen.settingsButtonKey`/`playButtonKey` intact. Fix a known bug: her post-auth progress hydration has no error absorption of its own, so a flaky `GET /progress` right after a valid login reports 'login failed'. Bring her two non-compliant test files (`restore_session_use_case_test.dart`, `auth_view_model_test.dart` — raw mocks/`setUp()` in the test body) into 3-level Testing API compliance. Wire everything in `providers.dart`/`main.dart` without silently dropping the AOP proxy wrapping if `feature/aop-extra-aspects` merged in the meantime. Append an `AI_USAGE.md` entry, commit, don't push."

**Result obtained:**
- **Ported as-is** (new files, no `develop` equivalent): `i_progress_sync_coordinator.dart`, `i_user_storage.dart`, `session_cleanup.dart`, `restore_session_use_case.dart`, `hydrate_progress_use_case.dart`, `push_progress_use_case.dart`, `progress_sync_coordinator.dart`, `progress_mapper.dart`, `shared_prefs_user_storage.dart`, `login_screen.dart`, `register_screen.dart` (both self-contained, kept their original hardcoded Spanish copy — not wired into the app's l10n catalog, since the task scoped them as "port as-is").
- **Adapted / merged** into `develop`'s current versions (both sides had diverged from Zarah's old base): `level_progress.dart`/`player_progress_dto.dart`/`progress_update.dart` (tolerant JSON parsing — numbers-as-strings, missing keys), `login_use_case.dart`/`register_use_case.dart`/`logout_use_case.dart` (now persist/clear `IUserStorage`; logout also clears local progress so it doesn't leak into guest mode), `complete_level_use_case.dart` (null-safe best-score/star comparison — guards against a progress entry hydrated with a default `starsEarned`), `i_player_progress_repository.dart` + `shared_prefs_player_progress_repository.dart` (`clear()`/`replaceAll()` for hydration), `auth_view_model.dart` (replaced the `develop` stub with the real implementation — **plus the bug fix below**), `game_view_model.dart` (added an optional `progressSync` collaborator; `_registerCompletion` now fires `pushCompletedLevel` unawaited after scoring — kept `develop`'s current doc comments from `pattern-hardening` rather than reintroducing Zarah's older wording).
- **Newly written**, not from her branch: the Home screen's account entry point (`_AccountEntryPoint`/`_UserAccountCard` in `home_screen.dart`) — an icon top-left (settings stays top-right, keys untouched) that opens `LoginScreen` when logged out or a small dropdown card (greeting + logout) when authenticated, watching `authViewModelProvider`; four new l10n keys (`accountTooltip`, `loginButton`, `logoutButton`, `accountGreeting`) added to both `app_en.arb`/`app_es.arb` and regenerated via `flutter gen-l10n` so the entry point matches the rest of Home's localized style even though the login/register screens themselves stayed hardcoded-Spanish; Testing APIs `RestoreSessionTestApi` and `AuthViewModelTestApi` (`test/_support/apis/`) to bring `restore_session_use_case_test.dart` and `auth_view_model_test.dart` into 3-level compliance — the tests now only call chainable `given.../when.../then...`, all mocktail/fake wiring lives in the API.
- **Bug fix (verified with a regression test):** `AuthViewModel._syncProgressAfterAuth()` previously called `_progressSync.pullAndApplyLocal()` un-guarded inside the same try/catch as the login/register call, so any non-404 failure (network, 401, 500, malformed JSON) on the post-auth `GET /progress` surfaced as an `AuthState.unauthenticated(errorMessage: ...)` even though the credentials were valid and the token was already saved. Fixed by wrapping the hydration call in its own `try/catch` (broad catch, matching the contract the port's doc comment already promised for `pushCompletedLevel`) so it can never propagate into the auth call's error handling; the doc comment on `IProgressSyncCoordinator.pullAndApplyLocal()` was updated to state this explicitly. Two new tests in `auth_view_model_test.dart` — `should_stay_authenticated_when_post_login_hydration_fails_transiently` and the register equivalent — inject a `NetworkError` from the mocked `IProgressSyncCoordinator` and assert the resulting state is still `AuthStatus.authenticated` with no `errorMessage`; both pass against the fix and would fail against Zarah's original code.
- **AOP proxy check:** `feature/aop-extra-aspects` (ExceptionHandlingApiClientProxy / CachingUseCaseProxy) was still unmerged into `origin/develop` as of this branch — only `UseCaseLoggerProxy` (wrapping `removeArrowUseCaseProvider`) exists today. `apiClientProvider`/`getLeaderboardUseCaseProvider` were left as plain providers; a comment block was added directly above them in `providers.dart` flagging that the wrapping must be verified explicitly if/when that branch merges, referencing this exact class of bug having happened twice before in this repo.
- Test-support additions ported as-is: `hydrate_progress_test_api.dart`, `push_progress_test_api.dart`, `fake_user_storage.dart`; `auth_test_api.dart`, `complete_level_test_api.dart`, and `fake_player_progress_repository.dart` were extended in place (not duplicated) to cover the new `userStorage`/`clear()`/`replaceAll()` surface. Suite grew from 187 to 211 tests (24 new: 3 restore-session + 8 auth-view-model + 4 progress-mapper + 2 hydrate + 4 push + 1 logout + 2 complete-level), all green. `flutter analyze --no-fatal-infos` went from 39 to 58 issues — the +19 are all `prefer_initializing_formals` info-lints on the new/ported constructors, the exact same pattern already present in ~30 of the baseline's 39 issues (public named param, e.g. `api:`, backing a private field, e.g. `_api`) — this is this codebase's established DI-port convention, not new sloppiness; the two genuinely free/zero-risk instances (in `auth_state.dart`'s named constructors, where the formal parameter name already matched the field name) were fixed for real. No errors or warnings, in baseline or now.

**Team modifications:** None yet — pending review of this branch before merge to `develop`. Two intentional deviations from a literal wholesale port worth calling out: (1) `home_screen.dart` was *not* replaced, per the explicit team decision; the account entry point is new code inspired by Zarah's logged-in/logged-out UI, not a copy of it. (2) The project owner separately reviewed Zarah's other branch (`feature/auth-ui`, which deletes `http_api_client.dart`/`shared_prefs_token_storage.dart` for a Dio-based client) and rejected it as conflicting with the AOP proxies and everything else on `develop`; nothing from that branch was consulted or ported here.

**Lessons learned:** Widening `gameViewModelProvider`'s and (via `HomeScreen`) `authViewModelProvider`'s real dependency graph to reach `sharedPreferencesProvider` broke two *existing* widget-test Testing APIs that had never needed to override it before (`home_screen_test_api.dart`, and — less obviously — `level_select_screen_test_api.dart`, whose "tap an unlocked tile" test navigates into `GameScreen` and so also touches the real `gameViewModelProvider`). Both were fixed by overriding `sharedPreferencesProvider` with `SharedPreferences.setMockInitialValues({})` rather than mocking every provider in the new auth/progress chain individually — since there's no stored token, `RestoreSessionUseCase` resolves to "no session" without ever reaching the network, so the override is enough to let the whole real provider graph construct safely in a widget test. The lesson: adding an optional collaborator to a shared, deeply-referenced provider (here, `IProgressSyncCoordinator` on `gameViewModelProvider`) has a wider test blast radius than the screen you're actually changing — worth grepping every `home:` widget pumped directly (not through an `overrideWith` of the provider itself) before declaring a change "isolated" to one screen.

---

## Critical Evaluation

- **Approximate share of AI-assisted code:** ~85% of the lines in this repository were written with AI assistance, under team-defined architecture, contracts and review. All AI-generated code is covered by the test suite.
- **Incorrect/suboptimal AI output and how it was caught:**
  - An early level draft contained a circular blocking dependency (unsolvable). Caught by the solvability test, then redesigned.
  - A `chore` commit was accidentally created on `develop` with a machine-specific `android/local.properties`; caught on review of the remote history and fixed by rewriting `develop`.
  - Initial CI draft failed on `flutter analyze` due to pre-existing info-level lints; fixed with `--no-fatal-infos` after verifying no errors/warnings were masked.
- **Reflection:** AI sped up the mechanical parts (restructuring, test scaffolding, JSON authoring) by an order of magnitude, letting the team spend its time on the decisions that matter: layer boundaries, the level contract, the testing methodology and the difficulty curve. The discipline that made it safe was (1) the read-only audit of the legacy repo before touching anything, (2) tests as the acceptance gate for every AI-produced artifact, and (3) granular Conventional Commits so each AI contribution is traceable.
