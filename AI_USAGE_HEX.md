# AI Usage — Hexagonal Mode (feature-specific log)

**Repository:** ucab-arrowmaze-mobile — Arrow Maze Escape Puzzle (Flutter client)
**Feature:** Hexagonal Mode (design doc: `docs/HEX_MODE_PLAN.md`)
**Relation to `AI_USAGE.md`:** this file is the detailed, feature-specific log for
the hexagonal mode. Each branch listed here still appends its own numbered
entry to the repo-wide `AI_USAGE.md` (graded rubric item); this document adds
the orchestration methodology and the per-phase detail that doesn't fit there.
**Status:** all four implementation phases (hex-core, hex-board-rendering,
hex-levels-catalog, hex-mode-ui) are complete, tested and manually played
end-to-end in a real Chrome build. `feature/hex-core` (PR #21),
`feature/hex-board-rendering` (PR #23) and `feature/hex-levels-catalog`
(PR #24) are merged into `develop`. `feature/hex-mode-ui` — three hand-designed
levels (Panal, Colmena, Enjambre), the campaign-trail selection screen and the
post-playtest fixes below — is ready for its own PR into `develop`.
**Last updated:** 2026-07-18

---

## Methodology: multi-agent orchestration

| Role | Agent | Scope |
|---|---|---|
| Orchestrator | Claude Code (Claude Fable 5), interactive session | Audits, design doc, branch cutting, subagent prompting, merge/integration, human-checkpoint management |
| Implementers | Claude Opus subagents, one per feature branch, each in an **isolated git worktree** | Write code + tests for exactly one branch, prompted with the literal Alcance / Pruebas exigidas / Definición de HECHO block from `docs/HEX_MODE_PLAN.md` §5 |
| Reviewers / auditors | Read-only subagents (Explore / general-purpose) | Audit teammates' branches, verify backend assumptions, review diffs before PR |

**Rules of engagement (agreed 2026-07-13, applied here):**

1. Phase 1 (`feature/hex-core`) is sequential — everything depends on it; no
   parallel agents until it merges to `develop`.
2. Phases 2A (`feature/hex-board-rendering`) and 2B
   (`feature/hex-levels-catalog`) run as **two parallel Opus worktree
   subagents** — they share no files by design.
3. Phase 3 (`feature/hex-mode-ui`) is sequential again (integrates 2A+2B and
   touches the contended `LevelSelectScreen`).
4. **A human confirms every push and every PR** — no batched approvals.
5. Before any push: rebase/merge `develop` into the branch and resolve
   `AI_USAGE.md` entry-numbering collisions (known recurring friction).
6. Gitflow: every branch cut from `develop`, every PR targets `develop`.
7. **Running the built app in a real browser is a required step, not
   optional QA** — every defect found in H-007 (an unwanted interior hole, a
   marker/progress-bar collision, an off-center dashed line) was invisible to
   `flutter analyze`/`flutter test` and only surfaced once a human actually
   played the build. 337 green tests caught zero of them.
8. **Transient agent failure vs. human stop are handled differently.**
   Three sessions died mid-task from causes with nothing to do with the code
   (API `ConnectionRefused` during hex-core; a session-limit reset at the
   start of the hex_3 request) — both were safely resumed with `SendMessage`
   using the *same* agent id, picked back up with full context, and finished
   the original scope. A fourth session was explicitly **stopped by the
   human** mid hex_3-regeneration (not a failure — a deliberate interrupt to
   redirect); that one could not be resumed (`SendMessage` returned "won't be
   resumed... only launch a new agent if the user explicitly asks"). When the
   human then asked to finish that same work, the orchestrator did NOT spawn
   a fresh subagent to re-derive the whole context — see H-007 for why and
   how.
9. **Isolated worktree ≠ isolated scratchpad.** Each implementer subagent
   gets its own git worktree, but subagents and the orchestrator share the
   same OS-level scratchpad temp directory for the session. When the
   hex_3-regeneration subagent was stopped mid-task, its auxiliary Dart
   generator script (`gen_hex3.dart`) was still sitting in that shared
   scratchpad — the orchestrator read it and reran it directly instead of
   asking a new agent to reconstruct the inverse-construction algorithm from
   the design doc.
10. **PR authorship split between the orchestrator and the human**, and both
    are legitimate. The orchestrator opened PRs #21 (hex-core), #22
    (hex-mode-plan docs) and #25 (hex-mode-ui) via the GitHub REST API
    (`gh` CLI is not installed in this environment; worked around with the
    token from `git credential fill` + `curl`, writing the JSON body to a
    file — an inline shell-escaped `--data` string returned HTTP 400
    "Problems parsing JSON" on the first attempt). PRs #23 (hex-board-
    rendering) and #24 (hex-levels-catalog) were pushed by the orchestrator
    *without* a PR at the human's explicit choice ("solo push, sin PRs"),
    and the human then opened and merged both directly on GitHub, on their
    own timeline, while the orchestrator was mid-task on something else. The
    orchestrator only found out via `git fetch` (see H-006) — this is normal,
    not a synchronization failure: the human is a full participant in the
    same gitflow, not just an approval gate.
11. **A local integration branch is disposable QA scaffolding, never a
    substitute for the real merge.** Before Phase 3 existed (no UI entry
    point yet), the orchestrator merged the three Phase-1/2 branches into a
    throwaway local `preview/hex-integration` branch purely to sanity-check
    that they combined cleanly — and hit the exact `AI_USAGE.md`
    entry-numbering collision rule 5 warns about (see H-006). The moment the
    human's real GitHub merges landed on `origin/develop`, that local branch
    and its own conflict resolution were discarded outright — the human's
    merge order is the one that counts, not whatever the orchestrator
    resolved locally first.
12. **Known environment constraints in this project (not generic Flutter
    facts — specific to this machine/harness):**
    - `flutter run -d windows` fails with *"Building with plugins requires
      symlink support"* — Windows desktop builds are not usable here; all
      live QA in this project ran with `flutter run -d chrome` instead.
    - There is no way to send interactive stdin (the `r` hot-reload
      keystroke) to a `flutter run` process launched in the background — a
      source change during a live session requires killing and relaunching
      the whole process, not a reload.

---

## Usage Log

### Entry H-000 — Audit of the board-graph pipeline and hexagonal mode design

**Task:** Before writing any code, audit how the board graph is built end-to-end
(JSON → `LevelDefinition` → `LevelBuilder` → `ITopologyStrategy` →
`AdjacencyBoardGraph` → `Board`), including the rendering layer and the
backend contract, and produce the full design + subagent orchestration plan
for the hexagonal mode.

**Prompt (paraphrase):** "Pull latest main. Audit the current state of every
class involved in graph creation so the node can become a hexagon (arrow can
exit through 6 directions). Document interfaces and class names before
development. Plan a subagent methodology — and evaluate whether it actually
makes sense. Include the backend in the audit. Entry point: a 'Hexagonal
Mode' button below the creative-mode button, opening a window with a 2-level
campaign (one easy, one very complex). Keep a feature-specific AI-usage doc."

**Result obtained:** `docs/HEX_MODE_PLAN.md` — full audit (which classes are
shape-agnostic vs square-coupled), the design decisions (odd-r offset
coordinates preserving the `cells:[[r,c]]` backend contract; 6-direction
encoding table; `TopologyKind` enum; `HexGridTopology`, `HexArrowFactory`,
`IBoardGeometry`/`HexBoardGeometry`, `HexLevelSelectScreen`, hex catalog and
use case), a greedy-solver-based solvability test strategy for the two
handcrafted levels, the 4-branch phased plan with per-branch scope/tests/DoD,
and the verdict on the subagent methodology (parallelism only pays in Phase
2; Phases 1 and 3 stay sequential). Backend audit conclusion: zero backend
changes needed for v1 — `LevelData` is an opaque blob and progress sync does
not validate level ids; the only caveat (backend strips unknown `data` keys
such as `topology`) is documented as a future-work item.

**Team modifications:** (pending review of the plan by the team before
Phase 1 starts).

**Lessons learned:** The domain was already designed for this — `Direction`
is index-within-total and `ITopologyStrategy` is the prepared seam — so the
real coupling to squares lives in exactly four places (`ArrowFactory`,
`LevelBuilder._validate`, `ProceduralArrowPlacer`, `BoardPainter`/`BoardView`).
Auditing first turned "rewrite the board" into "add two domain classes, one
presentation abstraction, and content".

### Entry H-001 — feature/hex-core: hexagonal topology in domain + application

**Task:** Lay the shape-agnostic core of the hexagonal mode with zero UI changes.
**Prompt (paraphrase):** the §5 Phase-1 block — `TopologyKind` VO, `HexGridTopology` (odd-r, 6 neighbours per row parity), `HexArrowFactory` (total=6), propagate `topologyKind` to `Board`/`LevelDefinition`/`LevelPreview`, and make `LevelBuilder` auto-select topology+factory and validate adjacency against the built graph instead of hardcoded manhattan arithmetic.
**Result obtained:** all of the above, with `TopologyKind.parse('hex')` defaulting to square for byte-identical back-compat; adjacency validation now asks the graph, killing the last square-only geometry leak. 30 new tests; suite 291/291; analyze at the 69-issue baseline (zero new); the 15 campaign levels still build.
**Team modifications:** none — orchestrator reviewed the full diff (neighbour table, `LevelBuilder` selection/validation, `Board`/`LevelDefinition` propagation) before approving the push; merged as-is via PR #21.
**Lessons learned:** the prior investment in `Direction` (index/total), `ITopologyStrategy` and `IArrowFactory` paid off exactly as designed — hex entered without touching a single game rule or existing test; the only hidden square-coupled code was the builder's manhattan check.

### Entry H-002 — feature/hex-board-rendering: abstract board geometry + hex render

**Task:** Extract ALL pixel math from `BoardPainter`/`BoardView` into an `IBoardGeometry` abstraction and implement the hex geometry, without changing one pixel of the square render (Phase 2A).
**Prompt (paraphrase):** the §5 Phase-2A block — `IBoardGeometry` (cellScaleFor, boardSize, cellCenter, cellOutline, unit directionVector, stepDistance, hitTest), a `SquareBoardGeometry` reproducing today's behaviour 1:1, and a pointy-top odd-r `HexBoardGeometry` with Voronoi hit-test reusing `HexGridTopology.neighborOffset`; painter/view delegate geometry by `board.topologyKind`.
**Result obtained:** `board_geometry.dart` + `hex_board_geometry.dart`; painter and view refactored to delegate; 20 new tests (hand-derived square regression constants for pixel-identity, hex properties, real `BoardView` hex widget test). Suite 311/311; analyze 69 issues (zero new).
**Team modifications:** none — orchestrator reviewed `hex_board_geometry.dart` in full and the `board_view.dart` diff before approving the push; merged as-is via PR #23.
**Lessons learned:** the square render secretly had two coupled scale formulas (painter `size.width/cols` vs view `min(w/cols,h/rows)`); `cellScaleFor(boardSize)` recovers the exact scale in both topologies and the "reserved size and scale are inverse" roundtrip is the property that makes the refactor pixel-neutral. Hit-test reuses the graph's neighbour table so pixel and graph geometry share one source of truth.

### Entry H-003 — feature/hex-levels-catalog: catalog, progression and two playable hex levels

**Task:** On top of the hex core, add content and an ISOLATED selection pipeline: two hand-designed levels (`hex_1` easy, `hex_2` hard), a dedicated asset catalog, a sequential-unlock use case and its view model, no screen (Phase 2B, parallel to 2A).
**Prompt (paraphrase):** the §5 Phase-2B block — author `hex_1.json`/`hex_2.json`/`hex_manifest.json`, `HexAssetLevelCatalogService`, `GetHexLevelSelectionUseCase`, `HexLevelSelectViewModel` + providers; write the greedy-solver solvability test FIRST and design the levels against it; square campaign untouched (15 levels).
**Result obtained:** both levels built by inverse construction (each arrow escapes over the already-placed occupancy ⇒ solvability guaranteed by the game's monotonicity), verified against the REAL `LevelBuilder` + greedy solver. `hex_1` "Panal" (14 cells, 4 arrows, 3 initially blocked), `hex_2` "Colmena" (41 cells, 11 arrows, 8 blocked). 13 new tests including catalog isolation both ways; suite 304/304; analyze 72 issues (3 inevitable `prefer_initializing_formals` clones from mirroring the square twins).
**Team modifications:** none — orchestrator reviewed `hex_1.json` and the `providers.dart` diff before approving the push; merged as-is via PR #24.
**Lessons learned:** designing odd-r hex levels by eye is a trap (row parity flips neighbours); inverse construction turns solvability into an invariant of generation and simultaneously maximises initial dependencies — the difficulty metric. The auxiliary script only *designs*; the real gate is the test that rebuilds with production `LevelBuilder` + solver.

### Entry H-004 — feature/hex-mode-ui: hexagonal-mode UI entry point (button, select screen, i18n)

**Task:** Phase 3 (final) — surface the hex mode in the UI: a "Hexagonal Mode" button under the creative one, a new `HexLevelSelectScreen` chaining the hex campaign queue into `GameScreen`, en/es i18n, and closing the AI docs.
**Prompt (paraphrase):** the §5 Phase-3 block — `_HexModeButton` (mirror style, amber, `Icons.hexagon`, `Key('level_select_hex_button')`, i18n, no login) → push `HexLevelSelectScreen`; the screen uses `hexLevelSelectViewModelProvider` (initState+load), two large cards with locked/unlocked/completed + stars + best score + a 6-direction note + `hexTileKey(int)`; playable tap → `startCampaign` from that index + `GameScreen` + reload on return; new i18n keys + `gen-l10n`; screen tests via the Testing API + `ProviderScope` fakes.
**Result obtained:** `_HexModeButton` and `HexLevelSelectScreen` built mirroring the existing screen's patterns exactly, so Panal→Colmena chaining and progress persistence work with zero new infrastructure; 3 new i18n keys in both `.arb` files, localizations regenerated; 6 new tests + a `HexLevelSelectScreenTestApi`. Suite 330/330; analyze 72 issues (same baseline, zero new); `windows/` untouched. Also reordered `AI_USAGE.md` 027/028/029 and closed this log.
**Team modifications:** superseded by the trail redesign requested immediately after review (see H-005) — the card-based screen from this entry never shipped as-is.
**Lessons learned:** the hex mode is UI over already-proven pipes — reusing `startCampaign`/`load()` avoided any new persistence code. Mirroring the existing Testing API kept the screen tests three-tier and hermetic; using a distinct lock glyph (`Icons.lock_outline_rounded`) in the card's trailing action keeps the `Icons.lock_rounded` count clean as the tests' locked-state contract.

### Entry H-005 — feature/hex-mode-ui (cont.): hex_3 "Enjambre" + hex campaign trail with coming-soon node

**Task:** A third, much harder hex level (giant board, ~2× arrows, deeply interlocked) generated by inverse construction, plus a redesign of `HexLevelSelectScreen` from cards to a campaign-style winding trail ending in an under-construction "coming soon" teaser node.
**Prompt (paraphrase):** "`hex_3.json` 'Enjambre': ~90-110 cells with an interior hole, 20-24 arrows (3-7 cells), ≥15 initially blocked, lives 3, 480 s, `parMoves` = arrow count, built with the phase-2B inverse-construction script; add to the manifest; extend the solvability test (≥90 cells, ≥15 blocked). Rebuild the hex screen as a `_CampaignTrail` mirror with a non-tappable `Icons.construction` node (`hexComingSoon` i18n, `Key('hex_coming_soon_tile')`); square campaign untouched."
**Result obtained:** seed-40 level: 110 cells (rows 0-10, 3-cell interior hole), 24 arrows, **18 initially blocked**, last 8 greedy moves forced; two generator refinements were needed — ray-biased walks (candidates prefer stepping on escapable arrows' escape rays) and rejecting unblockable arrows (head pointing straight off-board, escape ray of 0 in-board cells), plus exhaustive DFS enumeration once the board saturates. Trail screen mirrors the square campaign (progress bar, "you are here" marker, solid/dashed path) in amber, no per-node leaderboard, dashed-circle coming-soon node. Mirroring (not extracting) keeps the original screen and its tests untouched. Suite 337/337; analyze 72 (exact baseline).
**Team modifications:** see H-007 — playtesting this exact build in a real Chrome session surfaced the interior hole and two trail-layout collisions, fixed directly by the orchestrator before the PR.
**Lessons learned:** difficulty is not free in inverse construction — without ray bias the scorer found few blocks, and without the ray≥1 rule the board filled with edge-pointing arrows immune to any dependency; per-step debug (escapable/rayCells per placement) exposed both pathologies. Cell budgeting matters: 22×5-cell arrows cannot fit 99 cells — decreasing lengths as the board fills and switching to exhaustive search under fragmentation turned an always-failing generator into a reliable one.

### Entry H-006 — Integration checkpoint: local preview merge, a real `AI_USAGE.md` conflict, and the human's own GitHub merges

**Task:** Before Phase 3 (`feature/hex-mode-ui`) could be started, `hex-core`, `hex-board-rendering` and `hex-levels-catalog` needed to be combined somewhere — but at this point in the session none of the three had actually landed on `origin/develop` yet (the human had pushed all three but had only asked the orchestrator to open a PR for the docs branch; the code branches were pushed "sin PRs" by explicit choice). The human then asked to see the hex mode running, which needs all three combined.

**Prompt (paraphrase):** "vamos a probar como funciono y como se ve" (let's try it and see how it looks) — followed, once the orchestrator explained Phase 3 didn't exist yet to provide an entry point, by an interruption and "ya hice los merges terminemos" (I already did the merges, let's finish) once the human had gone to GitHub and merged the branches themselves.

**Result obtained:** The orchestrator created a throwaway local branch `preview/hex-integration` (from `feature/hex-core`) purely to sanity-check the three branches combined without touching anything remote: fast-forward merge of `hex-board-rendering` (clean), then merge of `hex-levels-catalog` — which hit a **real conflict in `AI_USAGE.md`**, exactly the entry-numbering collision rule 5 exists to warn about: both branches had independently inserted their entry (028, 029) at the same point in the file. Resolved locally by hand (strip conflict markers, keep both entries in ascending order) and committed the merge — this was in progress (reading `level_select_screen.dart` to sketch a temporary demo entry point) when the human interrupted: they had, independently and in parallel, opened and merged PRs #23 and #24 directly on GitHub. `git fetch` confirmed `origin/develop` now contained all of hex-core (#21), hex-mode-plan docs (#22), hex-board-rendering (#23) and hex-levels-catalog (#24) — with `AI_USAGE.md`'s entries landing in the order **027, 029, 028** (GitHub's own merge conflict resolution differed from the orchestrator's local one, since the two merges happened independently and in a different order). The orchestrator's local `preview/hex-integration` branch was deleted outright as no-longer-needed scaffolding — its own conflict resolution never mattered, only the human's real one did. Phase 3 was then cut fresh from the now-complete `origin/develop`.

**Team modifications:** the human performed the actual integration (merging #23 and #24 via the GitHub UI) while the orchestrator's local preview attempt was still in progress; the orchestrator's job here was to detect the divergence via `git fetch`, discard its own now-redundant work, and continue from the authoritative state.

**Lessons learned:** a local "let's see if these combine" branch is disposable QA, not a merge decision — the instant the human does the real merge, whatever the orchestrator resolved locally is worthless and must be thrown away, not reconciled. The `AI_USAGE.md` numbering collision predicted in rule 5 happened for real, twice in slightly different forms (once in the orchestrator's local merge, once in GitHub's), which is exactly why Phase 3's own task later included a step to physically reorder 027/028/029 back into ascending sequence rather than leaving it as an artifact of merge order. This was also the first clear signal that the human treats agent orchestration as *collaborative*, not just an approval gate: they merge branches themselves when it's faster than waiting on a round trip.

### Entry H-007 — feature/hex-mode-ui (cont.): live playtest loop — solid Enjambre, trail layout, and a stopped-agent recovery

**Task:** First end-to-end run of the finished hex mode in a real browser build (`flutter run -d chrome`), once Phase 3 (button + trail screen + `hex_3` "Enjambre") had been built on top of the now-complete `develop`. This was not a single fix — it was a short iterative loop of playing, reporting, and fixing, spanning a stopped-and-recovered agent session and two rounds of direct edits.

**Prompt (paraphrase):** First, mid-launch of the Chrome build: "no me gusta que el nivel tenga un hueco en medio del tablero, acomoda el 3 nivel" (regenerate Enjambre without the interior hole) — sent to the still-running hex-mode-ui implementer. That session was then **explicitly stopped by the human** partway through the regeneration (not a failure — a deliberate interrupt), followed immediately by "puedes terminar lo que estaba haciendo el subajente" (can you finish what the subagent was doing). Once the fix was applied and the app relaunched, two more requests arrived while Chrome was still booting: "acomoda un poco el selector para que la etiqueta de jugar del primer nivel no colisione con la barra de progreso" and "el círculo final de próximamente ruédalo un poco para la izquierda para que esté más centrada la línea punteada que lo atraviesa." Finally, mid-loop: "vamos a crorrer como quedo, corre" (let's run it to see how it turned out) — asked to launch immediately rather than wait for the fix to finish first.

**Result obtained:**
- **Stopped-agent recovery, not a fresh subagent:** `SendMessage` to the stopped implementer returned "won't be resumed... only launch a new agent if the user explicitly asks" (the human's stop is treated differently from a transient failure — see rule 8). Since the human HAD explicitly asked to finish the work, the orchestrator was authorized to act, but chose not to pay the cost of a brand-new subagent re-deriving the whole hex_3 context from the design doc. Instead it inspected the worktree directly (`git status`/`git log` — confirmed no regeneration had been committed yet) and found the stopped session's own Dart generator script (`gen_hex3.dart`) still sitting in the shared scratchpad (see rule 9) — reused it as-is.
- **Enjambre regenerated solid:** ran `gen_hex3.dart` against a 102-cell hexagon with no interior gap (the script's own shape-building code already produced a solid silhouette — a stale comment in it claiming a hole was subtracted was leftover from an earlier iteration and never matched the actual code). A first 300-seed sweep only reached 21 arrows / 14 blocked (below the design's own ≥15 bar); widened to 1500 seeds in a background run and found seed 508 — **21 arrows, 16 initially blocked, last 14 greedy moves forced** (a longer forced tail than the hole version had, i.e. harder, not just prettier). Applied directly to `hex_3.json` and reverified against the production `LevelBuilder` + `GreedyBoardSolver` (`hex_levels_test.dart`, 11/11 green) — the app was relaunched in Chrome for the "corre" request even while the wider seed search was still running in the background, with the human told up front that the board would still show the old hole until the search finished and the result was applied.
- **Trail/progress-bar collision fixed:** the current-level "play" marker renders `size/2 + 34` above its node's center; `_HexTrail._topPad` (44px) left it partly negative — bleeding into the progress bar above via the `Clip.none` Stack. Raised to 100px.
- **Coming-soon node recentred:** added `_comingSoonShiftLeft = 24`, applied to the trail's own computed center for the last node (not just its widget position), so the connecting dashed line — which is drawn to that same coordinate — keeps terminating exactly at the node's center while the whole thing (line + circle) moves left together. Both layout fixes were diagnosed by reading `_HexTrail`'s existing geometry code directly and applied with `Edit`, not by spawning any agent — they were small, well-understood, and the file had just been read in full.
- No hot-reload was available (rule 12) — every code change in this loop required killing and relaunching the whole `flutter run -d chrome` process, which is also why two of the three fixes were batched into one relaunch rather than three separate ones.
- Final verification after all three fixes: `flutter analyze` **72 issues** (exact baseline, zero new), `flutter test` **337/337**, committed on `feature/hex-mode-ui`.

**Team modifications:** none pending — this entry and its predecessor (H-006) together **are** the team's requested corrections, applied and verified live in this session rather than deferred to a review round.

**Lessons learned:** none of the three UI/content defects could have been caught by the test suite — they are visual and compositional, not logical, and 337 green tests found none of them; only playing the real build did. The generator's difficulty is shape-sensitive: the seed that wins on a hexagon-with-a-hole doesn't necessarily win on the solid one, so removing the hole required re-searching (and widening) the seed space, not just deleting three cells from the previously-winning result. Operationally, the sharp distinction between "resume the same agent" (transient failure) and "the human stopped it on purpose" (don't resume; either the human wants to redirect, or wants the orchestrator to finish it directly) kept this fast-moving, interrupt-heavy stretch of the session from either losing work or re-deriving context it already had sitting in the shared scratchpad.

## Retrospective: numbers across the four phases

| Phase | Branch | New tests | Suite total | `flutter analyze` | Merged as |
|---|---|---|---|---|---|
| 0 — design | `feature/hex-mode-plan` | — | — | — | PR #22 |
| 1 — core | `feature/hex-core` | 30 | 291/291 | 69 (baseline) | PR #21 |
| 2A — rendering | `feature/hex-board-rendering` | 20 | 311/311 | 69 (+0) | PR #23 (human-merged) |
| 2B — levels/catalog | `feature/hex-levels-catalog` | 13 | 304/304 | 72 (+3, unavoidable lint clones) | PR #24 (human-merged) |
| 3 — UI (cards, 2 levels) | `feature/hex-mode-ui` | 6 | 330/330 | 72 (+0) | superseded by H-005/H-007 before its own PR |
| 3 cont. — trail + Enjambre | `feature/hex-mode-ui` | 7 | 337/337 | 72 (+0) | PR #25 (open) |
| 3 cont. — playtest fixes | `feature/hex-mode-ui` | 0 (content/layout only) | 337/337 | 72 (+0) | same PR #25 |

`analyze` never regressed past the 3-issue bump in Phase 2B (mirrored constructor style, not a real problem); the test count only ever grows. No phase required touching an existing test's assertions — every addition was additive, which is the practical payoff of the domain having been designed for multiple topologies from the start (H-000).

<!--
Template for upcoming entries (append per branch as it lands):

### Entry H-00N — <branch>: <title>

**Task:** ...
**Prompt (paraphrase):** ... (the §5 block given to the worktree subagent)
**Result obtained:** ...
**Team modifications:** ...
**Lessons learned:** ...
-->
