# Vendored skills — provenance & license registry

External skills are **copied in** (not submoduled) so the harness stays self-contained
and every file is under our control. The trade-off is that updates are manual. This file
is the source of truth for *where each thing came from* and *what we changed*.

## Policy

1. **Never edit a vendored skill in place without recording it.** Vendor the pristine
   upstream version first (commit it untouched), then make local edits in a *separate*
   commit. That way `git log` shows exactly what diverges from upstream.
2. **Preserve the upstream LICENSE file** inside each vendored package. For MIT/BSD/Apache
   this is a license obligation, not optional.
3. **Pin the upstream commit SHA**, not just the repo URL. Updating = fetch the new
   upstream, diff against the pinned SHA, replay our local patches, bump the SHA here.
4. One folder per upstream source under `vendor/<name>/`, each with its own `ORIGIN.yaml`.

## Layout

```
skills/
├── vendor/                     # external, copied in
│   ├── VENDOR.md               # this file
│   └── <name>/
│       ├── ORIGIN.yaml         # provenance for this package (see template below)
│       ├── LICENSE             # upstream license, preserved verbatim
│       └── skills/...          # the copied skill files
└── local/                      # our own skills (full ownership, no provenance needed)
    └── hexagonal-architecture/
        └── SKILL.md
```

## ORIGIN.yaml template

```yaml
name: superpowers
upstream_repo: https://github.com/obra/superpowers
upstream_commit: <sha>            # the exact commit vendored — pin it, don't leave blank
upstream_ref: main                # tag or branch the sha came from
license: MIT
copyright: "Copyright (c) 2025 Jesse Vincent"
vendored_on: 2026-05-30
vendored_by: matthieu
# Which subset was copied (we don't always need the whole repo)
included:
  - skills/brainstorming
  - skills/writing-plans
  - skills/subagent-driven-development
  - skills/test-driven-development
  - skills/requesting-code-review
# Local modifications applied AFTER vendoring the pristine copy.
# Keep this list honest — it's what you replay when updating upstream.
local_patches:
  - "none yet"
notes: >
  MIT-licensed. Recommended split: strong-reasoning model for brainstorming/planning,
  cheaper/local model for implementation subagents.
```

## Registry

| Package      | Upstream                                  | License | Pinned SHA | Vendored   |
|--------------|-------------------------------------------|---------|------------|------------|
| superpowers  | github.com/obra/superpowers               | MIT     | _TBD_      | _TBD_      |
| matt-pocock  | github.com/mattpocock/skills              | MIT     | e3b90b5 (handoff, prototype); 89d370d (codebase-design) | 2026-05-30 / 2026-07-10 |
| _(add rows as you vendor more)_           |         |            |            |

## Updating a vendored package (manual re-sync)

```sh
# 1. clone upstream at a fresh ref into a temp dir
git clone --depth 1 https://github.com/obra/superpowers /tmp/superpowers-new

# 2. see what changed upstream since your pinned SHA
git -C /tmp/superpowers-new log --oneline <pinned_sha>..HEAD

# 3. copy the new version over the pristine vendored copy (NOT over your patched one)
#    then replay your local_patches from ORIGIN.yaml, resolve conflicts by hand

# 4. update ORIGIN.yaml: bump upstream_commit, vendored_on, and local_patches
```

The point of pinning the SHA and listing `local_patches` is that "update by hand" stays a
*diff-and-replay*, not a "rewrite from memory and hope". That's the whole reason to vendor
rather than fork-and-forget.
