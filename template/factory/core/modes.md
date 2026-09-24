# Selectable modes

**Rule for the Orchestrator:** every time the user chooses or changes one of these settings, show all options of the group with their summary, what happens, trade-offs and when to choose them, translated to `config.language`. Keep mode identifiers as-is, in backticks. Mark the recommended option. Then write the chosen value to the config key named in the group.

Sections: 1. Project type · 2. Execution · 3. Approval · 4. Testing level · 5. Design · 6. Security review depth · 7. Bug threshold · 8. Checkpoint merge · 9. Audit output

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

## 2. Execution

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

## 3. Approval

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

## 4. Testing level

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

## 5. Design

Config key: `design.mode` (and `design.review_ui_items`). Set in Discovery step 5.

| Option | Summary |
|---|---|
| `spec` | A text specification only. |
| `html_prototypes` | The factory also generates static HTML prototypes for you to approve. |
| `user_prototypes` | You put prototypes made in other tools into `factory/input/prototypes/`. |

- **What happens.** `spec`: the UX/UI Designer writes `factory/input/05-design-spec.md` (tokens, typography, components, flows, screens). `html_prototypes`: also generates one shared stylesheet from the design tokens and a static HTML file per key screen, which you open in a browser and approve; developers consult them. `user_prototypes`: you add exports, images or HTML from your own tools; the designer inventories them and extracts the spec.
- **Trade-offs.** `spec`: cheapest; you first see the look when the product runs. `html_prototypes`: costs tokens up front but catches layout and flow problems before any code exists. `user_prototypes`: best fidelity when you already have designs; costs your time to prepare them.
- **When to choose.** `spec` for internal tools, APIs and simple interfaces. `html_prototypes` when the interface matters and no designs exist. `user_prototypes` when a designer already made the screens.
- **`review_ui_items`.** `true` (default) adds a UX/UI review to every item that touches `ui/*`, before QA.
- **Recommended.** `spec` for most projects; `html_prototypes` when the product's interface is a key selling point.

## 6. Security review depth

Config key: `security.review_default`. Each task also carries its own `Security review` value.

| Option | Summary |
|---|---|
| `light` | Checklist review of the item's diff. |
| `required` | Checklist plus threat-model delta, abuse cases and data-flow tracing, on a high tier. |

- **What happens.** `light`: Security checks the diff against the light checklist in `factory/core/guidelines/security.md` (input validation, authn/authz, secrets, injection, XSS/CSRF, deserialization, new dependencies, sensitive logging, error leakage). `required`: all of that, plus a threat-model update, abuse cases, tracing data flows beyond the diff and dependency audit tools, at `security.required_review_tier`. The backlog marks auth, payments, personal data, uploads, untrusted parsing, crypto, secrets, permissions and public endpoints as `required` regardless of this default.
- **Trade-offs.** `light`: fast and cheap for ordinary changes. `required` everywhere: the deepest assurance, at a high-tier cost on every item.
- **When to choose.** `light` as the default for most products. `required` when the whole product handles sensitive data or regulated workloads.
- **Recommended.** `light`: sensitive items are already marked `required` individually.

## 7. Bug threshold

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

## 8. Checkpoint merge

Config key: `git.checkpoint_merge`.

| Option | Summary |
|---|---|
| `pr` | Open a pull request from develop to main with `gh` or `glab`. |
| `local` | Merge develop into main locally with `--no-ff`. |

- **What happens.** `pr`: when a remote and an authenticated `gh` (GitHub) or `glab` (GitLab) exist, the factory pushes both branches and opens a pull request whose body is the checkpoint report; after your approval it merges the pull request. Without a remote or an authenticated CLI it falls back to `local` until one is available. `local`: the factory merges on your machine and does not push.
- **Trade-offs.** `pr`: you review the diff on the hosting platform, CI runs on it, and history is visible to your team; needs a remote and CLI login. `local`: no network or accounts needed; you push when you want.
- **When to choose.** `pr` when the repository has a GitHub or GitLab remote. `local` for private experiments or other hosts.
- **Recommended.** `pr`: reviewable history and CI at every checkpoint, with an automatic local fallback.

## 9. Audit output

Not stored in the config: the Orchestrator asks each time an audit starts (`Audit`, or the offer for ongoing projects).

| Option | Summary |
|---|---|
| `report_first` | Write the audit report and let you choose which findings become bugs and tasks. |
| `tasks_directly` | Turn every finding into bugs and tasks right away. |

- **What happens.** `report_first`: the factory writes `factory/output/audits/AUDIT-<YYYY-MM-DD>.md`, shows a summary by severity, and waits for you to accept, reject or reprioritize findings. `tasks_directly`: same report, then every defect becomes a bug and every improvement a task with a new checkpoint, validated like any backlog change, and you are shown the result.
- **Trade-offs.** `report_first`: you stay in control of scope; costs one more round of conversation. `tasks_directly`: fastest; may add work you would have skipped.
- **When to choose.** `report_first` for existing products with many findings expected. `tasks_directly` when you want everything fixed and trust the priorities.
- **Recommended.** `report_first`: audits of existing code often find more than you want to fix at once.
