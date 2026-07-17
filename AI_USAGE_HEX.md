# AI Usage — Hexagonal Mode (feature-specific log)

**Repository:** ucab-arrowmaze-mobile — Arrow Maze Escape Puzzle (Flutter client)
**Feature:** Hexagonal Mode (design doc: `docs/HEX_MODE_PLAN.md`)
**Relation to `AI_USAGE.md`:** this file is the detailed, feature-specific log for
the hexagonal mode. Each branch listed here still appends its own numbered
entry to the repo-wide `AI_USAGE.md` (graded rubric item); this document adds
the orchestration methodology and the per-phase detail that doesn't fit there.
**Last updated:** 2026-07-17

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

<!--
Template for upcoming entries (append per branch as it lands):

### Entry H-00N — <branch>: <title>

**Task:** ...
**Prompt (paraphrase):** ... (the §5 block given to the worktree subagent)
**Result obtained:** ...
**Team modifications:** ...
**Lessons learned:** ...
-->
