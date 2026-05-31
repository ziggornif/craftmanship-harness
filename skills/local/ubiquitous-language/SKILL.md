---
name: ubiquitous-language
description: Establish and defend a ubiquitous language for the domain — a precise, shared glossary — and capture genuinely consequential decisions as disciplined ADRs. Use this whenever domain terms are being chosen or used, when language is fuzzy or overloaded, when modeling a domain, when naming entities/ports/use-case slices, or when a hard-to-reverse decision is being made. It sits between product discovery and architecture: discovery surfaces the concepts, this skill names them precisely, and architecture builds on those names. Also use it as a review grid to catch term drift, implementation detail leaking into the glossary, or missing/spurious ADRs. Trigger on "what do we call this", "the model", "glossary", "this term is ambiguous", "should we write this down", "ADR", "design decision" — even if no one says "ubiquitous language" or "DDD".
---

# Ubiquitous Language & Decision Records

*Inspired by Matt Pocock's `grill-with-docs` skill (MIT). Reworked for this harness and its guide+grid pattern.*

This skill has two modes. In **guide mode** it builds and defends the domain glossary and decides when a decision deserves an ADR. In **review mode** it judges whether code, briefs, and docs honor the agreed language and whether decisions are recorded with the right discipline. Read it all once; the review grid at the end is the contract.

It is the bridge between discovery and architecture. The product brief produces concepts; this skill turns them into *exact words*; the hexagonal architecture skill then uses those exact words as the names of domain types, API/SPI ports, and use-case slices. The craft payoff is one word per concept, end to end — the brief, the glossary, the folder names, and the code all say the same thing.

## The one rule everything derives from

**One concept, one word, one meaning — within a context. The glossary is the source of truth for the language, and nothing else.**

When the team's words are sloppy, the model is sloppy, and the code inherits the sloppiness. Naming is not cosmetic; an ambiguous term is an unresolved design question wearing a disguise.

## Building and defending the glossary (guide mode)

Keep the glossary in `docs/glossary.md` (path confirmed in `.harness/config.yml`). It is a **glossary, not a spec**: definitions of domain terms, devoid of implementation detail. It is not a scratchpad, not a requirements doc, not a place for decisions — those go in ADRs. If it starts accumulating "how it works", you've turned it into the wrong artifact.

During any modeling or grilling session:

- **Challenge fuzzy or overloaded terms on the spot.** When someone says "account", ask whether they mean the Customer or the login User — those are different concepts and must get different words. Propose a precise canonical term and, once agreed, record it.
- **Surface contradictions with code.** If the stated language disagrees with what the code does ("you said partial cancellation exists, but the code only cancels whole orders"), name the contradiction rather than papering over it. One of the two is wrong; resolving it is the work.
- **Probe with concrete scenarios.** When a relationship between concepts is vague, invent a specific edge-case scenario that forces precision about the boundaries. Vagueness survives abstraction; it rarely survives a concrete example.
- **Record terms as they crystallize, not in a batch at the end.** A resolved term captured immediately is correct; one reconstructed later from memory drifts.
- **Create files lazily.** No `docs/glossary.md` until the first term is worth writing down. No `docs/adr/` until the first decision earns an ADR.

## Bounded contexts (don't mistake them for conflicts)

The same word legitimately means different things in different parts of a system — "order" in fulfillment is not "order" in billing. That is not a glossary conflict; it is a **bounded context** boundary, and it is correct DDD. When a term's meaning splits cleanly along a subsystem line, give each context its own glossary under `docs/glossary/<context>.md`, with `docs/glossary/README.md` as the context map pointing to where each lives (a single-context project just uses `docs/glossary.md`). A conflict to *fix* is one word with two meanings *inside the same context*; a boundary to *honor* is one word with two meanings *across contexts*. Map each context to its area of the codebase — this aligns naturally with use-case slices and module boundaries.

## Decision records (ADRs), used sparingly

Most decisions do not need an ADR. Write one only when **all three** are true:

1. **Hard to reverse** — changing your mind later carries real cost.
2. **Surprising without context** — a future reader will ask "why on earth did they do it this way?"
3. **A genuine trade-off** — there were real alternatives and you chose one for specific reasons.

If any one is missing, skip it; a pile of ceremonial ADRs for obvious choices is noise that buries the few that matter. Conversely, a hard-to-reverse, surprising, traded-off decision left *unrecorded* is a landmine for the next person (or the next subagent). An ADR captures: the context/forces, the decision, the alternatives rejected and why, and the consequences. Keep them in `docs/adr/` (or a per-context `docs/<context>/adr/` when the decision is context-specific rather than system-wide).

## Handoff

The glossary's canonical terms are the vocabulary the architecture phase must use verbatim — for domain types, API/SPI names, and slice folder names. The ADRs are the constraints the architecture and implementation phases must respect. When you hand off, point downstream skills at `docs/glossary.md` and the relevant ADRs so the language and decisions propagate instead of being re-litigated.

## Anti-patterns to reject

- **Glossary as spec.** `docs/glossary.md` accumulating implementation detail, data shapes, or how-it-works prose.
- **Synonym drift.** Two words for one concept ("user" and "member"), or one word for two concepts, inside a single context.
- **Silent contradiction.** Code and stated language disagree and no one names it.
- **ADR ceremony.** Recording obvious, reversible, no-alternative choices — noise that hides the load-bearing ones.
- **ADR amnesia.** A hard-to-reverse, surprising, traded-off decision made with no record.
- **Context blindness.** Treating a legitimate cross-context meaning split as a naming bug, or cramming two contexts into one glossary.

---

## Review grid (review mode)

Apply to a glossary, a brief, an ADR set, or code. Each item pass/fail.

**Glossary integrity**
- [ ] `docs/glossary.md` contains domain definitions only — no implementation detail.
- [ ] Within a context, each concept has exactly one canonical term, and each term one meaning.
- [ ] Cross-context meaning splits are handled as bounded contexts (separate glossary per context under `docs/glossary/`, mapped), not as conflicts.

**Language fidelity**
- [ ] Code (types, ports, slice names) uses the glossary's canonical terms verbatim.
- [ ] The product brief and any spec use the same terms — no new synonyms introduced downstream.
- [ ] No fuzzy/overloaded term (e.g. "account", "item", "status") survives unresolved.

**Decision records**
- [ ] Every ADR present meets all three criteria (hard to reverse, surprising, real trade-off).
- [ ] No hard-to-reverse, surprising, traded-off decision is missing an ADR.
- [ ] Each ADR states context, decision, rejected alternatives, and consequences.

**Verdict**
- State **LANGUAGE SOUND** only if every box passes. Otherwise **NEEDS SHARPENING** with the failing items, each as `term/decision — what's wrong — the precise term or the question to resolve it`. Term drift caught here is cheap; caught after it's spread through the code, it's a rename across the whole slice.
