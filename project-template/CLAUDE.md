# Craft Harness

This repo uses the **craft harness** — a set of skills and a documented project structure for building software with coding agents.

## Read this first

**Start every session by reading the `orchestrator` skill.** It is the control system: phase order, exit gates, who owns the human at each moment, model routing, and the full guide/sensor map. If you don't know what to do next, the orchestrator is the answer.

## Skills installed

All skills are in `.claude/skills/`. Claude Code loads them automatically at session start. The key ones:

| Skill | When it triggers |
|---|---|
| `orchestrator` | Always — read it first |
| `project-setup` | First run in a new repo |
| `product-discovery` | Defining a product, feature, or scope |
| `ubiquitous-language` | Naming concepts, modeling the domain, writing ADRs |
| `hexagonal-architecture` | Structuring code, reviewing architecture (+ `references/rust.md` for Rust repos) |
| `agent-brief` | Writing a delegation contract for a subagent |
| `security-review` | Any backend surface, authn/authz, secrets, or dependency review |
| `prototype` | Spiking the riskiest assumption (throwaway code) |
| `handoff` | Compacting context across sessions or agents |

**superpowers** is installed as a plugin and owns the lifecycle engine: brainstorming, plan, subagent-driven-development, TDD loop, code-review, finish. Our skills plug into superpowers' ordered phases.

## Project structure

```
docs/
├── product/brief.md          # product brief (product-discovery output)
├── specs/<slice>.md          # one agent-brief per use-case slice
├── adr/                      # Architecture Decision Records
├── glossary.md               # ubiquitous language
├── architecture.md           # high-level architecture overview
├── design.md                 # design decisions
├── tech-debt.md              # technical debt log
└── security/
    ├── threat-model.md
    └── accepted-risks.md
```

Configuration (tracker, doc paths): `.harness/config.yml`

## For other agents

This `CLAUDE.md` is for Claude Code. For Codex or other SKILL.md-compatible agents, copy or symlink it as `AGENTS.md`. The skills work across agents; only the bootstrap filename differs.
