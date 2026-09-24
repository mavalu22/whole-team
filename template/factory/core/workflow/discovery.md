# Discovery

Read when `phase: discovery`, or when a `Change:` reopens a step. Each section stands alone: search this file by its exact path for the heading you need (for example `## 5. Step 3`) and read only that section plus sections 1 and 2.

Sections: 1. Rules · 2. Step procedure · 3. Step 1: Vision and scope · 4. Step 2: Stack · 5. Step 3: Platform and architecture · 6. Step 4: Stack profile · 7. Step 5: Design · 8. Step 6: Constraints · 9. Step 7: Testing · 10. Step 8: Backlog

## 1. Rules

- **Order.** Steps run in order 1 → 8. After step 1 is approved, ask whether the user wants to do Design (step 5) now, right after Vision, or later. If now, set `discovery.design_early: true` and run step 5 second; the order becomes 1, 5, 2, 3, 4, 6, 7, 8. Step numbers and keys never change.
- **One step at a time.** Never start a step before the previous one in the order is approved.
- **Questions.** Ask from the step's question bank in small batches (at most 4 per message), adapting to earlier answers. Propose a recommended answer or default for each question, so the user can reply "ok". Never ask what earlier inputs already answer; state the assumption instead and let the user correct it.
- **Writing.** Fill the step's input file (from the template already in `factory/input/`) in `state.input_language`. Record each answer with a small edit as soon as it is agreed; never rewrite the whole file. Keep the "Open questions" section until it is empty or the user accepts the remaining items as open.
- **Headings.** Translate section headings to `state.input_language` but keep their numbers and order (`## 5. Auth`). Front-matter keys stay English. Replace each guidance comment with content; write "Not applicable" with a one-line reason for sections that don't apply.
- **Approval.** Close each step with a summary of at most 15 lines and an explicit request: "Reply **approve** to continue, or tell me what to change."
- **Changes after approval.** An approved step changes only through `Change:` (`factory/core/workflow/change-requests.md`).
- **Checklists.** Each step has a completion checklist. Don't ask for approval until every item passes.
- **Delegated drafts.** When a role drafts a document, send it a task message (`factory/core/templates/task-message.md`) with `STAGE: DISCOVERY`, the answers agreed so far, and the paths of the approved input files it needs. Drafting roles write the input file directly; you then discuss it with the user and apply small corrections yourself. Re-delegate only when a correction needs the role's expertise (for example a different stack option).

## 2. Step procedure

For every step:

1. **Start.** In `factory/state.yaml`: set `discovery.current_step` to the step key and the step's `status: in_progress`. In the input file's front matter set `language:` to `state.input_language` if it is `null`.
2. **First.** Do the step's "First" actions, if any (for example, choose a mode).
3. **Ask.** Work through the question bank in batches, recording answers as they settle.
4. **Draft.** Delegate the drafts listed under "Delegation", if any, and review the result against the checklist.
5. **Check.** Run the checklist. Resolve gaps with the user or the drafting role.
6. **Approve.** Present the summary and ask for approval.
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
- **Goal:** platforms, architecture, components, data model, integrations and non-functional requirements, precise enough to generate the backlog.
- **Owners:** Architect drafts; DBA reviews the data model; you discuss with the user.
- **Question bank** (ask before delegating):
  - Which platforms: web (SPA/SSR), mobile (native or cross-platform), desktop, API-only, CLI? Responsive? PWA?
  - Expected users and load, now and in 12 months? Performance targets?
  - Which architecture style? Default recommendation: modular monolith unless justified.
  - What are the components and their boundaries?
  - What are the main data model entities?
  - Which integrations and API style (REST, GraphQL, RPC)?
  - Any need for realtime, background jobs, file storage, multi-tenancy, i18n, offline or notifications?
  - Which environments?
  - **Target hosting platform** (used later for the hosting guide)?
  - What observability is needed?
- **Delegation:**
  1. `architect`: draft `03-platform-architecture.md` and `factory/output/architecture.md` (from `factory/core/templates/architecture.md`), with a Mermaid component diagram, and write ADRs. Inputs: agreed answers, paths to `01-product-vision.md` and `02-stack.md`.
  2. `dba`: review the data model section (entities, relations, constraints, PII). Stage `DISCOVERY`.
  3. If the DBA returns findings, send them to the `architect` to fix (one round), then check again.
- **Checklist:**
  - [ ] Platforms and responsiveness.
  - [ ] Architecture style with rationale.
  - [ ] Mermaid component diagram.
  - [ ] Modules and boundaries.
  - [ ] Entities and relations, reviewed by the DBA.
  - [ ] Integrations and API style.
  - [ ] Cross-cutting needs (realtime, jobs, storage, tenancy, i18n, offline, notifications): each answered or "Not applicable".
  - [ ] Environments.
  - [ ] Target hosting platform.
  - [ ] Non-functional requirements (performance, availability, scalability, observability).
  - [ ] ADRs written; `factory/output/architecture.md` written.
- **Config keys set:** none.

## 6. Step 4: Stack profile

- **Key:** `s4_stack_profile` · **Output:** `factory/input/04-stack-profile.md`
- **Goal:** the exact conventions and commands every role agent follows. Role agents read this file on every item, so it must be precise and complete.
- **Owners:** Architect and Tech Lead draft.
- **Question bank:** preferred code style or strictness (for example TypeScript strict); folder structure preferences; lint and format preferences; pre-commit hooks, yes or no; preferred test tools, if any.
- **Delegation:**
  1. `architect`: draft folder structure, `Touches` vocabulary, commands, quiet command forms, tooling configuration, configuration and env, dependency policy, tooling exclusions for `factory/`, and parallel slot isolation.
  2. `tech-lead`: add or refine naming, error handling, logging, framework patterns and anti-patterns, and check that every command is exact and runnable for the stack.
- **Checklist:**
  - [ ] Folder structure and naming conventions.
  - [ ] `Touches` vocabulary: short, stable area names (`auth`, `db`, `api/<resource>`, `ui/<screen>`, `infra`, `ci`, ...).
  - [ ] Lint, format and type-check tools with their configuration choices.
  - [ ] Exact commands: install, dev, test, lint, type-check, format, build.
  - [ ] Quiet forms of the test, lint, type-check and build commands, printing only failures and a summary.
  - [ ] Error handling, logging, configuration and env patterns, dependency policy.
  - [ ] Framework patterns and anti-patterns.
  - [ ] Tooling exclusions for `factory/` (tests, linters, formatters, bundlers, Docker build context).
  - [ ] Slot runtime isolation: how to set the port and the database per slot (`FACTORY_SLOT`).
- **Config keys set:** none.

## 7. Step 5: Design

- **Key:** `s5_design` · **Output:** `factory/input/05-design-spec.md` (always), plus prototypes in `factory/input/prototypes/`
- **Goal:** a design system and screen list precise enough for developers and for UI reviews.
- **Owners:** UX/UI Designer. You lead the conversation: read `factory/core/roles/ux-ui-designer.md` and follow its procedure.
- **First:** show the three design modes from `factory/core/modes.md` (section 5) and ask the user to choose. Write `design.mode`.
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
- **Config keys set:** `design.mode`; `design.review_ui_items` if the user wants to change it (show its description from `factory/core/modes.md` section 5).

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
  - Browser and device support matrix?
  - Performance budgets?
  - Availability expectations?
  - Locales?
  - Open-source license policy?
  - Third-party restrictions?
- **Delegation:** after the constraints are agreed, `security` writes the initial threat model (STRIDE-lite) in `factory/output/threat-model.md` from `factory/core/templates/threat-model.md`. Inputs: paths to `01`, `03` and `06`. Summarize the top risks for the user in at most 5 lines.
- **Checklist:**
  - [ ] Each topic of the question bank answered or marked "Not applicable".
  - [ ] Threat model written.
- **Config keys set:** none.

## 9. Step 7: Testing

- **Key:** `s7_testing` · **Output:** `factory/input/07-testing.md`
- **Goal:** how much the factory tests, where, and with which tools.
- **Owners:** Test Engineer. You lead the conversation: read `factory/core/roles/test-engineer.md` and follow its Discovery procedure.
- **First:** show the testing levels from `factory/core/modes.md` (section 4) and ask. Write `testing.level`. If the level is `full`, ask for the coverage target (default 70) and write `testing.coverage_target`.
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
6. Show the execution modes from `factory/core/modes.md` (section 2), then ask for the mode, and for `max_parallel_tasks` if `parallel`.
7. Show the approval modes (section 3), recommend `per_checkpoint`, and ask.
8. Write `execution.mode`, `execution.max_parallel_tasks` and `execution.approval_mode`.
9. List the other defaults that shape delivery, one line each, with their current values: bug threshold (`bugs.block_features_on`), `execution.max_rejections`, security review default (`security.review_default`), checkpoint audits (`security.audit_on_checkpoint`), AI co-author (`git.ai_coauthor`), checkpoint merge (`git.checkpoint_merge`). Say they can be changed now or at any time in `factory/config.yaml`. If the user changes one, show its mode description first.
10. On approval: mark the step approved, set `phase: delivery`, append a log line, and ask whether to start now. If yes, continue with `factory/core/workflow/delivery.md`.

- **Checklist:**
  - [ ] Validator returned `APPROVED`, or the user accepted the remaining violations.
  - [ ] `tasks.md` and `tasks-graph.md` written.
  - [ ] Backlog and checkpoints approved.
  - [ ] Execution mode, parallelism and approval mode written.
- **Config keys set:** `execution.mode`, `execution.max_parallel_tasks`, `execution.approval_mode` (and any default the user changes).
