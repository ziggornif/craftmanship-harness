# Craftmanship Harness

An outer **harness** for building new software projects with coding agents, leashed to a **hexagonal + API/SPI + vertical-slice** topology and craft/DDD principles. It rides on a builder harness (Claude Code, Codex, …) and layers a system of **guides** (feedforward) and **sensors** (feedback) on top.

Mental model and vocabulary follow Birgitta Böckeler, *Harness Engineering for coding agent users* (martinfowler.com, 2026). The generator/evaluator pattern follows the Anthropic engineering article on harness design (anthropic.com/engineering, 2026).

---

## Getting started

### 1 — Install the lifecycle engine

In Claude Code, install superpowers (it owns brainstorming, plan, subagent-driven-development, TDD loop, code-review, finish):

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

### 2 — Bootstrap a new project

```bash
# Copy the project template into your target repo
cp -r project-template/. ~/your-repo/

# Link the harness skills flat into .claude/skills/
bash bin/link-skills.sh ~/your-repo
```

### 3 — Launch

```bash
cd ~/your-repo
claude
```

Then tell Claude your intent:

> "I want to create [project]. Launch the harness."

Example :

> "I want to create a tic-tac-toe game in Rust with a hexagonal architecture. Launch the harness."

Claude reads `CLAUDE.md` on startup and the orchestrator takes over from there.

---

## Layout

```
bin/
└── link-skills.sh              symlinks skills flat into .claude/skills/ (Claude Code discovery)

project-template/               copy this into your target repo to bootstrap it
├── CLAUDE.md                   agent entry point — tells Claude to read the orchestrator first
├── .harness/config.yml         tracker, doc paths, label vocabulary
└── docs/                       project documentation scaffold
    ├── product/brief.md        product-discovery output
    ├── specs/                  one agent-brief per use-case slice
    ├── adr/                    Architecture Decision Records
    ├── glossary.md             ubiquitous language
    ├── architecture.md
    ├── design.md
    ├── tech-debt.md
    └── security/

skills/
├── vendor/                     external skills, copied in with provenance
│   ├── VENDOR.md               registry + re-sync policy (pin SHA, replay patches)
│   ├── superpowers/            TODO: vendor obra/superpowers (brainstorm + ordered phases)
│   └── matt-pocock/            handoff, prototype — MIT, SHA pinned, ORIGIN.yaml
└── local/                      craft skills (guide + review-grid pattern throughout)
    ├── orchestrator/           control system — read first
    ├── project-setup/          project composition root: tracker/CLI, docs scaffold
    ├── product-discovery/      PM/PO: problem, user, outcomes, riskiest assumption
    ├── ubiquitous-language/    glossary + disciplined ADRs
    ├── hexagonal-architecture/ API/SPI, vertical slicing, domain purity, test philosophy
    │   └── references/rust.md  Rust computational sensors, workspace layout, decisions
    ├── agent-brief/            tracker-agnostic delegation contract
    ├── security-review/        threat modeling + adversarial vulnerability grid
    └── ci-setup/               CI pipeline generator + sensor wiring (GitHub Actions / GitLab CI)
```

---

## Phase spine

The harness routes to one of three **entry topologies** before phase 0: **new-product** (the full spine below), **new-feature** (existing codebase — reduced spine, architecture analyzes the existing code first, conditional UX/security), and **bugfix** (minimal spine — root-cause-first, minimal-fix rule). See the orchestrator for the routing table and the reduced spines.

```
0. project-setup            choose tracker/CLI, scaffold docs/             [once per repo]
1. product-discovery        problem, user, outcomes, riskiest assumption   gate: READY FOR ARCHITECTURE
   (prototype)              optional: spike the riskiest assumption cheaply
2. ubiquitous-language      sharpen terms; ADRs for hard calls             gate: LANGUAGE SOUND
3. hexagonal-architecture   slices, API/SPI, per-slice structure           gate: ACCEPT
3b. design (if UI/frontend) docs/design.md via prototype (UI branch)       gate: design.md non-empty
3c. ci-setup (if GitHub/GitLab) generate CI config + sensor scripts        gate: CI SOUND
4. plan + agent-brief       superpowers plan → one brief per slice         gate: READY TO DELEGATE
5. subagent dev (TDD)       superpowers subagent-driven-development        gate: tests green + grids pass
6. review                   computational sensors first, then inferential  gate: all sensors green
7. finish                   superpowers finish-the-branch
   handoff                  cross-cutting: compact context between agents
```

See `skills/local/orchestrator/SKILL.md` for the full control system: exit gates, who owns the human, model routing by reasoning tier, evaluator-separation rule, steering loop.

---

## Division of labour

| What | Who |
|---|---|
| Lifecycle engine (brainstorm → plan → TDD → review → finish) | superpowers plugin |
| Craft/domain layer (discovery, language, architecture, security, briefs) | Local skills |
| Throwaway spikes + context handoff | Vendored Pocock skills |

---

## Sources

- Birgitta Böckeler — [Harness Engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) (martinfowler.com, 2026)
- Anthropic Engineering — [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (2026)
- Jesse Vincent — [superpowers](https://github.com/obra/superpowers) — MIT
- Matt Pocock — [skills](https://github.com/mattpocock/skills) — MIT

---

## Known limitation

This harness is strong on **inferential feedforward** (skills as guides) and **inferential feedback** (review grids as evaluator contracts), but **thin on computational sensors** — the deterministic enforcement (dependency-cruiser/ArchUnit/crate-graph, type-checkers, tests wired to architectural rules). `references/rust.md` documents the Rust sensors to wire; other languages need equivalent setup. Until computational sensors are in place in the target repo, the architectural rules are *described* but not *regulated*. The orchestrator's gap map tracks what remains.
