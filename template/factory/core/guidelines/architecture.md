# Architecture

How the product is structured, whatever the stack. The chosen style, modules and technologies are in `factory/input/03-platform-architecture.md` and `factory/output/architecture.md`; the folder layout is in `factory/input/04-stack-profile.md`. Search this file for the heading you need.

Sections: 1. Modular boundaries · 2. Dependency direction · 3. Layers · 4. Configuration · 5. Twelve-factor basics · 6. When to write an ADR · 7. Monolith first · 8. Review checklist

## 1. Modular boundaries

- Split the product into modules by business capability (`billing`, `accounts`, `catalog`), not by technical type (`controllers`, `models`) at the top level.
- Each module exposes a small public interface (an index file, a service, a package API). Other modules use only that interface, never its internals or its tables.
- Data belongs to one module. Another module that needs it calls the owner's interface or subscribes to its events; it never reads the owner's tables directly.
- Shared code (`shared/`, `common/`) holds only generic, domain-free utilities. If it knows about a business concept, it belongs in a module.

| Don't | Do |
|---|---|
| `orders` queries the `users` table | `orders` calls `accounts.getCustomer(id)` |
| A `utils` module with pricing rules | Pricing rules inside `billing` |
| Circular imports between two modules | Extract the shared concept, or invert with an interface or event |

## 2. Dependency direction

- Dependencies point inward: infrastructure → application → domain. The domain depends on nothing outside itself.
- Modules form a directed acyclic graph; record it in the component diagram. A new cross-module dependency is a design decision: note it in the report, and write an ADR if it changes the diagram.
- Depend on interfaces you own for external services (payment provider, email, storage), and implement them in infrastructure adapters. This keeps vendors replaceable and tests fast.

## 3. Layers

- **Domain:** entities, value objects and business rules. Pure code: no HTTP, SQL, framework or clock calls (pass time and IDs in).
- **Application:** use cases that orchestrate the domain: load, decide, save, notify. Transactions and authorization checks live here.
- **Infrastructure:** adapters for databases, HTTP, queues, files, third-party APIs, and framework wiring.
- **Interface:** HTTP handlers, UI, CLI. They translate input to a use case call and the result to a response; no business rules.

For small products, fewer folders are fine, but the dependency rules still hold: business rules never live in handlers, components or SQL.

## 4. Configuration

- Everything that differs between environments comes from environment variables: URLs, credentials, feature flags, limits, ports.
- Read and validate configuration once at startup into a typed object; fail fast with a clear message when a required value is missing or invalid.
- Every setting appears in `.env.example` with a safe placeholder and a comment. Real values never enter git.
- Defaults are safe for local development and never weaken security in production (for example no default admin password, debug off unless set).
- Parallel slots: ports and database names derive from `FACTORY_SLOT` as the stack profile defines.

## 5. Twelve-factor basics

- One codebase in git; dependencies declared in a manifest with a lockfile.
- Config in the environment (section 4).
- Backing services (database, cache, queue, email) are attached resources addressed by configuration.
- Build, release and run are separate steps; the build does not need production secrets.
- Processes are stateless; state lives in backing services. Local files are for temporary data only.
- The app binds to a port from configuration.
- Fast startup and graceful shutdown: finish in-flight work on the termination signal.
- Development and production stay as similar as practical (same database engine, same major versions).
- Logs go to stdout or stderr as event streams (`factory/core/guidelines/observability.md`).
- Admin tasks (migrations, one-off scripts) run as commands of the same codebase.

## 6. When to write an ADR

Write an ADR (`factory/core/templates/adr.md`, in `factory/output/adr/`) when a decision:

- chooses or replaces a framework, database, major library, or external service;
- sets or changes the architecture style, a module boundary, or the API style;
- is hard or expensive to reverse, or trades off one quality attribute for another (consistency vs availability, speed vs cost);
- deviates from these guidelines or the stack profile.

An ADR records context, the decision, the alternatives considered, the consequences, the status and the date. Supersede an ADR with a new one; never edit an accepted decision away.

## 7. Monolith first

- Default to a modular monolith: one deployable, clear modules inside.
- Choose separate services only for a concrete, recorded need: independent scaling of one part, a different runtime, separate teams, or isolation for security or compliance.
- Avoid distributed-system costs you don't need: network calls between modules, distributed transactions, per-service deployment and observability.
- A well-bounded module can be extracted into a service later; design the boundaries so that stays possible.

## 8. Review checklist

- [ ] New code sits in the module that owns the capability; no module reaches into another's internals or tables.
- [ ] No circular dependencies; new cross-module dependencies are justified.
- [ ] Business rules live in the domain or application layer, not in handlers, components or queries.
- [ ] External services sit behind interfaces with infrastructure adapters.
- [ ] New settings come from the environment, are validated at startup, and appear in `.env.example`.
- [ ] Processes stay stateless; logs go to stdout or stderr.
- [ ] Significant decisions have an ADR.
