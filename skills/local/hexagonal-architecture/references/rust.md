# Rust — computational sensors for the hexagonal rules

This is the Rust-specific layer for `hexagonal-architecture/SKILL.md`. It does two things: record the decisions that Rust forces, and wire the **computational sensors** that turn the skill's rules from *described* into *regulated*. Read it when the target repo is Rust. It does not re-teach Rust; it captures what's load-bearing for the architecture and the harness.

## Decisions Rust forces (settle these once)

- **One `domain` crate with a module per slice**, not one crate per slice — until a slice grows big enough to justify its own crate. The crate graph enforces the dependency rule at the workspace level; intra-crate slice isolation is enforced by a check (below), not by the compiler. Promote a module to its own crate only when it earns it.
- **Ports are traits** in the domain crate (`ports::api`, `ports::spi`). Adapters are structs in separate crates that implement (SPI) or call (API) those traits. The orphan rule is a non-issue: an adapter owns the struct it implements the trait for.
- **`dyn Trait` at the composition root by default**, generics only where a hot path or a strong type relationship justifies the verbosity. Dynamic dispatch keeps wiring in `main` simple and keeps the slice count of generic parameters from leaking everywhere. This is a deliberate trade of a negligible vtable cost for legibility.
- **SPI stubs live in the domain crate**, behind a `stubs` feature (or `#[cfg(test)]` plus a `pub(crate)` test module): hand-written test doubles implementing the SPI traits, returning the datasets that exercise each business case. Keeping them in-crate preserves domain hermeticity (the no-mocks rule from the SKILL).

## Workspace layout

```
crates/
├── domain/                 # zero framework deps; modules per slice + ports + stubs
│   ├── src/
│   │   ├── place_order/     # one module per use-case slice
│   │   │   ├── mod.rs
│   │   │   ├── model.rs
│   │   │   └── ports/{api.rs, spi.rs}
│   │   ├── shared/          # minimal shared kernel
│   │   └── ports/spi/stubs/ # test doubles, behind `stubs` feature
│   └── Cargo.toml           # dependency allowlist is the sensor target
├── adapter-postgres/        # implements SPI traits; depends on domain
├── adapter-http/            # driving adapter; calls API traits; depends on domain
└── app/                     # composition root: main.rs wires adapters via dyn Trait
```

## Sensors, by quadrant and lifecycle

### Computational feedforward
- **The crate graph itself.** `domain` lists no adapter crates and no framework crates in `Cargo.toml`; the compiler then makes it *impossible* to use them. This is the cheapest, strongest sensor you have — lean on it.

### Computational sensors — pre-commit (fast, every change)
- **`cargo check` / `cargo build`** — the dependency rule, free.
- **`cargo clippy --all-targets -- -D warnings`** — deny on warnings. Add `-W clippy::pedantic` selectively. Clippy is your lint sensor.
- **Domain dependency allowlist check** — the structural sensor that catches the real failure mode (someone adds `tokio`/`sqlx`/`axum` to the domain crate). Cargo won't stop that; this check does. Example, emitting an LLM-shaped message:

  ```bash
  # tools/check-domain-purity.sh — run in pre-commit
  ALLOW="thiserror|uuid|time|rust_decimal"   # the only deps domain may have
  BAD=$(cargo tree -p domain --prefix none --no-dedupe \
        | sort -u | grep -vE "^(domain|std|core|alloc| *$|${ALLOW})")
  if [ -n "$BAD" ]; then
    echo "HEXAGONAL VIOLATION — domain crate has forbidden dependencies:"
    echo "$BAD" | sed 's/^/  - /'
    echo "Rule: the domain depends on nothing framework/IO (see hexagonal-architecture SKILL, 'Domain purity')."
    echo "Why: a framework type in the domain couples business rules to infrastructure and breaks the dependency rule."
    echo "Smallest fix: move the offending capability behind an SPI trait in ports/spi, implement it in an adapter crate, and remove the dep from crates/domain/Cargo.toml."
    exit 1
  fi
  ```

- **Slice isolation check** — no slice module `use`s a sibling slice. A grep-level sensor is enough to start:

  ```bash
  # flag `use crate::<otherslice>` from within a slice module; allow crate::shared
  ```
  When this matters more, promote it to a [dylint](https://github.com/trailofbits/dylint) custom lint — dylint is the Rust way to write a custom architectural linter whose message can carry the rule, the why, and the fix (a self-correcting sensor).

### Computational sensors — pre-merge (heavier)
- **`cargo test --workspace`** — domain unit tests (pure), use-case tests via SPI stubs, adapter integration tests using the **`testcontainers`** crate against a real Postgres, e2e through the HTTP driving adapter on critical journeys.
- **`cargo llvm-cov --workspace`** — coverage; gate on a threshold for the domain/use-case crates, not on adapters.
- **`cargo deny check`** — bans, license policy, and **RustSec advisories** (this doubles as a security sensor — see `security-review`). Pair with `cargo audit`.

### Continuous drift
- Dead-code: `cargo machete` / `-W dead_code`. Unused-dep detection. Periodic `cargo audit` for newly disclosed advisories.

## Self-correcting messages — the rule

Every sensor above must fail *loud and instructive*: name the rule, the why (point at the SKILL), and the smallest fix — like the allowlist script does. A sensor that only says "violation" creates a human ticket; a sensor that says "move X behind an SPI" creates a self-correction the implementing agent can act on without you.

## What the review grid's "enforced mechanically" item maps to here

When the hexagonal review grid asks "dependency direction is enforced mechanically", in Rust that means: the crate graph (build) + the domain allowlist check + the slice-isolation check are all present and wired into pre-commit/CI. If they aren't in the target repo, that grid item fails regardless of how clean the code looks.
