---
name: hexagonal-architecture
description: Enforce hexagonal (ports & adapters) architecture and craft principles when designing, structuring, implementing, or reviewing any application code. Use this whenever the work touches how a system is layered, where a piece of logic belongs, whether something should be an interface/port, how to keep the domain free of framework and I/O concerns, or how to map tests to layers. Trigger it during the architecture/design phase BEFORE code is written, and again as a review grid when reviewing a diff, PR, or plan — even if the words "hexagonal" or "ports and adapters" are never used. If the task is "build a new feature", "structure this module", "where should this go", "review this code", or "refactor this", consult this skill.
---

# Hexagonal Architecture (Ports & Adapters)

This skill has two modes. In **guide mode** (design/implementation) it tells you where code belongs and why. In **review mode** it gives you an objective grid to accept or reject a diff. Read the whole thing once; the review grid at the end is the contract.

## The one rule everything derives from

**Dependencies point inward. The domain depends on nothing.**

Source code dependencies always point from the outside toward the center. The center (domain) never imports anything from the outer regions — not a framework, not a database driver, not an HTTP type, not a serialization annotation. Everything else is a consequence of this rule. When in doubt, ask: "does this make the domain depend on something it shouldn't know exists?" If yes, it's wrong, and the fix is almost always to introduce a port.

## The three regions

Think in three concentric regions, not in technical folders. The boundary is *dependency direction*, not naming.

**Domain (center).** Entities, value objects, domain services, domain events, invariants. Pure logic and rules that would still be true if the application ran on paper. No I/O, no framework, no persistence, no time, no randomness reaching in directly. This is where business behavior lives — not in the application layer. An anemic domain (data bags + logic elsewhere) is a smell, not a style.

**Application (middle).** Use cases / application services that orchestrate the domain to fulfill one intent ("place order", "register user"). The application layer *defines the ports it needs* and coordinates them. It holds no business rules itself — it sequences calls to the domain and to ports. One use case = one clear transaction of intent.

**Infrastructure (outside).** Adapters. The concrete world: HTTP controllers, message consumers, CLI, database repositories, external API clients, clock, UUID generator, file system, email sender. Adapters depend inward on ports; nothing inward depends on adapters.

## API vs SPI (the two kinds of port — getting this wrong collapses the architecture)

There are two kinds of ports. We name them **API** and **SPI** (the Java sense of those words, *not* REST API). Both live **inside** the hexagon and speak only domain objects.

**API ports (inbound / driving)** — the interfaces through which the outside world *drives* the domain: the use case / command interfaces. An HTTP controller, a CLI command, a message consumer are *driving adapters*; they translate a transport request into a call on an API port. The API port is owned by the application. Folder: `ports/api/`.

**SPI ports — Service Provider Interface (outbound / driven)** — the interfaces the domain *needs from the world*: `OrderRepository`, `PaymentGateway`, `Clock`, `EventPublisher`. They are **defined inside** (in `ports/spi/`) and **implemented outside** by driven adapters. This is the dependency inversion that makes everything work: the domain declares the SPI, infrastructure provides the implementation (`StripePaymentGateway` implements the `PaymentGateway` SPI). Critically, an **SPI signature must only reference domain objects** — never ORM rows, DTOs, or transport types. That constraint is exactly what keeps persistence and serialization concerns out of the domain.

The litmus test for an SPI: *the domain needs to talk to something, but must not know which something.* If the application would otherwise import a concrete infrastructure class, define an SPI instead.

## Slice the domain by use case, not by technical layer

Organize the domain into **vertical slices, one folder per use case**, not into horizontal `model/` + `ports/` + `usecases/` buckets shared across the whole app. Each slice is self-contained: its API port, the SPIs *it* needs, the domain logic specific to it, its SPI stubs, and its tests, all co-located.

```
domain/
├── shared/                         # shared kernel — only truly cross-cutting domain types
│   └── model/                      # e.g. Money, identifiers, base value objects
├── place-order/                    # one use case = one slice, named by intent
│   ├── place-order.ts              # the use case (implements its API port)
│   ├── model/                      # domain types specific to this slice
│   └── ports/
│       ├── api/                    # the API port driving this use case
│       └── spi/
│           ├── order-repository.ts # only the SPIs THIS use case needs
│           └── stubs/
└── register-user/
    └── ... (same shape)
```

Why this beats layer-slicing:

- **It screams what the app does.** The top level of the domain is a list of capabilities (`place-order`, `register-user`), not a list of patterns. You read the folder and know the product.
- **Interface segregation falls out for free.** Each slice declares the *narrow* SPI it needs. `place-order` depends on a 2-method `OrderRepository`, not a 15-method god repository. A single adapter can still implement several slices' SPIs at the composition root.
- **A slice is the unit of delegation.** One use case, clear interfaces, independently testable, deletable without touching others — exactly the bite-sized unit a subagent can own end to end. This is the structural reason vertical slices and subagent-driven development fit together.

Rules that keep slicing honest:

- **No slice imports another slice.** If `place-order` needs behavior from `register-user`, that's a smell. Promote the shared concept into `shared/` (a domain service or value object), or — if it's a genuine cross-capability call — go through a port, never a direct import. Slice→slice coupling is the failure mode that turns vertical slices back into a tangle.
- **Keep `shared/` minimal and ruthless.** It is a shared *kernel*, not a junk drawer. Only types used by several slices and stable enough to be safe to share belong there. Prefer a little duplication in two slices over a premature abstraction in `shared/`. When in doubt, leave it in the slice.
- **Adapters can stay grouped by actor** (one `PostgresOrderAdapter` implementing the order SPIs of several slices) even though the SPIs are defined per slice. The composition root wires each adapter to the slices that declared the matching SPI.

## Decision heuristics (guide mode)

- **"Where does this logic go?"** If it expresses a business rule or invariant → domain. If it sequences steps to fulfill an intent → application use case. If it talks to the outside world → adapter behind a port.
- **"Should this be a port?"** Yes if the domain depends on a capability whose implementation belongs outside (persistence, messaging, external services, time, randomness, ID generation). Define the interface inside as an **SPI** in `ports/spi/`, name it for the capability (`OrderRepository`), not the technology (`PostgresClient`).
- **"Which side owns the interface?"** The *inside* owns it. API ports and SPI ports both live in the domain's `ports/` directory; adapters in infrastructure implement the SPIs and call the APIs. Never define a port in the adapter and have the domain depend on it — that re-inverts the dependency the wrong way.
- **"Can I put this annotation/decorator on a domain object?"** No. ORM mappings, JSON serialization, validation framework annotations, DI framework wiring — all of that lives in infrastructure or in dedicated DTO/persistence-model types, never on domain entities.

## Domain purity rules

- No imports from any framework, ORM, web, or serialization library inside domain or application.
- No `now()`, `random()`, `uuid()`, network, disk, or env access reaching into the domain directly — inject them as driven ports (`Clock`, `IdGenerator`).
- Persistence models ≠ domain entities. Map between them in the repository adapter. A repository (SPI implementation) returns domain objects, never ORM rows or DTOs. Because SPI signatures only mention domain objects, this mapping has nowhere to leak.
- DTOs / request-response shapes live with the driving (API) adapter that uses them. They do not cross into the domain; map at the boundary.
- Domain errors are domain types (e.g. `InsufficientFunds`), not HTTP status codes or framework exceptions. Driving adapters translate domain errors into transport errors.

## Testing strategy maps to the architecture

The layering is what makes tests cheap. Match the test type to the region:

- **Domain → pure unit tests, no mocks, no I/O.** If a domain test needs a mock, logic has leaked out of the domain.
- **Use cases (API ports) → tests driven through stubs of the SPIs.** The stubs are hand-written test doubles that implement the SPI interfaces and live **inside the domain**, in `ports/spi/stubs/`, returning the datasets needed to exercise every business case. Keeping stubs in the domain (rather than reaching for a mocking framework) preserves the domain's hermeticity and keeps these tests fast, deterministic, and framework-free. This is where most behavioral coverage lives.
- **Driven (SPI) adapters → integration tests against the real dependency** (e.g. a real database via Testcontainers). Verify the adapter honors its SPI contract.
- **Driving (API) adapters → thin tests** that the adapter correctly translates transport ↔ API-port call.
- **End-to-end → through the driving adapters**, exercising a real wired stack for the critical user journeys only.
- Co-locate tests with the code they cover (`*.spec.ts` / `_test.go` next to the source), so a unit and its test move together.

Two principles that keep these tests honest (they restate the architecture as testing rules):

- **Test observable behavior through the public interface, never the implementation.** A test that breaks when you rename an internal function — but the behavior is unchanged — was testing the wrong thing. Good tests survive refactors; they read like a specification of what a use case does.
- **Mock only at system boundaries — which, here, means only at SPIs.** Never mock your own domain collaborators. If a test mocks something inside the hexagon, that's the same leak the no-mocks-in-domain rule catches, seen from the test side. Stubbing an SPI is fine (it *is* the boundary); mocking an entity or a domain service is not.
- **Prefer deep modules** (Ousterhout): a small interface hiding substantial implementation. A narrow SPI in front of a rich domain *is* a deep module; a fat SPI that just forwards calls is a shallow one to avoid. The depth of your modules and the narrowness of your ports are the same property viewed twice.

A useful review signal: if adding a feature forced you to write mock-heavy tests in the domain, the design is wrong, not the test.

## Language mapping (compact)

The principles are language-agnostic; enforcement mechanisms differ. The canonical layout is `domain/` sliced **per use case** (each slice holding its use case, slice-specific `model/`, and `ports/{api,spi}/` with `ports/spi/stubs/`), plus a minimal `domain/shared/` kernel, and `infrastructure/` (or per-actor adapter packages) implementing the SPIs. Wiring happens at a single composition root. Keep deeper per-language detail in `references/<lang>.md` if it grows.

- **TypeScript / Node** — `domain` package with `ports/api`, `ports/spi`, and `ports/spi/stubs`; adapters in separate packages (one per external actor) implementing the SPIs; tests as co-located `*.spec.ts`. Wire adapters into the domain by constructor injection at a dedicated composition root / loader package — no DI framework reaching into the domain. Enforce import direction with an import-boundary linter (dependency-cruiser / eslint-plugin-boundaries).
- **Go** — `domain` package defining API and SPI as interfaces; adapters in their own packages implementing the SPIs; wire concrete adapters into the domain in `main` (the composition root). The package import graph enforces the dependency rule; keep `domain` importing only the standard library and other domain packages.
- **Java / Quarkus** — domain module with no Quarkus/Jakarta imports; `api`/`spi` interfaces in the domain; adapters as `@ApplicationScoped` beans implementing the SPIs; wire via CDI *at the edge only*. ArchUnit tests assert no domain → framework dependency.
- **Rust** — domain & application as crates with zero framework deps; API/SPI as traits; adapters as separate crates depending inward; wire with generics or `dyn Trait` at the `main` composition root. The crate graph *is* the dependency rule, compiler-enforced. Computational sensors, workspace layout, and the decisions Rust forces are in [references/rust.md](references/rust.md) — read it when the repo is Rust.

## Anti-patterns to reject

- **Folders without enforcement.** Three packages named domain/application/infra but nothing stops domain importing infra. The dependency rule must be *enforced* (compiler, module boundaries, ArchUnit/dependency-cruiser), not just intended.
- **Ports on the wrong side.** SPI interface defined in the adapter, domain depends on the adapter package. SPIs and APIs live in the domain's `ports/`.
- **Leaky SPI signatures.** An SPI method takes or returns an ORM entity, DTO, or transport type instead of domain objects.
- **Transport in the use case.** An API port takes an HTTP request object, returns an HTTP response, or throws framework exceptions.
- **Anemic domain.** Entities are getter/setter bags; all behavior sits in "services".
- **God use case.** One service doing five intents. One use case = one intent = one slice.
- **Slice→slice coupling.** One use-case slice imports another; or `shared/` has swollen into a god module that every slice depends on.
- **Framework in the center.** Any ORM/web/serialization/DI annotation on a domain or application type.

---

## Review grid (review mode)

Apply this to the diff/PR/plan. Each item is pass/fail. Assume the author had zero context and questionable taste; verify, don't trust. Report each failure with file:line and the smallest fix.

**Dependency direction**
- [ ] No domain file imports a framework, ORM, web, serialization, or DI library.
- [ ] No application file imports infrastructure/adapter packages.
- [ ] Dependency direction is *enforced* mechanically (crate graph / module boundaries / lint / ArchUnit), not just by convention.

**Ports**
- [ ] Every external capability the domain uses goes through an SPI (no direct `new StripeClient()` / concrete infra type inside the domain or a use case).
- [ ] API and SPI interfaces live in the domain's `ports/api` and `ports/spi`; adapters implement SPIs / call APIs — never the reverse.
- [ ] SPI signatures reference only domain objects (no ORM rows, DTOs, or transport types).
- [ ] Ports are named for capability, not technology (`OrderRepository`, not `PostgresOrderDao`).

**Domain purity**
- [ ] No `now()` / `random()` / `uuid()` / I/O reaching directly into domain; these arrive via SPIs.
- [ ] Domain entities carry behavior and invariants, not just data.
- [ ] Domain errors are domain types; transport/framework error mapping happens only in driving (API) adapters.

**Boundaries & mapping**
- [ ] Repository (SPI) implementations return domain objects, never ORM rows or DTOs.
- [ ] Request/response DTOs stay in the driving (API) adapter; mapping to domain happens at the boundary.
- [ ] Each API port / use case expresses exactly one intent.

**Slice cohesion**
- [ ] The domain is organized one folder per use case, not by horizontal technical layer.
- [ ] No slice imports another slice; cross-cutting types live in a minimal `shared/` kernel.
- [ ] Each slice declares only the narrow SPIs it needs (no shared god repository).

**Tests**
- [ ] Domain tests have no mocks and no I/O.
- [ ] Use cases are tested through SPI stubs located in `ports/spi/stubs` inside the domain.
- [ ] SPI adapters have integration tests against the real dependency (e.g. Testcontainers).
- [ ] Tests are co-located with the code they cover.

**Verdict**
- State **ACCEPT** only if every box passes. Otherwise **REQUEST CHANGES** with the failing items, each as `file:line — what's wrong — smallest fix`. Do not soften; a fresh reviewer's value is catching what the author rationalized.
