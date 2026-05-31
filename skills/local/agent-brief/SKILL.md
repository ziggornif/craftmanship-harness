---
name: agent-brief
description: Write the durable, tracker-agnostic contract a subagent implements one unit of work from. Use this when decomposing a plan into delegable tasks, when handing a use-case slice to an implementation subagent, or when turning an opportunity/PRD into something an autonomous agent can execute without further clarification. The brief is the authoritative spec; any original discussion is just context. Also use it as a review grid to judge whether a task is actually ready to delegate. Trigger on "delegate this", "ready for agent", "write the spec for", "hand this off", "break this down into tasks" — even if no tracker or "brief" is mentioned.
---

# Agent Brief

*The format is adapted from Matt Pocock's `triage` AGENT-BRIEF (MIT), decoupled from any issue tracker.*

This skill has two modes. In **guide mode** it writes the brief. In **review mode** it judges whether a unit of work is delegable. Read it all once; the review grid at the end is the contract.

A brief is the **authoritative contract for one unit of work** that a subagent will implement with zero prior context. It is tracker-agnostic: the same artifact is valid whether your orchestrator hands it to a subagent in memory or publishes it as a GitHub/GitLab issue (see the `project-setup` skill for how the tracker is chosen). The artifact is the contract; where it's stored is an adapter detail.

In this harness a brief corresponds to **roughly one vertical use-case slice**. The pipeline is: discovery surfaces opportunities → architecture turns each into a slice → each slice becomes one brief → one subagent owns it. Keeping that one-to-one makes delegation clean and review tractable.

## The one rule everything derives from

**Specify behavior and outcome, durably — not implementation, and not file coordinates.** The brief may be picked up minutes or weeks later, against a codebase that has since moved. A brief written against today's file layout is a landmine; a brief written against interfaces and behavior survives.

## Principles

- **Durability over precision.** Describe interfaces, types, and behavioral contracts — name the types and signatures the agent should look for or change. Never reference file paths or line numbers; never assume the current implementation structure persists. The agent will explore fresh.
- **Behavioral, not procedural.** Say *what* the system should do, not *how* to build it. "The `Order` aggregate should reject a second confirmation" — not "add an if-check in the confirm method". Implementation is the subagent's job.
- **Complete, testable acceptance criteria.** The agent must know when it's done. Each criterion is concrete and independently verifiable — a thing you could write a test for. "Triage returns issues that passed classification", not "triage works correctly".
- **Explicit scope boundaries.** State what is *out* of scope. This is the single most effective guard against gold-plating and against the agent wandering into adjacent features.
- **Reference, don't duplicate.** Link upstream artifacts by path: product brief at `docs/product/brief.md`, relevant ADRs at `docs/adr/`, glossary at `docs/glossary.md`. The brief carries what's specific to this unit; shared context lives where it already is. Save the brief itself to `docs/specs/<slice-name>.md`.

## Vocabulary and interface terms

State key interfaces in the project's domain language and in API/SPI terms, using the glossary (`docs/glossary.md`) vocabulary verbatim. A brief that invents new words for existing concepts forces the subagent to guess the mapping. If the work touches a hard-to-reverse decision, link the relevant ADR rather than re-deciding it.

## Template

```markdown
## Agent Brief

**Category:** feature | bug
**Summary:** one line — what needs to happen

**Slice / context:** which use-case slice this is, and the status quo it builds on
(for a bug: the broken behavior; for a feature: what exists today)

**Desired behavior:**
What should be true when the work is done. Be explicit about edge cases and
error conditions. Behavioral, not procedural.

**Key interfaces:** (in glossary + API/SPI terms — no file paths)
- `TypeName` — what changes and why
- `apiPort.useCase()` — input/output contract
- `SpiName` — the outbound capability this needs, if any

**Acceptance criteria:**
- [ ] concrete, testable criterion
- [ ] concrete, testable criterion

**Out of scope:**
- what must NOT be touched or added in this unit

**References:**
- Product brief: `docs/product/brief.md`
- ADRs: `docs/adr/`
- Glossary: `docs/glossary.md`
```

## Provenance hygiene

When a brief is published to a tracker by the harness rather than written by a human, prefix it with a one-line disclaimer noting it was AI-generated, so reviewers know its origin. This is honesty about provenance, not a disclaimer of responsibility.

## Anti-patterns to reject

- **File-coordinate spec.** "Edit `src/foo.ts` line 42" — stale the moment anyone refactors.
- **Procedural spec.** Telling the agent the steps instead of the outcome; pre-deciding the implementation.
- **Vague done.** "Make it work", "handle errors properly" — no testable criterion.
- **No scope fence.** No out-of-scope list, so the agent gold-plates or drifts.
- **Restated context.** Copying the whole PRD/ADR into the brief instead of linking it; now there are two copies to drift apart.
- **New vocabulary.** Inventing terms the glossary already names.

---

## Review grid (review mode — "is this delegable?")

Apply to a brief before it goes to a subagent. Each item pass/fail.

**Durability**
- [ ] No file paths, no line numbers, no assumption about current structure.
- [ ] Interfaces/types/contracts are named so the agent can locate them after a refactor.

**Behavior & done**
- [ ] States desired behavior (the what), not implementation steps (the how).
- [ ] Edge cases and error conditions are explicit.
- [ ] Every acceptance criterion is concrete and independently testable.

**Scope & traceability**
- [ ] Out-of-scope is explicit.
- [ ] Maps to ~one use-case slice (not a multi-slice mega-task).
- [ ] Key interfaces use glossary + API/SPI vocabulary; upstream artifacts are linked, not duplicated.
- [ ] If the slice has a frontend/UI surface: `docs/design.md` is non-empty before this brief is delegated.

**Verdict**
- State **READY TO DELEGATE** only if every box passes. Otherwise **NOT DELEGABLE** with the failing items, each as `field — what's missing — the fix`. A brief that fails here produces a subagent that guesses, and a guessing subagent is slower to fix than to brief properly.
