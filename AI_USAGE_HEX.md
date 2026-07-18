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
   optional QA** — the three defects in H-006 (an unwanted interior hole, a
   marker/progress-bar collision, an off-center dashed line) were all
   invisible to `flutter analyze`/`flutter test` and only surfaced once a
   human actually played the build.
8. **Implementer sessions can die mid-task from transient causes** (API
   connectivity, provider outage, session-limit resets) — this happened
   three times across the four phases. None were code problems: each was
   resumed via `SendMessage` with the exact same context and finished the
   original scope. If a session is explicitly stopped by the human instead
   (not a transient failure), it cannot be resumed — the orchestrator either
   launches a fresh agent with a full self-contained brief, or, for a small,
   already-understood fix, makes the change directly instead of re-deriving
   context in a new agent (see H-006).

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
**Team modifications:** see H-006 — playtesting this exact build in a real Chrome session surfaced the interior hole and two trail-layout collisions, fixed directly by the orchestrator before the PR.
**Lessons learned:** difficulty is not free in inverse construction — without ray bias the scorer found few blocks, and without the ray≥1 rule the board filled with edge-pointing arrows immune to any dependency; per-step debug (escapable/rayCells per placement) exposed both pathologies. Cell budgeting matters: 22×5-cell arrows cannot fit 99 cells — decreasing lengths as the board fills and switching to exhaustive search under fragmentation turned an always-failing generator into a reliable one.

### Entry H-006 — feature/hex-mode-ui (cont.): live playtest fixes — solid Enjambre, trail layout

**Task:** First end-to-end run of the finished hex mode in a real browser build (`flutter run -d chrome`), after all four phases were reviewed and (for hex-core/hex-board-rendering/hex-levels-catalog) merged into `develop`. The session played Panal, opened the trail, and reported three defects live.

**Prompt (paraphrase):** "No me gusta que el nivel tenga un hueco en medio del tablero, acomódalo" (regenerate Enjambre without the interior hole). Then, same session: "acomoda un poco el selector para que la etiqueta de jugar del primer nivel no colisione con la barra de progreso, y el círculo final de próximamente ruédalo un poco para la izquierda para que esté más centrada la línea punteada que lo atraviesa."

**Result obtained:**
- **Enjambre regenerated solid:** reran the H-005 inverse-construction script against a 102-cell hexagon with no interior gap. A first 300-seed sweep only reached 21 arrows / 14 blocked (below the ≥15 bar); widening to 1500 seeds found seed 508 — **21 arrows, 16 initially blocked, last 14 greedy moves forced** (a longer forced tail than the hole version had). Reverified against the production `LevelBuilder` + `GreedyBoardSolver` (`hex_levels_test.dart`, 11/11 hex-level tests green).
- **Trail/progress-bar collision fixed:** the current-level "play" marker renders `size/2 + 34` above its node's center; `_HexTrail._topPad` (44px) left it partly negative — bleeding into the progress bar above via the `Clip.none` Stack. Raised to 100px.
- **Coming-soon node recentred:** added `_comingSoonShiftLeft = 24`, applied to the trail's own computed center for the last node (not just its widget position), so the connecting dashed line — which is drawn to that same coordinate — keeps terminating exactly at the node's center while the whole thing (line + circle) moves left together.
- Applied directly by the orchestrator on `feature/hex-mode-ui` — no new subagent: the fixes were small, in a file just reviewed, and the branch's own implementer session had been stopped by the human mid-regeneration (unresumable; see rule 8 above) rather than lost to a transient failure. `flutter analyze`: 72 issues (baseline, 0 new). `flutter test`: 337/337.

**Team modifications:** none pending — this entry is itself the team's requested correction, applied and verified in the same session.

**Lessons learned:** None of these three defects could have been caught by the test suite — they are visual/compositional, not logical. The generator's difficulty is shape-sensitive: the seed that wins on a hexagon-with-hole doesn't necessarily win on the solid one, so removing the hole required re-searching (and widening) the seed space rather than just deleting three cells from the winning result. Operationally: distinguishing a *transient* agent failure (safe to resume with the same agent id) from a *human-stopped* one (must restart, either as a fresh agent or, for small well-scoped fixes, done directly) avoided both re-deriving context unnecessarily and silently dropping the human's stop signal.

<!--
Template for upcoming entries (append per branch as it lands):

### Entry H-00N — <branch>: <title>

**Task:** ...
**Prompt (paraphrase):** ... (the §5 block given to the worktree subagent)
**Result obtained:** ...
**Team modifications:** ...
**Lessons learned:** ...
-->
