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

---

## Critical Evaluation

- **Approximate share of AI-assisted code:** ~85% of the lines in this repository were written with AI assistance, under team-defined architecture, contracts and review. All AI-generated code is covered by the test suite.
- **Incorrect/suboptimal AI output and how it was caught:**
  - An early level draft contained a circular blocking dependency (unsolvable). Caught by the solvability test, then redesigned.
  - A `chore` commit was accidentally created on `develop` with a machine-specific `android/local.properties`; caught on review of the remote history and fixed by rewriting `develop`.
  - Initial CI draft failed on `flutter analyze` due to pre-existing info-level lints; fixed with `--no-fatal-infos` after verifying no errors/warnings were masked.
- **Reflection:** AI sped up the mechanical parts (restructuring, test scaffolding, JSON authoring) by an order of magnitude, letting the team spend its time on the decisions that matter: layer boundaries, the level contract, the testing methodology and the difficulty curve. The discipline that made it safe was (1) the read-only audit of the legacy repo before touching anything, (2) tests as the acceptance gate for every AI-produced artifact, and (3) granular Conventional Commits so each AI contribution is traceable.
