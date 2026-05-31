---
name: ci-setup
description: Generate and wire the CI pipeline for the project — lint, formatter, tests, e2e, advisory scans, and the architectural sensors from the hexagonal harness. Use this after architecture is confirmed and the tracker is known (GitHub or GitLab). It reads .harness/config.yml for the tracker kind and generates the appropriate CI config (.github/workflows/ci.yml or .gitlab-ci.yml), plus any supporting scripts (e.g. tools/check-domain-purity.sh for Rust). Also use it as a review grid to check whether an existing CI is complete and wires all the harness sensors. Trigger on "set up CI", "add a pipeline", "github actions", "gitlab ci", "add lint/tests to CI", or when the orchestrator reaches phase 3c.
---

# CI Setup

This skill has two modes. In **guide mode** it generates the CI config and supporting scripts from scratch. In **review mode** it checks whether an existing CI pipeline is complete and wires all the sensors the harness expects. Read it all; the review grid at the end is the contract.

This is the skill that **closes the computational-sensor gap**: everything `hexagonal-architecture/references/<lang>.md` describes as a sensor (domain-purity check, type-checker, linter, advisory scan) gets created here as a file that actually runs in CI. The sensors go from *described* to *regulated*.

## What to read first

Check `.harness/config.yml` for `tracker.kind` (github / gitlab / local). If local, skip this skill — no remote CI to generate. Then detect the project language from the codebase. Both determine what to generate.

## Jobs — the standard pipeline

Always run jobs in this order, fast-to-slow, fail-fast:

```
format → lint → build → test-unit → test-integration → test-e2e → advisory
```

- **format** — formatter check (fail if code isn't formatted; never auto-commit in CI)
- **lint** — linter with warnings-as-errors
- **build** — clean build, no warnings
- **test-unit** — domain + use-case tests (fast, no I/O)
- **test-integration** — SPI adapter tests against real dependencies (Testcontainers or service containers)
- **test-e2e** — critical journeys through the driving adapters
- **advisory** — dependency vulnerability and license scan

Add the **architectural sensor** as part of lint or as its own job: the check that enforces the dependency rule mechanically (domain-purity script for Rust, dependency-cruiser for TS, ArchUnit for Java). This is the most important sensor in the harness — it is what makes "the domain depends on nothing" a CI failure rather than a review comment.

## Rust + GitHub Actions

Generate `.github/workflows/ci.yml` and `tools/check-domain-purity.sh`.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:

env:
  CARGO_TERM_COLOR: always
  RUST_BACKTRACE: 1

jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --all -- --check

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - uses: Swatinem/rust-cache@v2
      - run: cargo clippy --all-targets --all-features -- -D warnings
      - name: Domain purity check
        run: bash tools/check-domain-purity.sh

  test-unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test --workspace --lib

  test-integration:
    runs-on: ubuntu-latest
    services:
      postgres:                     # adjust or remove if not using Postgres
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test --workspace --test '*'

  test-e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test --workspace --test 'e2e_*'   # adjust test naming convention

  advisory:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - uses: taiki-e/install-action@cargo-deny
      - run: cargo deny check
```

Generate `tools/check-domain-purity.sh` alongside — the domain-purity sensor from `hexagonal-architecture/references/rust.md`:

```bash
#!/usr/bin/env bash
# Enforce: the domain crate has no forbidden dependencies.
# Rule: domain may only depend on what's in ALLOW. Anything else is a HEXAGONAL VIOLATION.
# See: skills/local/hexagonal-architecture/references/rust.md
set -euo pipefail
ALLOW="thiserror|uuid|time|rust_decimal|serde"  # extend as needed, keep minimal
BAD=$(cargo tree -p domain --prefix none --no-dedupe 2>/dev/null \
      | sort -u | grep -vE "^(domain|std|core|alloc| *$|${ALLOW})" || true)
if [ -n "$BAD" ]; then
  echo "HEXAGONAL VIOLATION — domain crate has forbidden dependencies:"
  echo "$BAD" | sed 's/^/  - /'
  echo ""
  echo "Rule: the domain depends on nothing framework/IO (hexagonal-architecture SKILL, 'Domain purity')."
  echo "Why: a framework type in the domain couples business rules to infrastructure."
  echo "Fix: move the capability behind an SPI trait in ports/spi/, implement in an adapter crate,"
  echo "     then remove the forbidden dep from crates/domain/Cargo.toml."
  exit 1
fi
echo "Domain purity: OK"
```

Make it executable: `chmod +x tools/check-domain-purity.sh`.

## Rust + GitLab CI

Generate `.gitlab-ci.yml` with equivalent stages. Same jobs, GitLab syntax:

```yaml
# .gitlab-ci.yml
stages: [format, lint, test, advisory]

default:
  image: rust:latest
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths: [target/]

format:
  stage: format
  script: cargo fmt --all -- --check

lint:
  stage: lint
  script:
    - rustup component add clippy
    - cargo clippy --all-targets --all-features -- -D warnings
    - bash tools/check-domain-purity.sh

test-unit:
  stage: test
  script: cargo test --workspace --lib

test-integration:
  stage: test
  services:
    - postgres:16          # adjust or remove
  variables:
    POSTGRES_PASSWORD: test
  script: cargo test --workspace --test '*'

test-e2e:
  stage: test
  script: cargo test --workspace --test 'e2e_*'

advisory:
  stage: advisory
  script:
    - cargo install cargo-deny --locked
    - cargo deny check
```

## What to adjust project-by-project

- The `ALLOW` list in `check-domain-purity.sh` — update as you add legitimate domain deps.
- The `postgres` service — replace or remove based on your SPI adapters.
- The e2e test naming pattern (`e2e_*`) — match your test file convention.
- Add secret scanning if the repo is public: `gitleaks` or GitHub secret scanning (enable in repo settings).

## Anti-patterns to reject

- **Auto-formatting in CI.** CI checks, never writes. Commits from CI create noise and mask real failures.
- **No fail-fast.** Slow jobs (e2e, advisory) run in parallel with fast ones before fast ones finish — wastes minutes on doomed builds.
- **Missing architectural sensor.** The domain-purity check and/or dep-cruiser/ArchUnit absent from CI. The dependency rule then lives only in review comments.
- **Integration and unit tests in the same job.** Integration tests need services (Postgres, Redis…) and are slow; mixed jobs bloat unit test time and obscure which layer is broken.
- **Advisory scan only on schedule.** New CVEs land against unchanged code; scanning only on push or PR misses them between runs. Add a weekly/daily scheduled trigger.

---

## Review grid (review mode)

Apply to an existing CI configuration. Each item pass/fail.

**Coverage**
- [ ] Format check job present and fails on unformatted code.
- [ ] Lint job present with warnings-as-errors.
- [ ] Unit tests run (domain + use-case, fast, no external services).
- [ ] Integration tests run against real dependencies (service containers or Testcontainers).
- [ ] E2e tests run on critical journeys.
- [ ] Advisory/vulnerability scan present.

**Architectural sensors**
- [ ] Domain-purity check (or equivalent) runs in CI and fails on a forbidden domain dep.
- [ ] Sensor failure message names the rule, the why, and the fix — not just "violation".

**Pipeline hygiene**
- [ ] Jobs run fast-to-slow; pipeline fails fast on the cheapest failure.
- [ ] CI never auto-commits or auto-formats.
- [ ] Rust cache configured (Swatinem/rust-cache or equivalent) to keep build times sane.
- [ ] Advisory scan also runs on a schedule, not only on push.

**Verdict**
- State **CI SOUND** only if every box passes. Otherwise **CI INCOMPLETE** with each failing item as `job — what's missing — smallest fix`. A CI that skips the architectural sensor is a harness with a sensor gap — the rules are described but not regulated.
