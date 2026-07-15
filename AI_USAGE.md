# AI Usage Documentation

**Repository:** ucab-arrowmaze-mobile — Arrow Maze Escape Puzzle (Flutter client)
**Course:** Desarrollo de Software NRC 25783
**Last updated:** 2026-07-14

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

### Entry 011 — feature/aop-extra-aspects: two more AOP aspects (exceptions + caching)

**Task:** Raise the AOP criterion (rubric #5) from 1 aspect to 3 by adding two more proxies alongside the existing `UseCaseLoggerProxy`, all following the same Proxy pattern (transparent substitution), per `docs/DEVELOPMENT_PLAN.md` §C `feature/aop-extra-aspects`. Aspect A: centralized exception handling for network calls. Aspect B: TTL cache for the leaderboard. Both wired through Riverpod and covered by interaction-based (mocktail) tests — the one place `docs/testing-architecture.md` §5 explicitly sanctions mocks, because for a decorator the interaction (was the wrapped call made? retried? skipped on a cache hit?) IS the observable behavior.

**Prompt (paraphrase):** "On a branch cut from `origin/develop`, add `exception_handling_proxy.dart` (map network failures to the existing typed `ApiError` taxonomy uniformly, with simple retry if low-risk) and `caching_use_case_proxy.dart` wrapping `GetLeaderboardUseCase` with time-based invalidation. Match `use_case_logger_proxy.dart`'s shape exactly, wire both into `providers.dart` (`apiClientProvider`, `getLeaderboardUseCaseProvider`), and write mocktail interaction tests following the 3-level Testing-API convention. Keep `flutter analyze` clean of new issues and `flutter test` green."

**Result obtained:**
- `lib/application/proxies/exception_handling_proxy.dart` — `ExceptionHandlingApiClientProxy implements IApiClient`, wrapping `HttpApiClient` transparently in `apiClientProvider`. A single `_guard<T>()` helper normalizes every one of the port's 8 methods: already-typed `ApiError`s propagate untouched; any unexpected transport exception is mapped uniformly to the existing typed `NetworkError`; transient `NetworkError`s are retried up to `maxAttempts` (default 2) with an injectable `retryDelay`.
- `lib/application/proxies/caching_use_case_proxy.dart` — `CachingUseCaseProxy implements GetLeaderboardUseCase` (Dart lets a concrete class be used as an interface), memoizing results per `(levelId, limit)` for a TTL (default 30s) with an injectable clock. Wired into `getLeaderboardUseCaseProvider`.
- Tests (3-level, interaction-based): `ExceptionHandlingProxyTestApi` + `CachingProxyTestApi` in `test/_support/apis/` hide the mocktail mocks and the injected clock; thin specs in `test/application/proxies/` (`should_return_cached_result_when_called_twice_within_ttl`, `should_call_the_wrapped_use_case_again_when_ttl_expires`, `should_map_network_error_to_typed_api_error_when_request_fails`, `should_retry_and_succeed_when_first_attempt_hits_a_transient_network_error`, `should_stop_retrying_and_throw_when_network_error_persists`, etc.). Suite went from 176 to 184 tests, all green; `flutter analyze --no-fatal-infos` stayed at the pre-existing 39 info-level issues (0 new).

**Team modifications / decisions:**
- **Exception aspect scoped at the port, not by gutting `HttpApiClient`.** The plan floated "extract the dispersed error mapping out of `http_api_client.dart`", but that mapping (HTTP status → `ApiError`) is well-tested there and removing it would be a risky refactor that breaks `http_api_client_test.dart`. Instead the proxy sits *in front of* `IApiClient` as a genuine transparent Proxy (same molde as the logger), complementing the adapter: it catches whatever the adapter doesn't already type (e.g. `TimeoutException`) and adds the cross-cutting retry the adapter lacks. This keeps the aspect additive and low-risk.
- **Retries: kept, but only for transient `NetworkError`.** Deterministic API errors (401/404/409/422/500) are never retried — re-issuing them is pointless and would mask real failures. Retry applies uniformly across methods including non-idempotent POSTs (register/login); this is acceptable because a `NetworkError` originates from an `http.ClientException` (transport failure, the request generally never completed a round-trip), and a duplicate register would surface as a deterministic `409 ConflictError` rather than silent corruption. Default is 2 attempts (one retry) with a 300ms delay, both injectable so tests run instantly with `retryDelay: Duration.zero`.
- **Caching proxy implements the concrete `GetLeaderboardUseCase` as an interface** rather than introducing a new `IGetLeaderboardUseCase`. This keeps `getLeaderboardUseCaseProvider`'s type unchanged and, importantly, avoids editing `get_leaderboard_use_case.dart`, which is owned by the parallel `feature/leaderboard-ui` branch — no merge-conflict surface.
- **One suppressed lint, documented in-file.** Both proxies (like `UseCaseLoggerProxy`) use named `required` params with private fields, which trips `prefer_initializing_formals`. That lint is unsatisfiable here: Dart forbids private *named* parameters (`{required this._delegate}` is a compile error), so `// ignore_for_file: prefer_initializing_formals` was added with an explanatory comment rather than abandoning the repo's named-argument convention. Net analyze diff vs. `develop`: 0 new issues.

**Lessons learned:** "Extract the error mapping" read as a refactor, but the higher-value, lower-risk move was to *add* a cross-cutting layer around the port instead of relocating tested logic out of the adapter — the aspect is defined by what it adds (uniform normalization of untyped failures + retry), not by moving code around. Also: implementing a concrete class as a Dart interface is the clean way to insert a transparent proxy without forcing an interface-extraction change onto a file another teammate owns.

---

## Critical Evaluation

- **Approximate share of AI-assisted code:** ~85% of the lines in this repository were written with AI assistance, under team-defined architecture, contracts and review. All AI-generated code is covered by the test suite.
- **Incorrect/suboptimal AI output and how it was caught:**
  - An early level draft contained a circular blocking dependency (unsolvable). Caught by the solvability test, then redesigned.
  - A `chore` commit was accidentally created on `develop` with a machine-specific `android/local.properties`; caught on review of the remote history and fixed by rewriting `develop`.
  - Initial CI draft failed on `flutter analyze` due to pre-existing info-level lints; fixed with `--no-fatal-infos` after verifying no errors/warnings were masked.
- **Reflection:** AI sped up the mechanical parts (restructuring, test scaffolding, JSON authoring) by an order of magnitude, letting the team spend its time on the decisions that matter: layer boundaries, the level contract, the testing methodology and the difficulty curve. The discipline that made it safe was (1) the read-only audit of the legacy repo before touching anything, (2) tests as the acceptance gate for every AI-produced artifact, and (3) granular Conventional Commits so each AI contribution is traceable.
