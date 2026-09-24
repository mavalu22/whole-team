# Architecture - {{product name}}

<!-- Written by the Architect in factory/output/architecture.md (Discovery step 3), in English. It summarizes and connects factory/input/03-platform-architecture.md and the ADRs; keep details there and link by section number. Update it through change requests. -->

- **Last updated:** {{YYYY-MM-DD}}
- **Sources:** 02-stack.md, 03-platform-architecture.md, ADR index below

## 1. Overview

<!-- 3-6 lines: what the system is, the platforms, the architecture style and why (link the ADR). -->

{{overview}}

## 2. Component diagram

<!-- Mermaid flowchart with every component, data store and external integration, and the direction of calls. -->

```mermaid
flowchart LR
  {{component_a}}["{{Component A}}"] --> {{component_b}}["{{Component B}}"]
```

## 3. Modules

<!-- One row per module: responsibility, public interface, data it owns, modules it depends on. The Touches vocabulary in the stack profile maps to these modules. -->

| Module | Responsibility | Public interface | Owns data | Depends on |
|---|---|---|---|---|
| {{module}} | {{responsibility}} | {{interface}} | {{entities}} | {{modules}} |

## 4. Data model

<!-- Entities with key attributes and relations (Mermaid erDiagram), then the personal data inventory. -->

```mermaid
erDiagram
  {{ENTITY_A}} ||--o{ {{ENTITY_B}} : {{relation}}
```

### Personal data inventory

| Entity.field | Category | Purpose | Stored / sent to | Retention | Protection |
|---|---|---|---|---|---|
| {{entity.field}} | {{category}} | {{purpose}} | {{where}} | {{period}} | {{hashed, encrypted, masked}} |

## 5. Integrations

| Integration | Purpose | Protocol | Auth | Failure handling |
|---|---|---|---|---|
| {{service}} | {{purpose}} | {{REST, webhook, SDK}} | {{method}} | {{retry, fallback, queue}} |

## 6. Cross-cutting concerns

<!-- Authentication and authorization model, API style and conventions, error format, configuration, logging and observability, realtime, background jobs, file storage, multi-tenancy, i18n, offline, notifications. Write "Not applicable" where it does not apply. -->

- **Auth:** {{model}}
- **API style:** {{REST, GraphQL, RPC}} - {{conventions}}
- **Configuration:** {{environment variables, validated at startup}}
- **Observability:** {{logging, health checks, metrics}}
- **Other:** {{concern: approach}}

## 7. Non-functional requirements

| NFR | Target | How verified |
|---|---|---|
| {{performance, availability, scalability, security}} | {{measurable target}} | {{test, measurement, review}} |

## 8. Environments and hosting

- **Environments:** {{local, staging, production}}
- **Target hosting platform:** {{platform}} (the hosting guide is written at the checkpoint set by deploy.hosting_guide)

## 9. ADR index

| ADR | Title | Status | Date |
|---|---|---|---|
| ADR-{{nnn}} | {{title}} | {{status}} | {{YYYY-MM-DD}} |
