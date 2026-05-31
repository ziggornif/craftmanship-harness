# Craft Harness

An outer **harness** (in the harness-engineering sense — *Agent = Model + Harness*) for building new software projects with coding agents, leashed to a **hexagonal + API/SPI + vertical-slice** topology and craft/DDD principles. It rides on a builder harness (Claude Code, Codex, …) and layers a system of **guides** (feedforward) and **sensors** (feedback) on top.

Mental model and vocabulary follow Birgitta Böckeler, *Harness Engineering for coding agent users* (martinfowler.com, 2026).

## Read order

Start with `skills/local/orchestrator/SKILL.md` — it is the control system: phase order, exit gates, who owns the human, model routing by reasoning tier, lifecycle placement of checks, the steering loop, and an honest gap map.

## Layout

```
skills/
├── vendor/                         external skills, copied in with provenance
│   ├── VENDOR.md                   registry + re-sync policy (pin SHA, replay patches)
│   ├── superpowers/                TODO: vendor obra/superpowers (brainstorm + ordered phases)
│   └── matt-pocock/                handoff, prototype (MIT, pinned) + LICENSE + ORIGIN.yaml
└── local/                          our own skills (guide + review-grid pattern)
    ├── orchestrator/               control system — read first
    ├── project-setup/              project composition root: tracker/CLI, glossary/ADR locations
    ├── product-discovery/          PM/PO: problem, user, outcomes, riskiest assumption
    ├── ubiquitous-language/        glossary + disciplined ADRs (inspired by Pocock grill-with-docs)
    ├── hexagonal-architecture/     API/SPI, vertical slicing, domain purity, test philosophy
    │   └── references/rust.md       Rust computational sensors + layout + decisions
    ├── agent-brief/                tracker-agnostic delegation contract (format adapted from Pocock)
    └── security-review/            threat modeling + adversarial vulnerability grid
```

## Phase spine (see orchestrator for detail)

`project-setup → product-discovery → ubiquitous-language → hexagonal-architecture → plan + agent-brief → subagent dev (TDD) → review → finish`, with `prototype` and `handoff` invoked on demand.

## Division of labour

- **superpowers** owns the ordered lifecycle engine: brainstorming, plan, subagent-driven-development, the TDD loop, debugging, code-review, finish.
- **Local craft skills** own the domain layer: discovery, language, architecture, delegation contracts, orchestration.
- **Vendored Pocock skills** fill two gaps: `handoff` (cross-agent context) and `prototype` (throwaway spikes).

## Provenance & licensing

All vendored skills are MIT and copied pristine with their `LICENSE` preserved and an `ORIGIN.yaml` pinning the upstream commit. Updates are manual diff-and-replay against the pinned SHA — see `skills/vendor/VENDOR.md`. Local skills credit any external inspiration inline.

## Known limitation

This harness is currently strong on **inferential feedforward** (skills) and present on **inferential feedback** (review grids), but **thin on computational sensors** (the deterministic enforcement — type-checkers, dependency-cruiser/ArchUnit, tests wired to the rules). That is the priority work to make it a complete harness rather than a methodology. The orchestrator's gap map lists it explicitly.
