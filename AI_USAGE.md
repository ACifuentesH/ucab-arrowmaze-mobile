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

**Result obtained:** `test/_support/{mothers,apis,fakes,solvers}` plus one test file per unit; legacy tests rewritten onto the new architecture; 135+ tests.

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

### Entry 007 — feature/pattern-hardening: fix mislabeled design patterns in code comments

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

---

## Critical Evaluation

- **Approximate share of AI-assisted code:** ~85% of the lines in this repository were written with AI assistance, under team-defined architecture, contracts and review. All AI-generated code is covered by the test suite.
- **Incorrect/suboptimal AI output and how it was caught:**
  - An early level draft contained a circular blocking dependency (unsolvable). Caught by the solvability test, then redesigned.
  - A `chore` commit was accidentally created on `develop` with a machine-specific `android/local.properties`; caught on review of the remote history and fixed by rewriting `develop`.
  - Initial CI draft failed on `flutter analyze` due to pre-existing info-level lints; fixed with `--no-fatal-infos` after verifying no errors/warnings were masked.
- **Reflection:** AI sped up the mechanical parts (restructuring, test scaffolding, JSON authoring) by an order of magnitude, letting the team spend its time on the decisions that matter: layer boundaries, the level contract, the testing methodology and the difficulty curve. The discipline that made it safe was (1) the read-only audit of the legacy repo before touching anything, (2) tests as the acceptance gate for every AI-produced artifact, and (3) granular Conventional Commits so each AI contribution is traceable.
