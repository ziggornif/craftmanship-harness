---
name: security-review
description: Threat-model a design and review code adversarially for security risks and vulnerabilities. Use this during architecture (to find trust boundaries and entry points before code exists) and again as a separate, skeptical review gate before merge. It is the security role of the harness: an inferential sensor (threat modeling + vulnerability grid) backed by computational sensors (dependency/advisory scanning, secret scanning, SAST). Trigger whenever the work exposes an entry point, handles untrusted input, touches authn/authz, secrets, crypto, file/network/DB access, or dependencies — and whenever someone asks "is this safe", "any vulnerabilities", "security review". Default to running it on any backend feature with an external surface, even if no one asks.
---

# Security Review

This skill has two modes. In **guide mode** it threat-models a design while it's still cheap to change. In **review mode** it is the adversarial vulnerability gate. Read it all once; the review grid at the end is the contract.

Run review mode as a **separate, skeptical evaluator** — never as self-review by the agent that wrote the code. Security is the clearest case of the harness's evaluator-separation rule: an author rationalizes "probably fine"; an adversarial reviewer asks "how do I break this". Tune this reviewer to assume the input is hostile and the author is optimistic.

## The one rule everything derives from

**Treat every input crossing a trust boundary as hostile until validated, and every secret as already half-leaked.** Security is a property of the design, not a feature bolted on after. The cheapest vulnerability to fix is the one a threat model caught before the code existed.

## Threat modeling (guide mode, during architecture)

Map the design onto the hexagon — the architecture *is* your trust-boundary diagram:

- **Entry points = the driving (API) adapters.** HTTP handlers, message consumers, CLI. This is the attack surface. Everything entering here is untrusted.
- **The boundary = the adapter edge.** Validation, authentication, and authorization happen at the driving adapter, *before* a use case is called. A use case must never receive unvalidated transport input; the domain assumes its inputs are already legitimate.
- **Outbound risk = the driven (SPI) adapters.** SSRF, injection into downstream systems, secrets handling, and over-broad outbound access live here.
- **Secrets and trust live in infrastructure**, never in the domain — which falls out of domain purity for free.

Walk the design with a lightweight **STRIDE** frame — for each entry point and data flow, ask: Spoofing (can identity be faked?), Tampering (can data be altered in flight or at rest?), Repudiation (can an actor deny an action — is there an audit trail?), Information disclosure (what leaks on error, in logs, in responses?), Denial of service (what's unbounded — input size, rate, recursion?), Elevation of privilege (can a user act beyond their role?). Capture the assets worth protecting, the boundaries, and the riskiest exposure first — then propose the cheapest mitigation. Hard-to-reverse security decisions become ADRs.

## Vulnerability classes to check (backend focus)

- **Broken access control** (the most common real-world failure): every endpoint enforces authorization, not just authentication; no IDOR (object references checked against the caller's rights); default-deny.
- **Injection**: parameterized queries only (no string-built SQL); no shell/command construction from input; safe templating. Untrusted input is data, never code.
- **Authentication**: vetted libraries, no hand-rolled token/crypto; sane session/token lifetime; brute-force/rate limits.
- **Secrets management**: no secrets in code, config-in-repo, logs, or error messages; loaded from a secret store/env at the adapter edge.
- **Cryptography**: never roll your own; use established libraries and current algorithms; correct randomness source.
- **SSRF / outbound**: validate and constrain any URL/host the server fetches; allowlist where possible.
- **Deserialization / parsing**: bounded, typed, untrusted-input-safe; reject unexpected shapes.
- **DoS / resource exhaustion**: bound input size, pagination, recursion, concurrency; timeouts on all I/O.
- **Information disclosure**: errors return safe messages to the client; internal detail (stack traces, SQL, versions) stays server-side; logs carry no secrets/PII.
- **Supply chain**: dependencies pinned, scanned for advisories, minimal.

## Rust-specific notes

Memory safety removes a large bug class but not logic vulnerabilities, and not these:

- **`unsafe` blocks are review hotspots** — every `unsafe` needs a justification comment and extra scrutiny; it reintroduces the memory-safety risks the language otherwise prevents.
- **Advisory & supply-chain scanning**: `cargo audit` and `cargo deny check advisories` against the RustSec database — wire both as computational sensors (they also appear in `references/rust.md`).
- **Secret scanning**: `gitleaks` (or equivalent) in pre-commit and CI.
- **Panics as DoS**: an `unwrap()`/`expect()` on a path reachable from untrusted input is a denial-of-service vector; flag them.
- **Integer/auth logic**: overflow checks in release (`overflow-checks`), and authorization logic exercised by tests, not assumed.

## Computational security sensors (the deterministic quadrant)

Pair this skill's inferential review with deterministic checks, placed left:
- **Pre-commit**: secret scanning (`gitleaks`); `cargo deny check advisories`.
- **Pre-merge / CI**: full dependency & license scan (`cargo deny check`, `cargo audit`), SAST (e.g. `semgrep` rules), authorization tests.
- **Continuous**: re-run advisory scans on a schedule — new CVEs land against unchanged code.

## Handoff

Write threat modeling output to `docs/security/threat-model.md`. Findings become work: each confirmed issue is an `agent-brief` fix item in `docs/specs/` with concrete acceptance criteria; each *accepted* risk goes to `docs/security/accepted-risks.md` (or `docs/adr/` if it meets the 3-criteria ADR test) so the decision is recorded, not silently carried.

## Honest scope

This skill makes the agent *systematic* about common, well-understood vulnerability classes — it is not a penetration tester and will not find novel or chained exploits reliably. It raises the floor; it does not replace a human security review for anything high-assurance (auth systems, payment, PII at scale, public-facing trust boundaries). Treat a clean grid as "no common-class issues found", not "secure".

## Anti-patterns to reject

- **Authn without authz.** Logged in ≠ allowed; every action re-checks rights.
- **Trust at the wrong layer.** Validation inside the use case instead of at the driving adapter, or assuming an internal caller is safe.
- **Home-grown crypto / auth.** Any bespoke token, hash, or cipher.
- **Secrets anywhere durable.** In code, repo config, logs, or error payloads.
- **Optimistic self-review.** The author's "this is probably fine" standing in for an adversarial pass.
- **Unbounded anything.** Input, pagination, recursion, or I/O without a limit or timeout.

---

## Review grid (review mode — adversarial)

Apply to a design or diff as a skeptical, separate evaluator. Each item pass/fail; assume hostile input.

**Threat model**
- [ ] Entry points (driving adapters) and trust boundaries are identified.
- [ ] The riskiest exposure is named, with a mitigation.
- [ ] Accepted risks are recorded as ADRs, not left implicit.

**Access & input**
- [ ] Every endpoint enforces authorization, not just authentication; default-deny; no IDOR.
- [ ] Validation/authn/authz happen at the driving adapter, before any use case is called.
- [ ] No injection: parameterized queries, no command construction from input, safe parsing/templating.

**Secrets, crypto, transport**
- [ ] No secret in code, repo config, logs, or error messages.
- [ ] No hand-rolled crypto/auth; vetted libraries and current algorithms.
- [ ] Errors return safe messages; no internal detail leaks to the client.

**Resilience & supply chain**
- [ ] Inputs, pagination, recursion, concurrency, and I/O are bounded/timed.
- [ ] Dependencies scanned for advisories (computational sensor present and green).
- [ ] (Rust) every `unsafe` is justified; no `unwrap`/`expect` reachable from untrusted input.

**Verdict**
- State **NO COMMON-CLASS ISSUES FOUND** only if every box passes — and remember that is not the same as "secure". Otherwise **VULNERABILITIES FOUND** with each as `class — where — impact — smallest fix`, worst first. For anything high-assurance, recommend human security review regardless of the grid result.
