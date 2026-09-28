# Discovery

Read when `phase: discovery`, or when a `Change:` reopens a step. Each section stands alone: search this file by its exact path for the heading you need (for example `## 5. Step 3`) and read only that section plus sections 1 and 2.

Sections: 1. Rules · 2. Step procedure · 3. Step 1: Vision and scope · 4. Step 2: Stack · 5. Step 3: Platform and architecture · 6. Step 4: Stack profile · 7. Step 5: Interface design · 8. Step 6: Constraints · 9. Step 7: Testing · 10. Step 8: Backlog

## 1. Rules

- **Order.** Steps run in order 1 → 8. After step 1 is approved, ask whether the user wants to do Interface design (step 5) now, right after Vision, or later. If now, set `discovery.design_early: true` and run step 5 second; the order becomes 1, 5, 2, 3, 4, 6, 7, 8. Step numbers and keys never change.
- **One step at a time.** Never start a step before the previous one in the order is approved.
- **Questions.** Ask from the step's question bank in small batches (at most 4 per message), adapting to earlier answers. Propose a recommended answer or default for each question, so the user can reply "ok". Never ask what earlier inputs already answer; state the assumption instead and let the user correct it.
- **Writing.** Fill the step's input file (from the template already in `factory/input/`) in `state.input_language`. Record each answer with a small edit as soon as it is agreed; never rewrite the whole file. Keep the "Open questions" section until it is empty or the user accepts the remaining items as open.
- **Headings.** Translate section headings to `state.input_language` but keep their numbers and order (`## 5. Auth`). Front-matter keys stay English. Replace each guidance comment with content; write "Not applicable" with a one-line reason for sections that don't apply.
- **Approval.** Close each step with a summary of at most 15 lines and an explicit request: "Reply **approve** to continue, or tell me what to change."
- **Changes after approval.** An approved step changes only through `Change:` (`factory/core/workflow/change-requests.md`).
- **Checklists.** Each step has a completion checklist. Don't ask for approval until every item passes.
- **Delegated drafts.** When a role drafts a document, send it a task message (`factory/core/templates/task-message.md`) with `STAGE: DISCOVERY`, the answers agreed so far, and the paths of the approved input files it needs. Drafting roles write the input file directly; you then discuss it with the user and apply small corrections yourself. Re-delegate only when a correction needs the role's expertise (for example a different stack option).
- **Attachments.** A file cited in an answer (`factory/core/FACTORY.md`, "Attachments") is recorded in the step's input document with its path and description. It stays in `factory/attachments/discovery/<step key>/`, because there is no item yet.
- **Quick mode.** Steps 3 to 7 run in quick mode when their key is in `discovery.quick_steps` (`factory/core/modes.md` section 15). A quick step still produces its full output document, because later stages and agents depend on it, but skips "Ask" (section 2, step 3): its owner drafts the document straight from the answers already agreed, the stack's conventions and the documented defaults, without the question bank. The step's checklist still applies before it can be approved.

## 2. Step procedure

For every step:

1. **Start.** In `factory/state.yaml`: set `discovery.current_step` to the step key and the step's `status: in_progress`. In the input file's front matter set `language:` to `state.input_language` if it is `null`.
2. **First.** Do the step's "First" actions, if any (for example, choose a mode).
3. **Ask.** Work through the question bank in batches, recording answers as they settle. Skip this step for a quick step (Rules, "Quick mode"): go straight to Draft.
4. **Draft.** Delegate the drafts listed under "Delegation", if any, and review the result against the checklist.
5. **Check.** Run the checklist. Resolve gaps with the user or the drafting role.
6. **Approve.** Present the summary and ask for approval: the step's usual summary (at most 15 lines), or for a quick step, a summary of at most 10 lines with the choices that matter most, drafted by the owner alongside the document.
7. **On approval:**
   1. in the input file's front matter, set `status: approved` and `approved_at: <YYYY-MM-DD>`;
   2. in `factory/state.yaml`, set the step's `status: approved` and `approved_at`, set `current_step` to the next step key (or `null` after step 8), and append a log line;
   3. write the config keys the step owns (listed per step), replacing whole lines.
8. **Next.** Say which step comes next and start it.

## 3. Step 1: Vision and scope

- **Key:** `s1_vision` · **Output:** `factory/input/01-product-vision.md`
- **Goal:** a shared, testable definition of the problem, the users and the MVP.
- **Owners:** Product Owner. You lead the conversation: read `factory/core/roles/product-owner.md` and follow its procedure. No delegation.
- **Question bank:**
  - What problem does this solve, and for whom? What do people do today without it?
  - Who are the primary users (personas)? Are there admins or other secondary users?
  - What is the one-sentence value proposition?
  - What must the first usable version (MVP) do? What is explicitly out of scope?
  - Which 3-7 core features matter most? For each: who uses it and why?
  - What are the main user journeys, end to end?
  - How will you measure success?
  - Does the business model affect features (payments, subscriptions, ads)?
  - Are there products you like or dislike as references?
  - What are the known risks and assumptions?
- **Checklist:**
  - [ ] Problem and current alternatives stated.
  - [ ] Personas, primary and secondary.
  - [ ] Value proposition in one sentence.
  - [ ] MVP scope in and out.
  - [ ] Features prioritized with MoSCoW (Must, Should, Could, Won't).
  - [ ] User stories with IDs `US-01`, `US-02`, ..., each with acceptance criteria in Given/When/Then or checklist form.
  - [ ] Main journeys, end to end.
  - [ ] Success metrics.
  - [ ] Open questions resolved or accepted.
- **Config keys set:** none.
- **After approval:** ask the design-early question (section 1, "Order").

## 4. Step 2: Stack

- **Key:** `s2_stack` · **Output:** `factory/input/02-stack.md`, ADRs in `factory/output/adr/`
- **Goal:** every layer of the stack chosen with a rationale, current versions and recorded alternatives.
- **Owners:** Architect drafts; you discuss with the user.
- **Question bank** (ask before delegating):
  - Are there preferred or mandatory languages or frameworks (team skills, existing code)?
  - Which frontend, backend and database? If the user is undecided, the Architect proposes 1-2 options with trade-offs.
  - Which authentication approach (email/password, OAuth providers, managed service)?
  - Is there a hosting preference? It influences the stack.
  - Runtime versions (LTS) and package manager?
  - Which third-party services (email, payments, storage, analytics, maps)?
  - Any license constraints?
- **Delegation:** `architect`, with the agreed answers and the path to `factory/input/01-product-vision.md`. The Architect checks current stable or LTS versions with web search when available, records the date checked, drafts `02-stack.md` and writes an ADR for each major choice. When options remain open, it presents at most 2 per layer with trade-offs; you let the user choose, then the choice and the rejected option go into "Alternatives considered".
- **Checklist:**
  - [ ] Every layer chosen with a rationale (summary table filled).
  - [ ] Versions are current stable or LTS, each with the date verified.
  - [ ] Third-party services listed with their purpose.
  - [ ] Alternatives recorded.
  - [ ] ADRs written for major choices and listed in the file.
- **Config keys set:** none.

## 5. Step 3: Platform and architecture

- **Key:** `s3_architecture` · **Output:** `factory/input/03-platform-architecture.md`, `factory/output/architecture.md`, ADRs
- **Goal:** interfaces, architecture, components, data model, integrations and non-functional requirements, precise enough to generate the backlog.
- **Owners:** Architect drafts; DBA reviews the data model; you discuss with the user.
- **Question bank** (ask before delegating):
  - **Interfaces:** show the "Interfaces" descriptions from `factory/core/modes.md` (section 2) and ask which ones the product has (one or more). If `factory/state.yaml` already logs the user's answer (an `interfaces set` line), confirm it instead of asking again. Then ask the details each chosen interface needs:
    - `gui`: platforms (web SPA or SSR, mobile native or cross-platform, desktop), responsive, PWA;
    - `api`: style (REST, GraphQL, gRPC, webhooks); this also answers the API style question below;
    - `cli`: target shells and operating systems;
    - `service`: triggers (queue, schedule, stream);
    - `library`: language runtimes and the registry to publish to;
    - `plugin`: host application, supported host versions and the marketplace.
  - Expected users and load, now and in 12 months? Performance targets?
  - Which architecture style? Default recommendation: modular monolith unless justified.
  - What are the components and their boundaries?
  - What are the main data model entities?
  - Which integrations and API style (REST, GraphQL, RPC)?
  - Any need for realtime, background jobs, file storage, multi-tenancy, i18n, offline or notifications?
  - Which environments?
  - **Target hosting platform** (used later for the hosting guide)? Ask it only when the product has `gui`, `api` or `service`, and not when its only `gui` is panels or webviews inside a `plugin`. For `library` and `plugin`, ask for the registry or marketplace instead (already answered with the interface details).
  - What observability is needed?
- **Delegation:**
  1. `architect`: draft `03-platform-architecture.md` and `factory/output/architecture.md` (from `factory/core/templates/architecture.md`), with a Mermaid component diagram, and write ADRs. Inputs: agreed answers, paths to `01-product-vision.md` and `02-stack.md`.
  2. `dba`: review the data model section (entities, relations, constraints, PII). Stage `DISCOVERY`.
  3. If the DBA returns findings, send them to the `architect` to fix (one round), then check again.
- **Quick mode:** draft from the standard architecture default (a modular monolith, `factory/core/guidelines/architecture.md`) and the interfaces already agreed; list only the open decisions that most affect later steps in the summary.
- **Checklist:**
  - [ ] Interfaces, each with its details.
  - [ ] Architecture style with rationale.
  - [ ] Mermaid component diagram.
  - [ ] Modules and boundaries.
  - [ ] Entities and relations, reviewed by the DBA.
  - [ ] Integrations and API style.
  - [ ] Cross-cutting needs (realtime, jobs, storage, tenancy, i18n, offline, notifications): each answered or "Not applicable".
  - [ ] Environments.
  - [ ] Target hosting platform, when the product has something to host; the registry or marketplace for `library` and `plugin`.
  - [ ] Non-functional requirements (performance, availability, scalability, observability).
  - [ ] ADRs written; `factory/output/architecture.md` written.
- **Config keys set:** `project.interfaces`, as a list (for example `interfaces: [gui, api]`), with a log line `"<ISO time> interfaces set: [<ids>]"`.

## 6. Step 4: Stack profile

- **Key:** `s4_stack_profile` · **Output:** `factory/input/04-stack-profile.md`
- **Goal:** the exact conventions and commands every role agent follows. Role agents read this file on every item, so it must be precise and complete.
- **Owners:** Architect and Tech Lead draft.
- **Question bank:** preferred code style or strictness (for example TypeScript strict); folder structure preferences; lint and format preferences; pre-commit hooks, yes or no; preferred test tools, if any.
- **Delegation:**
  1. `architect`: draft folder structure, `Touches` vocabulary, commands, quiet command forms, tooling configuration, configuration and env, dependency policy, tooling exclusions for `factory/`, and parallel slot isolation.
  2. `tech-lead`: add or refine naming, error handling, logging, framework patterns and anti-patterns, and check that every command is exact and runnable for the stack.
- **Quick mode:** draft the commands from the stack's standard tooling (its usual install, dev, test, lint, type-check and build commands, with quiet forms) and the `Touches` vocabulary already used in `03-platform-architecture.md`, instead of asking preferences.
- **Checklist:**
  - [ ] Folder structure and naming conventions.
  - [ ] `Touches` vocabulary: short, stable area names (`auth`, `db`, `api/<resource>`, `ui/<screen>`, `cli/<command>`, `jobs/<name>`, `lib/<module>`, `plugin/<extension point>`, `infra`, `ci`, ...).
  - [ ] Lint, format and type-check tools with their configuration choices.
  - [ ] Exact commands: install, dev, test, lint, type-check, format, build.
  - [ ] Per interface, when the product has it: run the CLI, start the worker, build and pack the library locally, launch the plugin host in development mode, each with its quiet form where it has output.
  - [ ] Quiet forms of the test, lint, type-check and build commands, printing only failures and a summary.
  - [ ] Error handling, logging, configuration and env patterns, dependency policy.
  - [ ] Framework patterns and anti-patterns.
  - [ ] Tooling exclusions for `factory/` (tests, linters, formatters, bundlers, Docker build context).
  - [ ] Slot runtime isolation: how to set the port and the database per slot (`FACTORY_SLOT`).
- **Config keys set:** none.

## 7. Step 5: Interface design

- **Key:** `s5_design` · **Output:** `factory/input/05-design-spec.md` (always), plus prototypes in `factory/input/prototypes/` (`gui` only)
- **Goal:** a spec for every interface in `project.interfaces`, precise enough for developers and for reviews: a design system and screen list for `gui`, the contract other people or software rely on for the others.
- **Interfaces.** Read `project.interfaces` in `factory/config.yaml`. If step 3 is not approved yet (Design early) and the log has no `interfaces set` line, first ask the interfaces question of step 3 (section 5; the details wait for step 3), then write `project.interfaces` and append `"<ISO time> interfaces set: [<ids>]"` to the log.
- **How the step runs.** Read only the subsections of the product's interfaces:
  - `gui`: section 7.1, the design flow. The UX/UI Designer takes part only when the product has `gui`.
  - Every other interface: section 7.2, plus the interface's own subsection (7.3 to 7.7).
  - With `gui` and other interfaces, run 7.1 first, then 7.2.
- **Document.** `05-design-spec.md` has one part per interface: sections 1-14 for `gui`, then 15 `api`, 16 `cli`, 17 `service`, 18 `library` and 19 `plugin`. Each part starts with a scope line, `In scope.` or `Not in scope: <reason>.`, so readers skip what does not apply. Without `gui`, section 1 holds only its scope line and sections 2-14 are left out.
- **Checklist:** the checklist of each interface in scope, plus:
  - [ ] Every interface part starts with its scope line.
- **Config keys set:** those of section 7.1 when the product has `gui`; none otherwise.

### 7.1 `gui`

- **Owners:** UX/UI Designer. You lead the conversation: read `factory/core/roles/ux-ui-designer.md` and follow its procedure.
- **First:** show the three design modes from `factory/core/modes.md` (section 6) and ask the user to choose. Write `design.mode`.
- **Quick mode:** use design mode `spec` (skip the mode choice), drafted from brand personality, existing assets and references the user gives in one message, instead of the full question bank.
- **Question bank:**
  - Brand personality in 3 adjectives?
  - Existing brand assets (logo, colors, fonts)?
  - References and inspirations?
  - Light mode, dark mode, or both?
  - Target devices and breakpoints?
  - Accessibility target? Default: WCAG 2.2 AA.
  - Tone of voice for interface text?
  - Which key screens? Derive them from the journeys in `01-product-vision.md`.
  - Component library preference, compatible with the stack (skip if step 2 is not approved yet)?
- **Per mode:**
  - `spec`: you write `05-design-spec.md` from the answers.
  - `html_prototypes`: write the tokens in `05-design-spec.md` first, then delegate to `ux-ui-designer` to generate `factory/input/prototypes/assets/styles.css` from the tokens and the key screens, plus `index.html`. Show the user the path to `factory/input/prototypes/index.html` to open in a browser, collect feedback, and iterate (re-delegate with the feedback) until the user approves the screens.
  - `user_prototypes`: ask the user to place their files in `factory/input/prototypes/` (naming in `factory/input/prototypes/README.md`), then delegate to `ux-ui-designer` to inventory them and extract the spec into `05-design-spec.md`.
- **Checklist:**
  - [ ] Color tokens (with contrast checked against the accessibility target).
  - [ ] Typography.
  - [ ] Spacing and grid.
  - [ ] Radius and elevation.
  - [ ] Components with states (default, hover, focus, active, disabled, loading, empty, error).
  - [ ] Iconography and imagery.
  - [ ] Key flows as Mermaid diagrams.
  - [ ] Screen list mapped to user stories.
  - [ ] Accessibility target and rules.
  - [ ] Tone of voice.
  - [ ] Prototype index (when prototypes exist), approved by the user.
- **Config keys set:** `design.mode`. (The UI conformance check is `pipeline.ux_check`, set by the process preset at kickoff and changed with the `Process` command; `factory/core/modes.md` section 13.)

### 7.2 Other interfaces

- **Owners:** Architect drafts; you discuss with the user.
- **Question bank:** the question bank of each interface in scope (sections 7.3 to 7.7), in batches of at most 4. Recommend answers from the approved inputs and the usual conventions of the ecosystem. Skip what `03-platform-architecture.md` already answers (for example the API style) and, if step 2 is not approved yet, the questions that depend on the stack.
- **Delegation:** one task message to `architect` (stage `DISCOVERY`, item `s5_design`) covering every non-GUI interface of the product: the agreed answers per interface, the paths of the approved input files it needs (`01-product-vision.md`, and `02` to `04` when approved), and the sections of `05-design-spec.md` to fill. Then review the draft with the user as usual.
- **Checklist:** the checklist of each interface in scope.

### 7.3 `api`

- **Question bank:**
  - Which resources and operations does each user story need?
  - Where does the contract file live in the product repository? Default: `docs/openapi.yaml`, or the stack's schema file.
  - How is the API versioned?
  - Which error format? Default: RFC 9457 problem details.
  - How do pagination, filtering, idempotency, authentication and rate limits work?
  - Which naming conventions (paths, fields, case)?
- **Checklist:**
  - [ ] Resources and operations mapped to user stories.
  - [ ] Contract file and its path in the product repository.
  - [ ] Versioning.
  - [ ] Error format.
  - [ ] Pagination, filtering, idempotency, authentication and rate limits.
  - [ ] Naming conventions.

### 7.4 `cli`

- **Question bank:**
  - Which commands and subcommands does each user story need?
  - Which argument and flag conventions (long and short flags, POSIX style)?
  - Which exit codes?
  - Which output formats? Default: human-readable, plus JSON for scripts.
  - How do stdin and stdout behave (pipes, prompts)?
  - Which configuration files and environment variables?
  - Color and TTY detection? Shell completion?
- **Checklist:**
  - [ ] Command tree mapped to user stories.
  - [ ] Argument and flag conventions.
  - [ ] Help text for every command.
  - [ ] Exit codes.
  - [ ] Output formats: human-readable, and JSON for scripts.
  - [ ] Stdin and stdout behavior.
  - [ ] Configuration files and environment variables.
  - [ ] Error messages.
  - [ ] Color and TTY detection.
  - [ ] Shell completion, or "Not wanted".

### 7.5 `service`

- **Question bank:**
  - Which inputs does it consume and which outputs does it produce? With which message or event schemas?
  - Which triggers and schedules?
  - Which delivery guarantee? Default: at least once, with idempotent handlers.
  - How many retries, with which backoff, and where do failed messages go (dead letters)?
  - Which configuration?
  - Which health checks, logs and metrics?
  - How does it shut down gracefully?
- **Checklist:**
  - [ ] Inputs and outputs, with their message or event schemas.
  - [ ] Triggers and schedules.
  - [ ] Delivery guarantees and idempotent handlers.
  - [ ] Retries and dead letters.
  - [ ] Configuration.
  - [ ] Health checks, logs and metrics.
  - [ ] Graceful shutdown.

### 7.6 `library`

- **Question bank:**
  - Which public functions, types or classes does each user story need?
  - Which naming conventions?
  - How are errors reported (exceptions, result types, error codes)?
  - Which runtime versions are supported?
  - Which versioning and deprecation policy? Default: semantic versioning, deprecate for one minor version before removing.
  - Which package entry points (modules, exports, CommonJS or ESM)?
- **Checklist:**
  - [ ] Public API surface mapped to user stories.
  - [ ] Naming.
  - [ ] Error model.
  - [ ] Supported runtime versions.
  - [ ] Semantic versioning and deprecation policy.
  - [ ] Package entry points.
  - [ ] Usage examples.

### 7.7 `plugin`

- **Question bank:**
  - Which host and host versions (confirm step 3)?
  - Which extension points does each user story need, and what goes in the manifest?
  - Which activation events?
  - Which host permissions? Default: the least the stories need.
  - Which settings, and which commands or menus in the host?
  - How is it packaged?
- **Checklist:**
  - [ ] Host and supported versions.
  - [ ] Extension points and manifest.
  - [ ] Activation events.
  - [ ] Permissions (least privilege).
  - [ ] Settings.
  - [ ] Commands or menus exposed in the host.
  - [ ] Packaging.
  - [ ] How to load it in the host's development mode.

## 8. Step 6: Constraints

- **Key:** `s6_constraints` · **Output:** `factory/input/06-constraints.md`, `factory/output/threat-model.md`
- **Goal:** every constraint that limits the solution, and the initial threat model.
- **Owners:** Product Owner (you lead, with `factory/core/roles/product-owner.md`) and Security.
- **Question bank:**
  - Deadlines and milestones?
  - Monthly infrastructure budget?
  - Compliance (LGPD, GDPR, PCI DSS, HIPAA, ...)?
  - Sensitive data types?
  - Data retention and deletion rules?
  - Password and session policies?
  - Audit logging needs?
  - Browser and device support matrix (only with `gui`)?
  - Performance budgets?
  - Availability expectations?
  - Locales?
  - Open-source license policy?
  - Third-party restrictions?
- **Delegation:** after the constraints are agreed, `security` writes the initial threat model (STRIDE-lite) in `factory/output/threat-model.md` from `factory/core/templates/threat-model.md`. Inputs: paths to `01`, `03` and `06`. Summarize the top risks for the user in at most 5 lines.
- **Quick mode:** draft common constraints (typical retention, session and password policies, no unusual compliance regime) marked as assumptions, instead of asking each topic; the threat model still runs as usual.
- **Checklist:**
  - [ ] Each topic of the question bank answered or marked "Not applicable".
  - [ ] Threat model written.
- **Config keys set:** none.

## 9. Step 7: Testing

- **Key:** `s7_testing` · **Output:** `factory/input/07-testing.md`
- **Goal:** how much the factory tests, where, and with which tools.
- **Owners:** Test Engineer. You lead the conversation: read `factory/core/roles/test-engineer.md` and follow its Discovery procedure.
- **First:** show the testing levels from `factory/core/modes.md` (section 5) and ask, recommending the value the process preset already wrote (`pipeline.preset`, `factory/core/modes.md` section 11). Write `testing.level`. If the level is `full`, ask for the coverage target (default 70) and write `testing.coverage_target`.
- **Quick mode:** use the preset's `testing.level` as the answer instead of asking; still confirm the coverage target in one line when the level is `full`.
- **Then:**
  1. Propose the critical areas (auth, payments, personal data, core business rules, data integrity) that apply to this product, and confirm them.
  2. List the E2E flows from the journeys in `01-product-vision.md`.
  3. Define the test data strategy (fixtures, factories, seeds, isolation per slot).
  4. Define the CI test policy (what runs on each push and pull request).
- **Checklist:**
  - [ ] Level (and coverage target when `full`).
  - [ ] Tools, taken from `04-stack-profile.md`.
  - [ ] Critical areas.
  - [ ] E2E flows.
  - [ ] Test data strategy.
  - [ ] CI policy.
- **Config keys set:** `testing.level`, `testing.coverage_target`.

## 10. Step 8: Backlog

- **Key:** `s8_backlog` · **Output:** `factory/tasks.md`, `factory/tasks-graph.md`
- **Goal:** an approved backlog with waves and checkpoints, and the execution settings.
- **Owners:** Architect (high tier) with the Product Owner's input; Backlog Validator (low tier).

Procedure:

1. Delegate to `architect`: generate `factory/output/drafts/backlog-draft.md` following `factory/core/workflow/backlog.md` (sections 1 and 3). Inputs: paths to all approved input files, `factory/output/architecture.md`, and, in `ongoing` projects, the accepted audit items.
2. Delegate to `backlog-validator`: check the draft against `factory/core/workflow/backlog.md` section 4. If it returns violations, send them to the `architect` to fix and validate again. At most 2 fix rounds; then show the remaining violations to the user and ask how to proceed.
3. Write `factory/tasks.md` (summary block plus the draft body) and generate `factory/tasks-graph.md` (`factory/core/workflow/backlog.md` section 2). Set `delivery.next_task_id` to the highest task number + 1 and `delivery.next_checkpoint_id` to the highest checkpoint number + 1.
4. Present the backlog: task count per wave, the foundation tasks, each proposed checkpoint with what it delivers, and the path `factory/tasks-graph.md` (it renders in VS Code's Markdown preview with a Mermaid extension, and on GitHub).
5. Ask the user to approve or adjust the backlog and the checkpoints. Apply adjustments through the `architect` and re-validate; small edits (a title, a checkpoint name) you make yourself.
6. Show the execution modes from `factory/core/modes.md` (section 3), then ask for the mode, and for `max_parallel_tasks` if `parallel`.
7. Show the approval modes (section 4), recommend `per_checkpoint`, and ask.
8. Write `execution.mode`, `execution.max_parallel_tasks` and `execution.approval_mode`.
9. List the other defaults that shape delivery, one line each, with their current values: bug threshold (`bugs.block_features_on`), `execution.max_rejections`, security review default (`security.review_default`), checkpoint audits (`security.audit_on_checkpoint`), AI co-author (`git.ai_coauthor`), checkpoint merge (`git.checkpoint_merge`). Say they can be changed now or at any time in `factory/config.yaml`. If the user changes one, show its mode description first.
10. On approval: mark the step approved, set `phase: delivery`, append a log line, and ask whether to start now. If yes, continue with `factory/core/workflow/delivery.md`.

- **Checklist:**
  - [ ] Validator returned `APPROVED`, or the user accepted the remaining violations.
  - [ ] `tasks.md` and `tasks-graph.md` written.
  - [ ] Backlog and checkpoints approved.
  - [ ] Execution mode, parallelism and approval mode written.
- **Config keys set:** `execution.mode`, `execution.max_parallel_tasks`, `execution.approval_mode` (and any default the user changes).
