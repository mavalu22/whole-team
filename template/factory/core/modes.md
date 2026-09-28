# Selectable modes

**Rule for the Orchestrator:** every time the user chooses or changes one of these settings, show all options of the group with their summary, what happens, trade-offs and when to choose them, translated to `config.language`. Keep mode identifiers as-is, in backticks. Mark the recommended option. Then write the chosen value to the config key named in the group.

Sections: 1. Project type · 2. Interfaces · 3. Execution · 4. Approval · 5. Testing level · 6. Design · 7. Security review depth · 8. Bug threshold · 9. Checkpoint merge · 10. Audit output · 11. Process preset · 12. Delivery stages · 13. UX check · 14. Task size · 15. Discovery quick mode

## 1. Project type

Config key: `project.type`. Set by the installer; change it only by reinstalling or by hand before Discovery starts.

| Option | Summary |
|---|---|
| `new` | A new product; Discovery starts from the idea. |
| `ongoing` | An existing codebase; Discovery starts by analysing the code. |

- **What happens.** `new`: Discovery runs all 8 steps as conversations, and kickoff creates the integration branch without asking. `ongoing`: the Architect analyses the repository and drafts the stack, architecture and stack profile (marked `(inferred)`) for you to confirm; the factory records a test, lint and build baseline and offers a bug and security audit. Kickoff asks before committing `.gitignore` or creating branches.
- **Trade-offs.** `new` costs more conversation up front but starts from a clean slate. `ongoing` saves questions because the code answers many of them, and adds the cost of the analysis and the optional audit.
- **When to choose.** `new` when there is no product code yet, or when you will start over. `ongoing` when there is code the product must keep.
- **Recommended.** Whichever matches the repository. The installer asks.

## 2. Interfaces

Config key: `project.interfaces`, a list of one or more options. Set in Discovery step 3; in `ongoing` projects, asked before the code analysis. Combinations are normal: a web app with a public API is `[gui, api]`, a VS Code extension with a webview is `[plugin, gui]`.

| Option | Summary |
|---|---|
| `gui` | Screens used by people: web, mobile or desktop apps, a plugin's panels or webviews. |
| `api` | A network interface other software calls: REST, GraphQL, gRPC, webhooks. |
| `cli` | A command-line program: developer tools, admin scripts, installers. |
| `service` | A process with no direct user interface, driven by events or schedules: queue workers, cron jobs, stream processors, daemons. |
| `library` | Code other code imports: npm, PyPI, crates.io, Maven or NuGet packages, SDKs. |
| `plugin` | An extension loaded by a host application: VS Code or JetBrains extensions, browser extensions, WordPress plugins. |

- **What happens.** Each interface gets its own part of the spec in Discovery step 5, its own foundation task, review rules, tests and QA procedure, and a block in the checkpoint report's "How to try it".
  - `gui`: the UX/UI Designer designs the screens (design mode, tokens, components, flows) and reviews every `ui/*` item.
  - `api`: step 5 defines the contract (resources, errors, versioning, pagination, auth); the Tech Lead reviews `api/*` items against it; QA sends requests to the running service.
  - `cli`: step 5 defines the command tree, flags, exit codes and output formats; QA runs the commands and checks exit codes and output.
  - `service`: step 5 defines inputs, outputs, triggers, delivery guarantees and health checks; QA feeds test inputs through the trigger.
  - `library`: step 5 defines the public API and the version policy; QA installs the local package into a throwaway project; the checkpoint guide covers publishing instead of hosting.
  - `plugin`: step 5 defines the host, the manifest, activation and permissions; QA loads it in the host's development mode; the guide covers publishing.
- **Trade-offs.** Every interface is a surface to design, test and keep compatible, so each one adds spec work and checks. `library` and `plugin` releases are hard to take back once published, so their version policy matters from the start. A `plugin` depends on its host: checks the host cannot run headless become checks you do at checkpoints.
- **When to choose.** List what the product exposes to people or to other software, not its internal parts: a web app's own backend is part of `gui` unless other software calls it too.
- **Recommended.** Whatever matches the product. The default is `[gui]`.

## 3. Execution

Config keys: `execution.mode`, `execution.max_parallel_tasks`. Set in Discovery step 8.

| Option | Summary |
|---|---|
| `sequential` | One item at a time, in your working copy. |
| `parallel` | Several independent items at once, each in its own git worktree. |

- **What happens.** `sequential`: the factory creates the item's branch in your working copy, runs every stage, merges, then picks the next item. `parallel`: independent items (no shared dependencies, no overlapping `Touches`, no checkpoint in between) run at the same time, each in `factory/.worktrees/<ID>` with its own ports and database; the Orchestrator merges them one at a time.
- **Trade-offs.** `sequential`: lowest token use, easiest to follow, slowest wall-clock time. `parallel`: faster, but uses more tokens (each item keeps its own agents and dependency install), and you must not edit files in the main working copy while it runs. Quality is the same: every item goes through the same gates.
- **When to choose.** `sequential` for small backlogs, tight usage limits, or when you want to watch each change. `parallel` for larger backlogs with wide waves, when time matters more than tokens.
- **`max_parallel_tasks`.** Items in progress at once (default 3). Use 2-3 on a laptop or a limited plan; 4-5 only when waves are wide, the machine can run several copies of the product, and your plan has headroom. More than the widest wave gains nothing.
- **Recommended.** `sequential`: cheapest and easiest to follow; switch to `parallel` any time by editing the config.

## 4. Approval

Config key: `execution.approval_mode`. Set in Discovery step 8.

| Option | Summary |
|---|---|
| `per_task` | Stop before each task or bug is merged into develop, and at every checkpoint. |
| `per_checkpoint` | Stop only at checkpoints. |
| `none` | Never stop; checkpoints still merge develop into main. |

- **What happens.** `per_task`: after SEC, each item waits in `AWAITING_APPROVAL` with a short summary (what changed, how to try it, test results); your feedback sends it back to development without counting as a rejection. `per_checkpoint`: items merge into develop as soon as they pass the gates; at each checkpoint the factory stops with a report and a validation checklist. `none`: the factory runs every checkpoint procedure (audit, verification, docs, report) and merges into main without waiting.
- **Trade-offs.** `per_task`: most control, slowest, and costs more of your time. `per_checkpoint`: you validate working increments; problems found go through `Support:`. `none`: fastest; you review only the reports afterwards, so mistakes travel further before you see them.
- **When to choose.** `per_task` for sensitive products or when you are learning how the factory works. `per_checkpoint` for most projects. `none` for prototypes or when you will review the result as a whole.
- **Recommended.** `per_checkpoint`: every increment gets your validation while the factory keeps moving between checkpoints.

## 5. Testing level

Config keys: `testing.level`, `testing.coverage_target`. Set in Discovery step 7.

| Option | Summary |
|---|---|
| `none` | No automated tests; QA validates by running the product. |
| `critical` | Automated tests only for items marked `Critical: yes`. |
| `full` | Automated tests for every item; the whole suite runs on every merge and at every checkpoint. |

- **What happens.** `none`: the TEST stage is skipped, and QA verifies every acceptance criterion by running the product. `critical`: the Test Engineer writes tests before implementation for critical items (auth, payments, personal data, core business rules, data integrity) and a regression test for every bug. `full`: tests for every item except `docs` items, the full suite on every merge and checkpoint, and `coverage_target` enforced at checkpoints.
- **Trade-offs.** `none`: cheapest and fastest; regressions are caught only by manual QA. `critical`: protects what hurts most when it breaks, at moderate cost. `full`: strongest safety net and easiest future changes; the most tokens and time per item.
- **When to choose.** `none` for throwaway prototypes. `critical` for most MVPs. `full` for products that will live long, handle money or sensitive data, or change often.
- **`coverage_target`.** Minimum line coverage (%) checked at checkpoints with `full` (default 70). 60-80 is a practical range; 0 disables the check. Higher numbers cost more tests without proportionate safety.
- **Recommended.** `critical`: most of the protection for a fraction of the cost.

## 6. Design

Config key: `design.mode`. Set in Discovery step 5, only when the product has `gui`.

| Option | Summary |
|---|---|
| `spec` | A text specification only. |
| `html_prototypes` | The factory also generates static HTML prototypes for you to approve. |
| `user_prototypes` | You put prototypes made in other tools into `factory/input/prototypes/`. |

- **What happens.** `spec`: the UX/UI Designer writes `factory/input/05-design-spec.md` (tokens, typography, components, flows, screens). `html_prototypes`: also generates one shared stylesheet from the design tokens and a static HTML file per key screen, which you open in a browser and approve; developers consult them. `user_prototypes`: you add exports, images or HTML from your own tools; the designer inventories them and extracts the spec.
- **Trade-offs.** `spec`: cheapest; you first see the look when the product runs. `html_prototypes`: costs tokens up front but catches layout and flow problems before any code exists. `user_prototypes`: best fidelity when you already have designs; costs your time to prepare them.
- **When to choose.** `spec` for internal tools, APIs and simple interfaces. `html_prototypes` when the interface matters and no designs exist. `user_prototypes` when a designer already made the screens.
- **`review_ui_items`.** Deprecated since 1.3.0 and no longer read. The UI conformance check is now `pipeline.ux_check` (section 13).
- **Recommended.** `spec` for most projects; `html_prototypes` when the product's interface is a key selling point.

## 7. Security review depth

Config key: `security.review_default`. Each task also carries its own `Security review` value.

| Option | Summary |
|---|---|
| `light` | Checklist review of the item's diff. |
| `required` | Checklist plus threat-model delta, abuse cases and data-flow tracing, on a high tier. |

- **What happens.** `light`: Security checks the diff against the light checklist in `factory/core/guidelines/security.md` (input validation, authn/authz, secrets, injection, XSS/CSRF, deserialization, new dependencies, sensitive logging, error leakage). `required`: all of that, plus a threat-model update, abuse cases, tracing data flows beyond the diff and dependency audit tools, at `security.required_review_tier`. The backlog marks auth, payments, personal data, uploads, untrusted parsing, crypto, secrets, permissions and public endpoints as `required` regardless of this default.
- **Trade-offs.** `light`: fast and cheap for ordinary changes. `required` everywhere: the deepest assurance, at a high-tier cost on every item.
- **When to choose.** `light` as the default for most products. `required` when the whole product handles sensitive data or regulated workloads.
- **Recommended.** `light`: sensitive items are already marked `required` individually.

## 8. Bug threshold

Config key: `bugs.block_features_on`.

Priority definitions:

- **P0:** crash, data loss, security hole, or the product is unusable.
- **P1:** a major feature is broken and there is no workaround.
- **P2:** broken but a workaround exists, or a minor feature is affected.
- **P3:** cosmetic or trivial.

| Option | Summary |
|---|---|
| `P0` | Only blockers stop feature work. |
| `P1` | Blockers and major bugs stop feature work. |
| `P2` | Also minor bugs with a workaround stop feature work. |
| `P3` | Every bug stops feature work. |

- **What happens.** Bugs at the threshold or more severe are **blocking**: they run before any new task starts (P0 first), and a checkpoint cannot complete while one is open. Less severe bugs wait until all tasks are done, unless you ask for one with `Let's code B-<id>`.
- **Trade-offs.** A lower threshold (`P0`) delivers features fastest but lets known bugs pile up. A higher threshold (`P2`, `P3`) keeps quality high at every checkpoint but slows new features.
- **When to choose.** `P0` for a quick demo. `P1` for most products. `P2` or `P3` for polished releases or products already in use.
- **Recommended.** `P1`: nothing major stays broken, and cosmetic issues don't stall progress.

## 9. Checkpoint merge

Config key: `git.checkpoint_merge`.

| Option | Summary |
|---|---|
| `pr` | Open a pull request from develop to main with `gh` or `glab`. |
| `local` | Merge develop into main locally with `--no-ff`. |

- **What happens.** `pr`: when a remote and an authenticated `gh` (GitHub) or `glab` (GitLab) exist, the factory pushes both branches and opens a pull request whose body is the checkpoint report; after your approval it merges the pull request. Without a remote or an authenticated CLI it falls back to `local` until one is available. `local`: the factory merges on your machine and does not push.
- **Trade-offs.** `pr`: you review the diff on the hosting platform, CI runs on it, and history is visible to your team; needs a remote and CLI login. `local`: no network or accounts needed; you push when you want.
- **When to choose.** `pr` when the repository has a GitHub or GitLab remote. `local` for private experiments or other hosts.
- **Recommended.** `pr`: reviewable history and CI at every checkpoint, with an automatic local fallback.

## 10. Audit output

Not stored in the config: the Orchestrator asks each time an audit starts (`Audit`, or the offer for ongoing projects).

| Option | Summary |
|---|---|
| `report_first` | Write the audit report and let you choose which findings become bugs and tasks. |
| `tasks_directly` | Turn every finding into bugs and tasks right away. |

- **What happens.** `report_first`: the factory writes `factory/output/audits/AUDIT-<YYYY-MM-DD>.md`, shows a summary by severity, and waits for you to accept, reject or reprioritize findings. `tasks_directly`: same report, then every defect becomes a bug and every improvement a task with a new checkpoint, validated like any backlog change, and you are shown the result.
- **Trade-offs.** `report_first`: you stay in control of scope; costs one more round of conversation. `tasks_directly`: fastest; may add work you would have skipped.
- **When to choose.** `report_first` for existing products with many findings expected. `tasks_directly` when you want everything fixed and trust the priorities.
- **Recommended.** `report_first`: audits of existing code often find more than you want to fix at once.

## 11. Process preset

Config key: `pipeline.preset`. Set at kickoff, right after the language; change it any time with the `Process` command.

| Option | Summary |
|---|---|
| `mvp` | Fastest process: prototypes, MVPs, personal tools. |
| `standard` | Balanced process: marketing or portfolio sites, internal tools, small apps. |
| `complete` | Full process (every gate, today's flow): products with users' data, payments, compliance, or a team depending on them. |
| `custom` | Set every key below yourself. |

- **What happens.** Choosing `mvp`, `standard` or `complete` writes `pipeline.stages`, `pipeline.ux_check`, `pipeline.task_size`, `pipeline.critical_full_pipeline`, `testing.level`, `security.audit_on_checkpoint` and `discovery.quick_steps` to the preset's values (table below); you still confirm `testing.level` at Discovery step 7. `custom` asks each of those settings in turn (`pipeline.stages`: section 12; `pipeline.ux_check`: section 13; `pipeline.task_size`: section 14; `testing.level`: section 5; `discovery.quick_steps`: section 15; `pipeline.critical_full_pipeline` and `security.audit_on_checkpoint` as described above), then enforces the safety nets: at least one gate besides DEV, and a UX check only where its stage runs.

| Setting | `mvp` | `standard` | `complete` |
|---|---|---|---|
| `pipeline.stages` | `[review]` | `[review, qa]` | `[test, review, qa, sec]` |
| `pipeline.ux_check` | `none` | `qa` | `review` |
| `pipeline.task_size` | `feature` | `feature` | `session` |
| `pipeline.critical_full_pipeline` | `true` | `true` | `true` |
| `testing.level` | `none` | `critical` | the Discovery step 7 answer (default `critical`) |
| `security.audit_on_checkpoint` | `false` | `true` | `true` |
| `discovery.quick_steps` | `[s4_stack_profile, s6_constraints, s7_testing]` | `[s6_constraints, s7_testing]` | `[]` |

- **Trade-offs.** `mvp`: fastest and cheapest, with only one gate (REVIEW) and no automated tests; fine for throwaway or low-stakes work, risky for anything users depend on. `standard`: a second gate (QA) and critical-path tests, for products with real but modest stakes. `complete`: every gate, and tests as Discovery step 7 decides; the most protection, at the highest per-item cost. `custom`: exactly the process you want, at the cost of choosing it yourself and keeping it coherent.
- **Safety nets**, kept in every preset including `custom`: at least one gate besides DEV; a required security review always runs SEC; a critical item always runs every stage when `pipeline.critical_full_pipeline` is true; checkpoints always verify, audit (per `security.audit_on_checkpoint`) and report.
- **When to choose.** `mvp` for a prototype, a personal tool, or code nobody but you depends on. `standard` for most products: marketing sites, internal tools, small apps with some real users. `complete` for anything that stores user data, moves money, must meet a compliance regime, or that a team relies on. `custom` when a project's needs don't match a preset, for example a `complete` product that also wants `task_size: feature`.
- **Recommended.** `standard` as a starting point when the product's stakes aren't yet clear; `complete` for anything sensitive from the first task.

## 12. Delivery stages

Config key: `pipeline.stages`, a list from `test`, `review`, `qa`, `sec`. Part of a preset, or set directly with `custom`.

- **What happens.** Every item runs DEV, then the stages in this list, in order (`test`, `review`, `qa`, `sec`), skipping the rest, then APPROVAL when `execution.approval_mode` asks for it, then MERGE; DEV and MERGE always run. A stage left out is never delegated and leaves no status or history line for that item, except: a required security review still runs SEC even when `sec` is off, and a critical item runs every stage when `pipeline.critical_full_pipeline` is true.
- **Trade-offs.** Every stage you drop saves the fixed cost of a fresh agent and a review round, at the cost of that check. `test` off means no automated tests unless `testing.level` still requires them for the item (the Developer then writes them in DEV). `review` off removes the only code-quality gate; `qa` off removes the only running-product verification; `sec` off removes review of ordinary items (required reviews still run).
- **When to choose.** Keep `review` or `qa` (or both): the factory refuses to drop the last gate besides DEV. Add `test` when regressions are costly to find by hand. Add `sec` when most items touch sensitive code, instead of relying on the per-item required flag alone.
- **Recommended.** `[review, qa]` for most products (the `standard` preset); `[test, review, qa, sec]` for anything sensitive (the `complete` preset).

## 13. UX check

Config key: `pipeline.ux_check`.

| Option | Summary |
|---|---|
| `review` | The UX/UI Designer reviews every `ui/*` item in REVIEW. |
| `qa` | QA applies the UX checklist and the design spec; no separate designer review. |
| `none` | No UX conformance check. |

- **What happens.** `review`: the UX/UI Designer joins REVIEW for items touching `ui/*`. `qa`: the UX/UI Designer is not added to REVIEW; QA applies `factory/core/guidelines/ui-ux-and-accessibility.md` and the item's screens in `05-design-spec.md` itself. `none`: neither role checks UI conformance; only the acceptance criteria are verified.
- **Trade-offs.** `review`: a specialist check, at the cost of one more reviewer. `qa`: folds the check into a stage that already runs, cheaper but less specialized. `none`: cheapest, and risks visual and accessibility regressions nobody catches.
- **Constraints.** `qa` requires `qa` in `pipeline.stages`; `review` requires `review` in it.
- **When to choose.** `review` for products where the interface is a selling point. `qa` for most `gui` products, to save a reviewer without dropping the check. `none` only for internal tools or prototypes where appearance doesn't matter.
- **Recommended.** `qa`: most of the protection, without a dedicated reviewer.

## 14. Task size

Config key: `pipeline.task_size`.

| Option | Summary |
|---|---|
| `session` | Every task fits one focused agent session. |
| `feature` | A task is a whole user-visible feature or page. |

- **What happens.** `session`: today's rule (`factory/core/workflow/backlog.md` section 3, rule 4): one vertical slice, at most about 7 acceptance criteria, roughly 8 production files or fewer. `feature`: a task covers one user-visible feature, page or capability with everything it needs (layout, content, styles, data, its tests at the testing level); work that would be reviewed together stays in one task instead of being split.
- **Trade-offs.** `session`: more tasks and more review rounds, each small and easy to verify, at a higher fixed cost per unit of work. `feature`: fewer, larger tasks and fewer gate rounds, at the cost of a bigger diff per review and a longer session per task.
- **When to choose.** `session` for complex, high-stakes work where small, reviewable steps matter. `feature` for simple products where most of the cost is process overhead, not the work itself.
- **Recommended.** `feature` for `mvp` and `standard` projects; `session` for `complete` projects, where every gate already runs.

## 15. Discovery quick mode

Config key: `discovery.quick_steps`, a list of step keys from `s3_architecture`, `s4_stack_profile`, `s5_design`, `s6_constraints`, `s7_testing`. Steps 1, 2 and 8 always run in full.

- **What happens.** A quick step still produces its full output document, because later stages and agents depend on it. Instead of working through the question bank, the owner drafts it from the answers already agreed, the stack's conventions and the documented defaults; the Orchestrator shows a summary of at most 10 lines with the choices that matter most, and you approve or correct it in one reply. The step's checklist still applies before it can be approved.
- **Trade-offs.** Fewer questions and a shorter Discovery, at the cost of more defaults chosen for you; a wrong default costs a `Change:` later instead of a question now.
- **When to choose.** Quick mode for steps where the stack, the product type or common practice already answers most questions (the stack profile's commands, common constraints, the testing level). Keep a step out of quick mode when its answers are unusual or you want to be asked.
- **Recommended.** Set by the pipeline preset (section 11); adjust it with `custom` or the `Process` command.
