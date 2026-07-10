# Proposal — Borrow from `vibe-clauding` and mattpocock/skills

- **Status:** proposed
- **Date:** 2026-07-10
- **Scope:** proposal only — no skill files added in this PR. Decides *what* to borrow and *how* it grafts onto the harness. Implementation follows in separate PRs.

---

## 1. Context

Two gaps in the current harness motivate this proposal:

1. **The harness is greenfield-only.** The phase spine (`orchestrator/SKILL.md`) runs `0. project-setup → 7. finish` assuming a project built from scratch. Yet the orchestrator's own opening line calls this a *"harness template for the new project / **new feature** topology"* — the new-feature topology is named but never implemented, and there is no bugfix path at all. Superpowers owns debugging as a skill, but there is no *workflow* that shapes a bugfix (root-cause-first, minimal-fix discipline, reduced pipeline).
2. **Thin on the architecture-regulation quadrant.** The orchestrator's own "honest gap map" flags weakness on computational sensors and on deep-module / architecture enforcement.

Two in-house sources can fill these without inventing anything:

- **`vibe-clauding`** (Codeberg, `ziggornif/vibe-clauding`) — an agent-based multi-agent system with three explicit entry workflows (`new-product`, `new-feature`, `bugfix`), concrete per-role model routing, and human checkpoints.
- **`mattpocock/skills`** (GitHub, MIT) — already partially vendored (`handoff`, `prototype`); several unvendored skills are strong craft fits.

**Paradigm constraint (load-bearing).** `vibe-clauding` is built from **named agents** (orchestrator, product-owner, architect, backend-dev, …). This harness is deliberately **skill-based**, riding superpowers' subagent-driven-development. We do **not** import the named agents — that would fork the control model. We mine the **workflow shapes**, the **model-routing table**, and the **checkpoint discipline**, and re-express them as phase-spine variants and orchestrator sections.

---

## 2. What each source offers vs. what the harness already has

### 2.1 `vibe-clauding`

| `vibe-clauding` | Harness has it? | Verdict |
|---|---|---|
| `new-product` workflow | ✅ the phase spine | duplicate — ignore |
| **`new-feature`** (existing codebase, impact assessment, conditional UX/security) | ❌ | **borrow — fills greenfield-only gap** |
| **`bugfix`** (root-cause-first, minimal fix, reduced pipeline) | ❌ (superpowers debug skill, no workflow) | **borrow — fills missing bugfix path** |
| `/new` `/feature` `/bugfix` entry commands | ❌ (single "launch the harness") | borrow the *routing signal*, not the commands |
| **Explicit model routing** (opus/sonnet/haiku per role) | ⚠️ orchestrator describes "route by tier" abstractly | **borrow — concretize the routing table** |
| Named agents (11 roles) | ❌ (skill-based by design) | **do not import — paradigm clash** |
| `/test`, `/security-scan`, `/spec` point-actions | partial (`security-review` skill, superpowers) | skip — overlap |
| `vibe-clauding` CLI activation | `bin/link-skills.sh` | skip — different mechanism |

### 2.2 mattpocock/skills — beyond already-vendored `handoff` + `prototype`

`vendor/matt-pocock/ORIGIN.yaml` already records deliberate rejections (tdd, grill-*, diagnose, triage, to-*) for good reasons (superpowers collision, tracker-coupling). The same logic eliminates most unvendored skills. Survivors:

| Skill | Why borrow | Cost |
|---|---|---|
| **codebase-design** (deep modules, seams, depth — refined Ousterhout) | pure craft, complements `hexagonal-architecture`, zero collision, **no external deps** | low — vendor pristine |
| **improve-codebase-architecture** (architectural audit → HTML report of shallow-module candidates) | directly serves the architecture-regulation gap; an *inferential sensor* over structure | **higher — depends on `/grilling`, `/domain-modeling`, `CONTEXT.md`; needs rework** |
| `research` | general utility, no overlap | defer — not gap-driven |
| `wayfinder` | overlaps superpowers plan | skip for now |

**Rejected (with reason):** `domain-modeling` (= our `ubiquitous-language`), `code-review` (= superpowers), `to-spec`/`to-tickets`/`implement` (tracker-coupled — we already took the AGENT-BRIEF *format* into `agent-brief`), `grilling`/`ask-matt`/`setup-*`.

---

## 3. Proposal 1 — Entry topologies `new-feature` and `bugfix`

Add two **entry topologies** to the orchestrator. They are not new skills; they are documented *routes through* the existing phase spine plus superpowers, selected at project start by the same routing logic `vibe-clauding`'s orchestrator uses.

### 3.1 Routing (new orchestrator section "Entry topology")

At the start of work, before phase 0, classify intent:

| Signal | Topology |
|---|---|
| No existing codebase; "create", "new app", "from scratch", "greenfield" | **new-product** → full phase spine 0–7 (current behavior) |
| Existing codebase in cwd; "add", "implement", "integrate", "new endpoint/page" | **new-feature** → reduced spine (§3.2) |
| "fix", "bug", "broken", "regression", stack trace, ticket ref | **bugfix** → minimal spine (§3.3) |
| Ambiguous | STOP — ask the human |

### 3.2 `new-feature` topology (reduced spine)

Maps `vibe-clauding`'s `new-feature` pipeline onto our skills. Key differences from `new-product`: **architect analyzes the existing codebase first**, project-setup is skipped, agents are conditional.

```
1. product-discovery   → frame the feature, acceptance criteria      gate: READY FOR ARCHITECTURE
                          [STOP — human validates the functional spec]
2. hexagonal-architecture → analyze existing code FIRST, impact assessment,
                          API/SPI contract, breaking-change detection  gate: ACCEPT
                          [STOP — if breaking change detected]
3b. design (if UI)     → prototype UI branch, cohere with existing design
4.  plan + agent-brief → superpowers plan → brief per changed slice     gate: READY TO DELEGATE
5.  subagent dev (TDD) → superpowers subagent-driven-development         gate: tests green + grids
6.  review             → computational sensors first, then inferential grids
    security-review     → CONDITIONAL: auth / sensitive data / new API surface / file upload / perms
7.  finish             → superpowers finish-the-branch
```

Skipped vs new-product: `project-setup` (repo already exists), `ubiquitous-language` runs only if the feature introduces new domain terms (kick back to it if so), `ci-setup` (CI already wired).

Borrowed discipline from `vibe-clauding`: existing-codebase-analysis-first, breaking-change checkpoint, conditional security/UX triggers (the explicit trigger lists in `workflows/new-feature.md` are worth transcribing verbatim into the orchestrator).

### 3.3 `bugfix` topology (minimal spine)

Maps `vibe-clauding`'s `bugfix` pipeline. This is where superpowers' systematic-debugging plugs in, wrapped in minimal-fix discipline.

```
1. root cause           → superpowers systematic-debugging: reproduce, locate,
                          identify true cause (not symptom), impact scope
                          [STOP — if root cause is an architecture problem:
                           present (a) symptom fix + tech-debt ticket, or
                           (b) escalate to new-feature topology; human decides]
2. fix (TDD)            → superpowers TDD: failing repro test FIRST, then minimal fix
3. review              → non-regression: full suite green, no adjacent refactor
                          [minimal-fix rule enforced — see below]
4. finish              → superpowers finish-the-branch
```

**Minimal-fix rule** (transcribe from `vibe-clauding/workflows/bugfix.md`): the smallest change that fixes the bug. No refactor, no adjacent cleanup, no feature-add, no dep bump (unless the dep *is* the cause), no convention change. Problematic surrounding code is logged as tech-debt, not fixed here. This is a strong, testable guide that the current harness lacks entirely.

### 3.4 Where it lands

Extend `orchestrator/SKILL.md` with an "Entry topologies" section (routing + the two reduced spines). The current spine becomes explicitly the `new-product` topology. No new skill folders needed — the topologies reuse existing skills in a different order with different gates.

---

## 4. Proposal 2 — Concrete model-routing table

The orchestrator's "Model routing by reasoning tier" section is currently abstract ("frontier for reasoning, cheaper for mechanical"). `vibe-clauding` assigns a concrete model per role. Fold a concrete table into the orchestrator, **keyed by reasoning tier / activity**, not by named agent (to stay paradigm-consistent):

| Activity | Tier | Rationale (from `vibe-clauding` role assignments) |
|---|---|---|
| product-discovery, architecture decisions, security review, planning, all inferential review grids, root-cause analysis | **frontier (opus-class)** | quality-setting reasoning; `vibe-clauding` puts orchestrator/PO/architect/security/tech-lead on opus |
| implementation from a detailed brief, QA/test authoring, UX annotation, mechanical transforms | **mid (sonnet-class)** | executes an explicit brief; `vibe-clauding` puts dev/qa/ux on sonnet |
| documentation updates, changelog, formatting | **cheap/local (haiku-class)** | low-reasoning transforms; `vibe-clauding` puts documentation on haiku |

This concretizes the existing principle without contradicting it: the reasoning tier — not the phase — still decides. It just gives the reader a worked mapping.

---

## 5. Proposal 3 — Vendor `codebase-design` (+ `improve-codebase-architecture` with rework)

### 5.1 `codebase-design` — vendor pristine

Clean, MIT, zero external deps. Files: `SKILL.md`, `DEEPENING.md`, `DESIGN-IT-TWICE.md`. Provides a precise deep-module vocabulary (module / interface / depth / seam / adapter / leverage / locality), the deletion test, and testability-through-the-interface — all of which **complement** `hexagonal-architecture` (which owns API/SPI and slicing) rather than colliding with it. One collision to resolve in `ORIGIN.yaml` notes: its glossary reuses "seam" and "adapter"; align with our `ubiquitous-language` glossary so terms stay coherent.

Vendor per `VENDOR.md` policy: pristine commit first, add to `matt-pocock/ORIGIN.yaml` `included:` list, bump `VENDOR.md` registry, run `link-skills.sh`.

### 5.2 `improve-codebase-architecture` — vendor with dependency rework

Serves the architecture-regulation gap: an inferential sensor that sweeps the codebase for shallow modules and emits an HTML audit report of deepening candidates. **But** it depends on three things the harness does not have:

| Upstream dep | Harness substitute (rework needed) |
|---|---|
| `/grilling` (interview loop) | superpowers brainstorming |
| `/domain-modeling` + `CONTEXT.md` | our `ubiquitous-language` + `docs/glossary.md` |
| `/codebase-design` vocabulary | provided once §5.1 lands (order dependency) |

So it must be vendored *and patched* (record patches in `ORIGIN.yaml local_patches`), and only after `codebase-design`. Recommend: land §5.1 first, treat §5.2 as a follow-up once the vocabulary skill is in.

---

## 6. What we deliberately do NOT borrow

| Item | Why not |
|---|---|
| `vibe-clauding` named agents (11 roles) | Contradicts the skill-based, superpowers-driven control model. We take their *shapes*, not the agents. |
| `/test`, `/spec`, `/security-scan` point-actions | Overlap superpowers + local `security-review`. |
| `vibe-clauding` CLI + `install.sh` | We use `link-skills.sh`; different activation mechanism. |
| mattpocock `domain-modeling`, `code-review`, `to-*`, `grilling`, `research`, `wayfinder` | Already-recorded rejections in `ORIGIN.yaml`, or superpowers overlap, or not gap-driven. |

---

## 7. Implementation plan (ordered, separate PRs)

1. **Entry topologies** (Proposal 1) — highest value; fixes greenfield-only. Extend `orchestrator/SKILL.md` with routing + `new-feature` + `bugfix` reduced spines; transcribe the conditional-trigger lists and minimal-fix rule from `vibe-clauding`. Update `README.md` phase-spine section.
2. **Model-routing table** (Proposal 2) — small; fold the concrete table into the orchestrator's existing routing section.
3. **Vendor `codebase-design`** (Proposal 3.1) — pristine vendor + provenance bookkeeping + `link-skills.sh`.
4. **Vendor + rework `improve-codebase-architecture`** (Proposal 3.2) — after #3; patch out the three deps.

Each step is independently mergeable and independently reversible.

---

## 8. Sources

- `vibe-clauding` — Codeberg `ziggornif/vibe-clauding` (author's own repo). Files referenced: `workflows/new-feature.md`, `workflows/bugfix.md`, `agents/orchestrator.md`.
- mattpocock/skills — GitHub `mattpocock/skills`, MIT. Skills referenced: `engineering/codebase-design`, `engineering/improve-codebase-architecture`.
- Current harness: `skills/local/orchestrator/SKILL.md`, `skills/vendor/VENDOR.md`, `skills/vendor/matt-pocock/ORIGIN.yaml`.
