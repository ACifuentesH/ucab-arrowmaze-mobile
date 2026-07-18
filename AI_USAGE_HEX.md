# AI Usage — Hexagonal Mode (feature-specific log)

**Repository:** ucab-arrowmaze-mobile — Arrow Maze Escape Puzzle (Flutter client)
**Feature:** Hexagonal Mode (design doc: `docs/HEX_MODE_PLAN.md`)
**Relation to `AI_USAGE.md`:** this file is the detailed, feature-specific log for
the hexagonal mode. Each branch listed here still appends its own numbered
entry to the repo-wide `AI_USAGE.md` (graded rubric item); this document adds
the orchestration methodology and the per-phase detail that doesn't fit there.
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
**Team modifications:** pending review.
**Lessons learned:** the prior investment in `Direction` (index/total), `ITopologyStrategy` and `IArrowFactory` paid off exactly as designed — hex entered without touching a single game rule or existing test; the only hidden square-coupled code was the builder's manhattan check.

### Entry H-002 — feature/hex-board-rendering: abstract board geometry + hex render

**Task:** Extract ALL pixel math from `BoardPainter`/`BoardView` into an `IBoardGeometry` abstraction and implement the hex geometry, without changing one pixel of the square render (Phase 2A).
**Prompt (paraphrase):** the §5 Phase-2A block — `IBoardGeometry` (cellScaleFor, boardSize, cellCenter, cellOutline, unit directionVector, stepDistance, hitTest), a `SquareBoardGeometry` reproducing today's behaviour 1:1, and a pointy-top odd-r `HexBoardGeometry` with Voronoi hit-test reusing `HexGridTopology.neighborOffset`; painter/view delegate geometry by `board.topologyKind`.
**Result obtained:** `board_geometry.dart` + `hex_board_geometry.dart`; painter and view refactored to delegate; 20 new tests (hand-derived square regression constants for pixel-identity, hex properties, real `BoardView` hex widget test). Suite 311/311; analyze 69 issues (zero new).
**Team modifications:** pending review.
**Lessons learned:** the square render secretly had two coupled scale formulas (painter `size.width/cols` vs view `min(w/cols,h/rows)`); `cellScaleFor(boardSize)` recovers the exact scale in both topologies and the "reserved size and scale are inverse" roundtrip is the property that makes the refactor pixel-neutral. Hit-test reuses the graph's neighbour table so pixel and graph geometry share one source of truth.

### Entry H-003 — feature/hex-levels-catalog: catalog, progression and two playable hex levels

**Task:** On top of the hex core, add content and an ISOLATED selection pipeline: two hand-designed levels (`hex_1` easy, `hex_2` hard), a dedicated asset catalog, a sequential-unlock use case and its view model, no screen (Phase 2B, parallel to 2A).
**Prompt (paraphrase):** the §5 Phase-2B block — author `hex_1.json`/`hex_2.json`/`hex_manifest.json`, `HexAssetLevelCatalogService`, `GetHexLevelSelectionUseCase`, `HexLevelSelectViewModel` + providers; write the greedy-solver solvability test FIRST and design the levels against it; square campaign untouched (15 levels).
**Result obtained:** both levels built by inverse construction (each arrow escapes over the already-placed occupancy ⇒ solvability guaranteed by the game's monotonicity), verified against the REAL `LevelBuilder` + greedy solver. `hex_1` "Panal" (14 cells, 4 arrows, 3 initially blocked), `hex_2` "Colmena" (41 cells, 11 arrows, 8 blocked). 13 new tests including catalog isolation both ways; suite 304/304; analyze 72 issues (3 inevitable `prefer_initializing_formals` clones from mirroring the square twins).
**Team modifications:** pending review.
**Lessons learned:** designing odd-r hex levels by eye is a trap (row parity flips neighbours); inverse construction turns solvability into an invariant of generation and simultaneously maximises initial dependencies — the difficulty metric. The auxiliary script only *designs*; the real gate is the test that rebuilds with production `LevelBuilder` + solver.

### Entry H-004 — feature/hex-mode-ui: hexagonal-mode UI entry point (button, select screen, i18n)

**Task:** Phase 3 (final) — surface the hex mode in the UI: a "Hexagonal Mode" button under the creative one, a new `HexLevelSelectScreen` chaining the hex campaign queue into `GameScreen`, en/es i18n, and closing the AI docs.
**Prompt (paraphrase):** the §5 Phase-3 block — `_HexModeButton` (mirror style, amber, `Icons.hexagon`, `Key('level_select_hex_button')`, i18n, no login) → push `HexLevelSelectScreen`; the screen uses `hexLevelSelectViewModelProvider` (initState+load), two large cards with locked/unlocked/completed + stars + best score + a 6-direction note + `hexTileKey(int)`; playable tap → `startCampaign` from that index + `GameScreen` + reload on return; new i18n keys + `gen-l10n`; screen tests via the Testing API + `ProviderScope` fakes.
**Result obtained:** `_HexModeButton` and `HexLevelSelectScreen` built mirroring the existing screen's patterns exactly, so Panal→Colmena chaining and progress persistence work with zero new infrastructure; 3 new i18n keys in both `.arb` files, localizations regenerated; 6 new tests + a `HexLevelSelectScreenTestApi`. Suite 330/330; analyze 72 issues (same baseline, zero new); `windows/` untouched. Also reordered `AI_USAGE.md` 027/028/029 and closed this log.
**Team modifications:** pending review.
**Lessons learned:** the hex mode is UI over already-proven pipes — reusing `startCampaign`/`load()` avoided any new persistence code. Mirroring the existing Testing API kept the screen tests three-tier and hermetic; using a distinct lock glyph (`Icons.lock_outline_rounded`) in the card's trailing action keeps the `Icons.lock_rounded` count clean as the tests' locked-state contract.

### Entry H-005 — feature/hex-mode-ui (cont.): hex_3 "Enjambre" + hex campaign trail with coming-soon node

**Task:** A third, much harder hex level (giant board, ~2× arrows, deeply interlocked) generated by inverse construction, plus a redesign of `HexLevelSelectScreen` from cards to a campaign-style winding trail ending in an under-construction "coming soon" teaser node.
**Prompt (paraphrase):** "`hex_3.json` 'Enjambre': ~90-110 cells with an interior hole, 20-24 arrows (3-7 cells), ≥15 initially blocked, lives 3, 480 s, `parMoves` = arrow count, built with the phase-2B inverse-construction script; add to the manifest; extend the solvability test (≥90 cells, ≥15 blocked). Rebuild the hex screen as a `_CampaignTrail` mirror with a non-tappable `Icons.construction` node (`hexComingSoon` i18n, `Key('hex_coming_soon_tile')`); square campaign untouched."
**Result obtained:** seed-40 level: 110 cells (rows 0-10, 3-cell interior hole), 24 arrows, **18 initially blocked**, last 8 greedy moves forced; two generator refinements were needed — ray-biased walks (candidates prefer stepping on escapable arrows' escape rays) and rejecting unblockable arrows (head pointing straight off-board, escape ray of 0 in-board cells), plus exhaustive DFS enumeration once the board saturates. Trail screen mirrors the square campaign (progress bar, "you are here" marker, solid/dashed path) in amber, no per-node leaderboard, dashed-circle coming-soon node. Mirroring (not extracting) keeps the original screen and its tests untouched. Suite 337/337; analyze 72 (exact baseline).
**Team modifications:** pending review.
**Lessons learned:** difficulty is not free in inverse construction — without ray bias the scorer found few blocks, and without the ray≥1 rule the board filled with edge-pointing arrows immune to any dependency; per-step debug (escapable/rayCells per placement) exposed both pathologies. Cell budgeting matters: 22×5-cell arrows cannot fit 99 cells — decreasing lengths as the board fills and switching to exhaustive search under fragmentation turned an always-failing generator into a reliable one.

<!--
Template for upcoming entries (append per branch as it lands):

### Entry H-00N — <branch>: <title>

**Task:** ...
**Prompt (paraphrase):** ... (the §5 block given to the worktree subagent)
**Result obtained:** ...
**Team modifications:** ...
**Lessons learned:** ...
-->
