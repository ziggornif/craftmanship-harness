---
name: project-setup
description: Bootstrap the harness's project-level configuration the first time it runs in a repo — most importantly, which issue tracker to use (GitHub via gh, GitLab via glab, or local files) and whether its CLI is installed and authenticated. Also records where the glossary and ADRs live and the label vocabulary, so downstream skills (agent-brief publishing, handoff, triage) read one config instead of re-asking. Use at the start of a new project, on first run in an unconfigured repo, or when the user says "set up the harness here", "configure the tracker", "init the project". Trigger before any skill that would publish to a tracker.
---

# Project Setup

This is the **project-level composition root** of the harness: choose the pluggable adapters once, record them, and let every downstream skill read the choice. The most consequential choice is the issue tracker, because the brief and handoff formats are tracker-agnostic by design — the tracker is the adapter that makes them concrete.

Run this once per repo. It is human-in-the-loop and should be fast: ask only what can't be detected, detect the rest.

## What to establish

1. **Issue tracker + CLI.** Ask which tracker this project uses:
   - **GitHub** → `gh` CLI
   - **GitLab** → `glab` CLI
   - **Local / none** → briefs and handoffs live as files under `.harness/` (no tracker)

   Detect before asking where possible: a `git remote` pointing at github.com or gitlab.com is a strong default — propose it and let the user confirm rather than asking cold. Then **verify the CLI is installed and authenticated** (`gh auth status` / `glab auth status`). If it isn't, say so plainly and give the one-line fix (install + auth login); do not assume it will work later.

2. **Glossary and ADR locations.** Note where the glossary (`docs/glossary.md`, or `docs/glossary/<context>.md` for multiple bounded contexts) and `docs/adr/` live, or that they don't exist yet (the `ubiquitous-language` skill creates them lazily). Downstream skills read the glossary path from this config, not from a hardcoded location.

3. **Label vocabulary (tracker only).** The harness uses canonical role names (`ready-for-agent`, `needs-info`, `bug`, `enhancement`, …); the actual label strings in the tracker may differ. Record the mapping so the tracker adapter stays swappable — canonical names in the harness, project-specific strings at the edge.

## Output: `.harness/config.yml`

Create lazily — only once there's something to record. Keep it small and declarative.

```yaml
tracker:
  kind: gitlab            # github | gitlab | local
  cli: glab               # gh | glab | null
  project: group/repo     # tracker project identifier, if any
  authenticated: true     # result of the auth check at setup time
docs:
  glossary: docs/glossary.md   # ubiquitous language — path stored here so skills find it via config
  adr_dir: docs/adr            # Architecture Decision Records
  specs_dir: docs/specs        # agent-briefs per slice
  product_brief: docs/product/brief.md
  threat_model: docs/security/threat-model.md
  accepted_risks: docs/security/accepted-risks.md
  architecture: docs/architecture.md
  design: docs/design.md
  tech_debt: docs/tech-debt.md
labels:                    # canonical role -> actual tracker label
  ready-for-agent: ready-for-agent
  needs-info: needs-info
  bug: bug
  enhancement: enhancement
```

## Scaffold docs/

On first setup, copy the project-template `docs/` structure into the repo root:

```
docs/
├── product/brief.md         # product-discovery writes here
├── specs/                   # one agent-brief per slice
├── adr/                     # ubiquitous-language writes here (sparingly)
├── glossary.md              # ubiquitous language (path recorded in config, read from there by all skills)
├── architecture.md          # hexagonal-architecture high-level overview
├── design.md                # design decisions (prototype UI branch output)
├── tech-debt.md             # running debt log
└── security/
    ├── threat-model.md      # security-review guide mode output
    └── accepted-risks.md    # deliberate accepted risks
```

Create only; never overwrite existing files — the human may have written content there already.

## How downstream skills use it

- **agent-brief** writes the same brief regardless of `tracker.kind`. Publishing is the adapter: `local` → write to `.harness/briefs/`; `github` → `gh issue create`; `gitlab` → `glab issue create`, applying the mapped labels. The brief content never changes — only the sink.
- **handoff** references tracker artifacts by URL when a tracker exists, or by file path under `.harness/` when local.
- Any **triage**-style flow maps canonical roles through `labels` before touching the tracker.

## Principle

Keep the tracker choice at this one edge. No downstream skill should hardcode `gh` or `glab` or branch on the tracker in its own logic beyond the thin publish step — exactly as an SPI adapter is selected once at the composition root and the domain never knows which one it got. If you find tracker-specific commands spreading into the brief or handoff skills, that's the same leak the hexagonal review grid catches, one level up.
