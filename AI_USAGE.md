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

---

## Critical Evaluation

- **Approximate share of AI-assisted code:** ~85% of the lines in this repository were written with AI assistance, under team-defined architecture, contracts and review. All AI-generated code is covered by the test suite.
- **Incorrect/suboptimal AI output and how it was caught:**
  - An early level draft contained a circular blocking dependency (unsolvable). Caught by the solvability test, then redesigned.
  - A `chore` commit was accidentally created on `develop` with a machine-specific `android/local.properties`; caught on review of the remote history and fixed by rewriting `develop`.
  - Initial CI draft failed on `flutter analyze` due to pre-existing info-level lints; fixed with `--no-fatal-infos` after verifying no errors/warnings were masked.
- **Reflection:** AI sped up the mechanical parts (restructuring, test scaffolding, JSON authoring) by an order of magnitude, letting the team spend its time on the decisions that matter: layer boundaries, the level contract, the testing methodology and the difficulty curve. The discipline that made it safe was (1) the read-only audit of the legacy repo before touching anything, (2) tests as the acceptance gate for every AI-produced artifact, and (3) granular Conventional Commits so each AI contribution is traceable.
