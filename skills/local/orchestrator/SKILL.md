---
name: orchestrator
description: The control system of this harness — read it FIRST, at the start of any project or feature. It defines the phase order, which skill owns the human at each moment, how work is routed to models by reasoning tier, where computational and inferential checks run across the lifecycle, and how the harness is steered over time. Use it whenever you are starting work, deciding what phase you're in, deciding whether a phase's exit gate is met, or deciding which model/subagent should do the next step. If you are unsure what to do next in this harness, this skill is the answer.
---

# Orchestrator

This is the **outer harness's control system**. The mental model follows Birgitta Böckeler's *Harness Engineering* (martinfowler.com, 2026): an agent is a model plus a harness, and a good harness regulates the agent with **guides** (feedforward — steer before acting) and **sensors** (feedback — observe after, enable self-correction), each either **computational** (deterministic: tests, linters, type-checkers, structural analysis) or **inferential** (semantic: LLM-as-judge, review agents). A harness that has only guides never learns whether its rules worked; one with only sensors repeats its mistakes. The job here is to run all four quadrants in the right order, at the right cost, with the human steering.

This harness is a **harness template for the "new project / new feature" topology**, leashed to a hexagonal + API/SPI + vertical-slice structure. Committing to that topology is deliberate: it narrows what the agent can produce, which is what makes a comprehensive harness achievable.

## Where our assets sit in the four quadrants

| | Feedforward (guides) | Feedback (sensors) |
|---|---|---|
| **Inferential** | `product-discovery`, `ubiquitous-language`, `hexagonal-architecture`, `agent-brief`, superpowers brainstorming/plan/TDD | the review grids inside each skill (LLM-as-judge), superpowers code-reviewer |
| **Computational** | `project-setup` bootstrap scripts, scaffolds | **← the gap.** type-checker, test runner, linter, dependency-cruiser / ArchUnit / crate-graph, coverage, drift scans |

Read that table honestly: we are strong on inferential feedforward, present on inferential feedback, and **thin on computational sensors** — the cheapest, most reliable quadrant. Closing that gap is the priority that turns this from a methodology collection into a harness. Wherever a skill says "enforce mechanically", that enforcement is a computational sensor that must actually exist in the target repo.

## The evaluator is a separate, skeptical agent (never self-review)

Inferential sensors — our review grids — must be run by an agent **distinct from the one that produced the work**, not as self-review. Agents grading their own output skew positive and will confidently approve mediocre work; the gap between "looks done" and "is done" is exactly what they rationalize away. Two design consequences (drawn from Anthropic's *Harness design for long-running application development*, 2026, and its generator/evaluator pattern):

- **Tune the evaluator to be skeptical.** Making a standalone evaluator critical is far more tractable than making a generator self-critical. The evaluator owns the review grid; the generator only sees its verdict and iterates against it.
- **Grade against concrete criteria with hard thresholds.** Each review grid is already pass/fail; treat any failed item as a hard stop that bounces the work back with specific feedback, not a soft suggestion. Where possible the evaluator should exercise the running result (e.g. drive the UI/API), not just read the diff — behavior is verified by use, not by inspection.

This is why every skill in this harness ships a review grid: it is the evaluator's contract, kept separate from the generator's guide.

## Definition-of-done contract before implementation

Before a slice is implemented, the generator and evaluator agree a **done contract**: the specific testable behaviors that will verify completion, settled *before* any code is written. This bridges the intentionally high-level spec and a testable implementation, and it is exactly the acceptance-criteria section of the `agent-brief` used as a negotiated contract — the generator proposes what it will build and how success is checked, the evaluator confirms it is the right thing, and only then does coding start.

## The phase spine

Run phases in order. Each phase has an **exit gate** — the review grid of the owning skill — and the next phase does not start until the gate passes. This is superpowers' "the workflow is the skills, in order", extended with our craft phases.

```
0. project-setup        → choose tracker/CLI, locate glossary & ADRs        [once per repo]
1. product-discovery    → problem, user, outcomes, riskiest assumption       gate: READY FOR ARCHITECTURE
   (prototype)          → optional: spike the riskiest assumption cheaply
2. ubiquitous-language  → sharpen terms into a glossary; ADRs for hard calls  gate: LANGUAGE SOUND
3. hexagonal-architecture → slices, API/SPI, per-slice structure             gate: ACCEPT (architecture grid)
3b. design (if UI/frontend) → fill docs/design.md via prototype (UI branch)  gate: docs/design.md non-empty
4. plan + agent-brief   → superpowers plan decomposes; one brief per slice    gate: READY TO DELEGATE (per brief)
5. subagent dev (TDD)   → superpowers subagent-driven-development, per slice   gate: tests green + grids pass
6. review               → computational sensors FIRST, then inferential grids gate: all sensors green
7. finish               → superpowers finish-the-branch
   handoff              → if work spans sessions/agents, compact context
```

**Phase 3b is not optional when the project has a UI component.** After architecture confirms which slices have a frontend surface, ask the human one question: "This project has a UI — should we define the design before implementation?" If the answer is yes (or if the product brief mentions a frontend), run the `prototype` UI branch to explore at least two visual directions, record the decisions in `docs/design.md`, and only then proceed to plan. Do not let implementation start on a UI slice with an empty `docs/design.md`. The dogfood signal that motivated this gate: a working but undesigned frontend was produced because no phase asked the design question.

## Who owns the human (resolve the interrogation collision)

Three skills can question the human (discovery, ubiquitous-language, superpowers brainstorming). **Only one owns the human at a time, and only in its phase.** The rule everywhere: ask one question at a time, propose your recommended answer, and explore the codebase/docs before asking anything answerable without the human. Outside phases 1–2 the harness runs mostly autonomously, surfacing the human only at exit gates and at the human-review sensor (phase 6). If a downstream phase discovers a genuine product question, it does not start its own interrogation — it kicks back to the owning phase.

## Model routing by reasoning tier (hybrid frontier/local)

Route each step to the cheapest model capable of it — superpowers 5's principle, applied across the whole harness:

- **Frontier (strong reasoning):** discovery, architecture decisions, security review, planning, and all *inferential* review grids. These set quality; spend here.
- **Cheaper / local:** implementation subagents working from a detailed brief, and mechanical transforms. A good `agent-brief` makes the task explicit enough that a small or local model executes it without complex reasoning.

This is why `agent-brief` quality is load-bearing: the better the brief, the lower the tier the implementation can drop to, the more of the harness runs on your own hardware. The reasoning tier — not the phase — decides frontier vs local.

A sharper version of the same idea applies to the evaluator: it is worth its cost only when the task sits *beyond what the generator does reliably on its own*. For work well within the generator's solo capability, the evaluator is overhead; for work at or past the edge, it gives real lift. So route the evaluator in too — skip it on trivial slices, spend it on the hard ones.

## Keep quality left: where sensors run

Distribute checks by cost, speed, and criticality:

- **Pre-commit (fast, computational, every change):** type-check, lint, dependency-cruiser/ArchUnit/crate-graph (the dependency rule), unit tests, domain-purity checks.
- **Pre-merge (heavier):** full test suite incl. SPI-adapter integration tests (Testcontainers), e2e on critical journeys, then the *inferential* review grids (architecture, security, agent-brief) and human review.
- **Continuous drift (outside the change lifecycle):** dead-code detection, coverage-quality, dependency/vulnerability scans — the "garbage collection" pass that scans for drift and has an agent propose fixes.

## Self-correction loop

Wire computational sensors so their failure output is consumed by the implementing subagent *before* it reaches a human — and make those messages LLM-shaped: a dependency-cruiser violation should not just say "boundary violation", it should tell the agent *which* rule, *why* it exists (point at the hexagonal skill), and *the smallest fix*. A sensor that emits a fix-instruction turns a failure into a self-correction instead of a human ticket.

## The steering loop (the human's real job)

The human does not micro-review output; the human **iterates on the harness**. When the same failure appears twice, do not just fix the instance — strengthen a control so it can't recur: add or sharpen a guide (a skill line, a glossary term, an ADR) or add a sensor (a lint rule, a structural test). This is the disciplined version of "encode the decision the second time you make it". A harness is an ongoing engineering practice, not a one-time setup; its guides and sensors must be kept coherent and in sync as it grows.

The flip side matters just as much: **every component in this harness encodes an assumption about what the model can't do on its own — and those assumptions go stale as models improve.** Stress-test them. When a stronger model lands, re-examine the harness: strip the pieces that are no longer load-bearing and add new ones that reach capability the old model couldn't. The principle from *Building Effective Agents* applies directly — find the simplest thing that works, and only add complexity when it earns its place. A skill or sensor that the current model no longer needs is not heritage to preserve; it is overhead to remove. This is the honest counterweight to building more skills: the goal is the smallest harness that gets the result, not the largest.

## Honest gap map (what to build next to make this a real harness)

1. **Computational sensors per target language** — the enforcement our skills assume. Highest priority. For each repo: type-check, dependency-cruiser/ArchUnit/crate-graph wired to the hexagonal rules, test runner, coverage. Without these, the dependency rule and domain purity are *described* but not *regulated*.
2. **Self-correcting sensor messages** — make the above emit LLM-consumable fix instructions.
3. **Lifecycle wiring** — pre-commit hooks + pipeline stages that actually run the sensors at the right point.
4. **Behaviour harness** — the hard one. We have spec (discovery/agent-brief) as feedforward and TDD/e2e as feedback, but it leans on AI-generated tests, whose quality is not yet trustworthy enough to remove human verification. Treat green AI tests as necessary, not sufficient.
5. **Security role** — `security-review` now exists (threat modeling + adversarial vulnerability grid as an inferential sensor). Its computational half (secret scanning, `cargo deny`/`cargo audit`, SAST) still needs wiring into the target repo's pre-commit/CI to be regulated rather than merely described.

Until 1–3 exist in a given repo, this harness is guide-heavy and computational-sensor-light: excellent at steering the first attempt, weaker at deterministic self-correction. That is a known, named limitation — not a hidden one.
