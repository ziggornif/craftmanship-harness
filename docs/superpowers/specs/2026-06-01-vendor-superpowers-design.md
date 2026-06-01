# Vendoring superpowers — design

**Date:** 2026-06-01
**Status:** approved

## Goal

Replace the `skills/vendor/superpowers/ TODO` placeholder with a real, pristine
copy of a curated subset of [obra/superpowers](https://github.com/obra/superpowers),
following **exactly the same vendoring mechanics already used for `matt-pocock`**:
verbatim copy + preserved `LICENSE` + `ORIGIN.yaml` + a row in `VENDOR.md` + a
README layout update.

This is provenance/self-containment work, governed by `skills/vendor/VENDOR.md`:
copy the *pristine* upstream (never reconstruct from memory), pin the upstream SHA,
record what we included and what we deliberately left out.

## Upstream pin

- Repo: `https://github.com/obra/superpowers`
- Commit: `6fd4507659784c351abbd2bc264c7162cfd386dc`
- Ref: `main` (commit dated 2026-05-29)
- License: MIT

## Subset — 11 skills

Chosen as the transitive closure of the skills the harness phase spine actually
invokes. The closure was computed from the cross-reference map of the cloned repo
(not from memory).

| Skill | Reason |
|---|---|
| `brainstorming` | phase 1 — intent |
| `writing-plans` | phase 4 |
| `executing-plans` | pulled in by writing-plans + subagent-driven-development |
| `subagent-driven-development` | phase 5 |
| `test-driven-development` | TDD loop, phase 5 |
| `systematic-debugging` | debug (superpowers owns this per matt-pocock notes) |
| `requesting-code-review` | phase 6 |
| `receiving-code-review` | other half of the review loop (handling feedback) |
| `finishing-a-development-branch` | phase 7 |
| `using-git-worktrees` | dependency of executing/subagent/finishing |
| `verification-before-completion` | dependency of debugging + review |

Each skill folder is copied **verbatim** — including its `scripts/`, prompt files,
references, and upstream artifacts (e.g. `systematic-debugging/CREATION-LOG.md`,
`test-pressure-*.md`). Pristine means pristine.

## Excluded — 3 (documented in ORIGIN.yaml, mirroring matt-pocock's "NOT vendored")

- `using-superpowers` — bootstrap/router, injected by the plugin's **SessionStart
  hook**, not a phase-spine step.
- `dispatching-parallel-agents` — generic fan-out; the harness delegates through
  `subagent-driven-development` + local `agent-brief`.
- `writing-skills` — skill-authoring meta-tool; not used to *run* a project through
  the spine.

## Resulting layout

```
skills/vendor/superpowers/
├── ORIGIN.yaml          # real SHA, included[], "NOT vendored" section, local_patches: none
├── LICENSE              # MIT, obra/superpowers, verbatim
└── <11 skill folders, copied verbatim>
```

## Doc edits

- `skills/vendor/VENDOR.md` registry table: replace the
  `superpowers | … | _TBD_ | _TBD_` row with the real pinned SHA (`6fd4507`) and
  vendored date (`2026-06-01`).
- `README.md` layout block: replace the
  `superpowers/  TODO: vendor obra/superpowers …` line with a real description
  (same shape as the existing `matt-pocock/` line).

## Known side effect (intentional, faithful to matt-pocock)

`bin/link-skills.sh` symlinks every folder containing a `SKILL.md`, so these 11
vendored skills will be linked into `.claude/skills/` exactly like the matt-pocock
ones. If the superpowers **plugin** is also installed, the same skills exist from
two sources. We keep behaviour identical to matt-pocock — `link-skills.sh` is **not**
modified. The vendored copy serves provenance and self-contained installs.

## Out of scope

- Vendoring upstream `hooks/`.
- Replacing the plugin install path.
- Changing `link-skills.sh` logic.
