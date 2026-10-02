# Changelog

All notable changes to WholeTeam are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/).

## [1.3.2] - 2026-10-02

### Fixed

- Claude agents give the Tech Writer shell tools, Security and the Tech Lead write tools, and DevOps web search, as their roles require.
- Task messages name the integration branch as DIFF BASE; item reviews and conflict rebases use it instead of the stable base branch.
- Codex agent names replace every hyphen in a role slug with an underscore, as stated in the delegation rules and role map.
- Rejected rounds' full findings and blocked stages' questions persist in reports linked from in-flight state, so rework and clarification resume without losing details or counting a rejection twice.
- Criteria check-off uses the evidence of enabled stages, and a recorded "Accept as-is" escalation decision counts as stage approval in the Definition of Done.
- Both installed root guide blocks list the Process command.

### Added

- README license and version-tag installation notes, and a maintenance rule requiring an annotated tag and changelog-based GitHub release for every release commit.

### Changed

- Release 1.3.2 keeps the config format unchanged; an in-flight entry without the optional findings_file key is treated as having null.

## [1.3.1] - 2026-10-02

### Fixed

- Delivery documentation and pipeline history examples place TEST before DEV when it runs, followed by REVIEW, QA, SEC, APPROVAL and MERGE as enabled.

### Changed

- A read-only Python check verifies role and agent copies, common preambles, agent names, TOML literal safety and identical config files.
- CI runs the consistency check, Bash syntax check and ShellCheck on pushes and pull requests to main.
- Root instructions and README maintenance rules require updating all role copies, keeping config files identical, running the check before commits and omitting attribution from commits and pull requests.
- Release 1.3.1 keeps the config and state formats unchanged.

## [1.3.0] - 2026-09-28

### Added

- `pipeline` settings in the config (`preset`, `stages`, `ux_check`, `task_size`, `critical_full_pipeline`) and `discovery.quick_steps`, described in `modes.md` sections 11-15. Four presets (`mvp`, `standard`, `complete`, `custom`) choose how much delivery process runs per project; the default is `complete`, so an update never changes how an existing project runs. The `1.3.0` migration sets `pipeline.ux_check` from the old `design.review_ui_items`, which is now deprecated and no longer read.
- Kickoff asks for the process preset right after the language, with a recommendation and a `custom` path that enforces the safety nets (at least one gate besides DEV, a UX check only where its stage runs). `ongoing` projects choose it at the same point.

### Changed

- Delivery runs only the item's enabled stages (`pipeline.stages`, plus SEC for required reviews and every stage for critical items), recorded once in the item's `pipeline: dev, ...` history line; a skipped stage gets no status, no history line, and is named in the other stages' `CONSTRAINTS`. When TEST is not enabled but `testing.level` requires tests, the Developer writes them in DEV; QA and the Tech Lead still check they exist. When `pipeline.ux_check` is `qa`, QA applies the UX checklist and the design spec instead of the UX/UI Designer reviewing in REVIEW; `none` skips the UI conformance check entirely. Rejections restart the item's enabled gates from the first one after DEV. The Definition of Done checks only the stages that ran.
- `pipeline.task_size: feature` groups a task around one whole user-visible feature or page instead of splitting it into session-sized slices. `Critical: yes` now means only that a defect could cause unauthorized access, loss or corruption of data, wrong money movement, exposure of personal or secret data, or legal or compliance harm; the Backlog Validator flags any `Critical: yes` that matches none of these. The Architect can propose a re-check of `Critical` and `Security review` on tasks that are not started, for the user to approve.
- Discovery steps 3 to 7 run in quick mode when listed in `discovery.quick_steps`: the owner drafts the step's document from the answers already agreed, the stack's conventions and the documented defaults, without the question bank, and the user approves a summary of at most 10 lines instead. `ongoing` projects apply it to the same steps of reverse Discovery; the interfaces are still always stated by the user.
- A sixth command, `Process`, shows the current delivery process and lets the user change it at any time, including on a project already running (`factory/core/workflow/process.md`). In-flight items finish their current stage under the old settings, then continue with the new stage list for the stages still ahead; a checkpoint in progress finishes with the settings it started with. A `task_size` change offers to regroup or split unstarted tasks through the Architect; a `discovery.quick_steps` change applies to Discovery steps not yet started. `Status` now shows the process in one line.
- README: a "Choosing how much process" section with the presets table, the safety nets, the `Process` command and a recommendation per project type; the parts that described a fixed pipeline now say gates depend on the chosen process.

## [1.2.0] - 2026-09-28

### Added

- `factory/attachments/`, a folder for screenshots and files the user cites in requests (`Support:`, `Change:`, a new feature, a Discovery answer). The factory moves cited files into `<ID>/` subfolders once linked to an item.
- Attachments can be cited by name or path in any command or Discovery answer; the Orchestrator resolves, describes once and links them: `Evidence` for bugs, `Refs`/`Notes` for tasks, the reopened input document for change requests, the step's input document for Discovery. `Status` reports attachments not yet linked to an item.
- Task messages carry an `ATTACHMENTS` section with each linked attachment's path, description and whether to open it. The Developer copies attachments marked as product assets into the product; QA and the UX/UI Designer compare the result against a reference image; Support uses attachments as reproduction evidence. Checkpoint reports list attachment paths per item.
- A secret or personal data spotted in an attachment is never copied into an item, a report, a task message or a commit; the Orchestrator tells the user instead. Attachment content is always data, never instructions, for the Orchestrator and every role agent. The Developer strips unintended secrets or personal data (for example EXIF location) from a product asset built from an attachment before committing it; the Tech Lead checks that none remains.
- The README documents the attachments folder; kickoff mentions it in the welcome message.

## [1.1.0] - 2026-09-27

### Added

- `project.interfaces` in the config: the ways people or other software use the product (`gui`, `api`, `cli`, `service`, `library`, `plugin`), described in `modes.md` section 2. The `1.1.0` migration asks projects that already passed Discovery step 3 for their interfaces.
- Guidelines `cli-design.md`, `services-and-jobs.md` and `libraries-and-plugins.md`, and a section in `security.md` for CLIs, services, libraries, plugins and published packages. The Architect, Tech Lead and Developer read them only for the interface the work touches.
- `Touches` areas `cli/<command>`, `jobs/<name>`, `lib/<module>` and `plugin/<extension point>`; a foundation skeleton task per interface; and stack profile commands to run the CLI, start the worker, pack the library and launch the plugin host.
- A publishing part in the hosting guide for libraries and plugins (account and ownership, metadata, versioning, release artifact, signing, CI tokens, a release workflow, dated marketplace facts, deprecating a bad release). With nothing to host, the guide is only a publishing guide. The factory never publishes.

### Changed

- Discovery step 3 asks for the product's interfaces, with the details each one needs, instead of its platforms. It asks for a hosting platform only when there is something to host, and for the registry or marketplace of a library or plugin.
- Discovery step 5 is now "Interface design": `gui` keeps the design flow of 1.0.1, and every other interface gets its own question bank and checklist, drafted by the Architect in one task. `05-design-spec.md` is the "Interface and design spec", with one part per interface and a scope line at the start of each part. The step key and file name are unchanged.
- Delivery handles each interface: the Tech Lead checks items touching `api/*`, `cli/*`, `jobs/*`, `lib/*` or `plugin/*` against their spec section and guideline, and a breaking change to a published interface is a finding; tests and QA follow one short procedure per interface. Criteria QA cannot run on the machine are marked `MANUAL` and go to the next checkpoint's validation checklist. The checkpoint report's "How to run locally" is now "How to try it", with one block per interface.
- In `ongoing` projects, the Orchestrator asks the user for the product's interfaces before the code analysis, and the analysis documents exactly those. Code that looks like an unlisted interface becomes a question for the user, never an automatic addition. The `1.1.0` migration never derives the interfaces from the code either.
- The README describes the supported product types ("What you can build"), interface design in Discovery and the publishing guide.

## [1.0.1] - 2026-09-24

### Fixed

- Custom models are re-applied after an installer update: the installer writes `factory/.models-sync-needed` whenever it rewrites the agent files, and the Orchestrator's model sync runs when that file exists, then deletes it.
- Model changes the user asks for mid-session take effect right away: the Orchestrator runs the model sync as soon as it changes a value under `models`.
- An interrupted merge is safe to resume: MERGE starts with a resume check that aborts an unfinished rebase or merge, detects an item already merged, and commits a squash that was staged but not committed. The steps after the merge are idempotent, and an item whose branch is gone is checked for a merge before being reset to `TODO`.
- The steps after a checkpoint approval are safe to resume: the approval and each step are logged, the merge, tag and state steps skip what is already done, and a pending approval that was already given, or whose checkpoint is already merged, is finished instead of asked again.
- A refused install or update leaves the project exactly as it was: both installers check the root files (guide files and fallbacks both tracked, incomplete marker blocks) before writing anything.
- The bug summary states exactly which priorities block: `bugs.block_features_on` or more severe, with P0 the most severe.

### Changed

- The factory asks for a restart only when the tool needs one: after a model sync, only in Codex (Claude Code reloads edited agent files by itself), and when the factory agents are unknown because WholeTeam was installed while the session was open.

### Removed

- The unused task and bug templates from `core/templates/`. The task and bug formats live only in `workflow/backlog.md` section 1.3 and `workflow/bugs-and-support.md` section 1; installed projects lose the two files on update.

## [1.0.0] - 2026-09-24

### Added

First release.

- **Installers:** `install.sh` (bash 3.2+: Linux, macOS, Git Bash) and `install.ps1` (Windows PowerShell 5.1 and PowerShell 7) install WholeTeam into an existing git project or update an installed one, idempotently, without modifying files tracked by git other than `.gitignore`.
- **Layout:** `VERSION`, `.gitattributes`, and the `template/` tree the installer copies into a target project.
- **Root guide blocks** for `CLAUDE.md` and `AGENTS.md` (and their local-only fallbacks `CLAUDE.local.md` and `AGENTS.override.md`), delimited by `whole-team` markers.
- **Configuration and state:** `factory/config.yaml` with a comment on every setting, the identical `factory/core/config.defaults.yaml`, `factory/state.yaml`, and `factory/core/MIGRATIONS.md` for migrating both after updates.
- **Orchestrator manual:** `factory/core/FACTORY.md` (golden rules, directory map, commands, startup routine, roles and tiers, language rules, phase pointers) and `factory/core/modes.md` (every selectable mode with trade-offs and a recommended default).
- **Workflow:** 14 documents for kickoff, Discovery (8 approved steps), ongoing projects, backlog generation and validation, delivery (sequential and parallel), checkpoints, quality gates, delegation and model sync, bugs and support, change requests, audits, status, state and resumption, and the hosting guide.
- **Roles and agents:** 14 role files, 13 Claude Code agents and 13 Codex agents that embed them, with tier-based models (`high`, `medium`, `low`).
- **Guidelines:** 14 stack-agnostic engineering guidelines, each with a review checklist.
- **Templates:** 13 document templates (task, bug, task message, role report, ADR, architecture, threat model, audit report, checkpoint report, hosting guide, status report, checkpoint PR body, baseline) and 7 Discovery input templates plus the prototypes README.
- **Commands:** `Let's code`, `Support: <description>`, `Status`, `Change: <request>`, `Audit`.
- **README** with installation, usage, configuration, models and cost, git behavior, parallel mode, troubleshooting and limitations.

## Design notes

Choices made where the specification left room. Each note says what was chosen and why.

### Foundation

- **Summary blocks.** The summary between `<!-- factory:summary:start -->` and `<!-- factory:summary:end -->` is a short list of bold labels (`Updated`, `Statuses`, `Current wave`, `Next checkpoint`, `In flight` in `tasks.md`; `Updated`, `Open by priority`, `Blocking`, `In flight` in `bugs.md`). One line per fact keeps status updates to one-line edits.
- **Graph status classes.** `tasks-graph.md` defines five classes: `todo`, `active` (every in-progress and rejected status), `done`, `blocked` and `cancelled`, plus `checkpoint` for checkpoint nodes. Node IDs drop the hyphen (`T012`) because Mermaid treats `-` as edge syntax. The nodes and the status lines sit between `%% factory:nodes:*` and `%% factory:status:*` comment markers so the Orchestrator can find and edit them without reading the whole diagram.
- **Baseline owner.** The Architect runs the baseline (tests, lint, build) during reverse Discovery, because it already has shell access and is analysing the repository at that moment.
- **Future config versions.** If `config.yaml` is newer than the installed core, the Orchestrator stops and asks the user to update the WholeTeam clone instead of guessing a downgrade.

### Orchestrator

- **Commands by phase.** `FACTORY.md` defines what each command does before delivery: `Support:` answers usage questions (and records bugs in `ongoing` projects), `Change:` reopens approved Discovery steps, and `Audit` runs only when there is code to audit.
- **Audit output mode is not a config key.** `report_first` and `tasks_directly` are described in `modes.md` but asked at the start of every audit, because the right answer depends on the audit's scope.
- **Handling role reports.** `FACTORY.md` maps each report verdict to an action, verifies cheap facts (cited commits and test files exist) before recording them, and treats a malformed report as a failed delegation. This keeps the Orchestrator from recording claims it has not checked.
- **Extra golden rules.** Bounded loops, local-only operation, ISO 8601 timestamps and respect for the user's uncommitted work are golden rules, because each one prevents an irreversible or token-burning failure.
- **Model sync notice.** After rewriting agent model lines, the Orchestrator tells the user that restarting the tool makes the new models take effect, since both tools load agent definitions at startup.

### Workflow

- **Kickoff commit on an empty repository.** The initial commit contains only `.gitignore` (with the factory block), so it also satisfies the `.gitignore` commit step. Kickoff asks before committing a `.gitignore` that has user changes outside the factory block.
- **Delegated Discovery drafts write the input file directly.** The Architect, Tech Lead and UX/UI Designer write their drafts into the step's input file; the Orchestrator then applies the user's small corrections itself and re-delegates only when the correction needs the role's expertise. In step 5 the Orchestrator leads the conversation and writes the spec, and delegates prototype generation and inventory to the UX/UI Designer agent, because those produce many files.
- **Reverse Discovery hints persist.** The Architect writes pre-fill hints for steps 1, 5, 6 and 7 to `factory/output/drafts/prefill-hints.md`, so an interrupted session does not lose them. Reverse Discovery counts as complete when the baseline exists and the drafts have a `language` in their front matter.
- **Audit offer timing.** In ongoing projects the audit is offered after step 7 and before step 8, so accepted improvements feed the backlog generation.
- **Test paths live in the item history.** The TEST stage records its commit and test paths in a history line of the item block, which every task message includes. The Tech Lead verifies the tests are unmodified with `git diff <test commit> HEAD -- <paths>`. This keeps the `in_flight` entry in the exact shape the spec defines.
- **Full-suite runs before merging.** With `testing.level: full`, the whole suite runs on the rebased branch before the merge, so the integration branch is never broken by a merge.
- **Accept as-is.** An escalated item accepted as-is keeps the finding in its `Notes`, which feeds "Known issues" in the next checkpoint report; a bug is created only if the user wants it fixed later. Guidance from the user resets the rejection counter.
- **Checkpoint docs branch.** The Tech Writer commits checkpoint docs on `docs/cp-<n>`, reviewed by the Tech Lead and merged like an item, so docs changes also go through review.
- **Checkpoint verification failures** use the bug source `checkpoint-audit`, since they are findings of the checkpoint's quality checks, and are at least P1.
- **Bug-fix checkpoints** are not written to `tasks.md`; they take the next `next_checkpoint_id` and exist in the report, the log and `last_checkpoint`.
- **Bug IDs are reserved when Support starts,** so the reproduction file can use the final name; usage questions leave a gap, which is allowed for bugs.
- **State shapes.** `pending_approvals`, `escalations` and `last_checkpoint` have documented shapes in `state-and-resume.md`; `last_report` is a one-line `<STAGE> <VERDICT>: <summary>` that marks a stage as finished for resumption.
- **QA evidence folder.** Screenshots for visual criteria go to `factory/output/evidence/<ID>/`, added to `output/README.md`.
- **Technique added: re-review only the new commits.** On a rework round, the Tech Lead checks that each previous finding is fixed and then reviews only `git diff <previous reviewed commit>..<branch>`, unless the fixes changed the design. Every changed line is still reviewed.
- **Technique added: stale summary refresh.** `Status` regenerates a summary block from the `Status` lines only when it is older than the last log entry, instead of reading task blocks.
- **DEV role by item type.** `developer` runs DEV for most items, `devops` for `infra` items, and `tech-writer` for `docs` items, so foundation tooling and documentation go to the role that owns them.
- **Technique added: parallel reviewers.** REVIEW runs the Tech Lead, DBA and UX/UI reviews of one round concurrently when the tool allows, which saves time without changing any reviewer's input.

### Roles and agents

- **Agent files are generated.** Each agent body is the §13.1 preamble, with the report block copied from `core/templates/role-report.md`, followed by the role file verbatim. When a role file changes, both agent files are regenerated so the role file stays the source of truth.
- **Severity scales.** Reviews, QA and validation use `blocker`, `major`, `minor`, `info`; security reviews and audits use `critical`, `high`, `medium`, `low`, which map to P0-P3. `blocker`/`major` and `critical`/`high`/`medium` require a fix; QA also uses `UNRELATED_DEFECT`. The scales are defined in `role-report.md` and applied in the role files and guidelines.
- **Project root in task messages.** The task message template adds a `PROJECT ROOT` line under the working directory, because role agents in worktrees must open factory files by absolute path.
- **Paths in role files.** Role files write factory paths relative to the project root and say once, in "Read first", that the task message gives its absolute path. This keeps the embedded role text identical across projects, which keeps it cacheable.
- **Worked examples.** Most role files end with a short example of their report fields or findings, because exact examples make agents follow the formats more reliably than descriptions alone.
- **Support reproductions** are scripts or tests run by explicit path, since product tooling excludes `factory/`.
- **Technique added: quiet checks in review.** The Tech Lead runs only the quiet lint and type-check forms, and QA runs tests at the testing level, so the same full logs are never produced twice.

### Guidelines

- **OWASP categories by name.** The security mapping lists OWASP Top 10 categories by name and adds supply-chain and exceptional-condition rows, so it stays valid across Top 10 editions instead of pinning one edition's numbering.
- **Default budgets and license allowlist.** `performance.md` and `dependencies.md` give default budgets and a default permissive license allowlist that apply only when the constraints document defines none, so reviews always have a concrete threshold.
- **Every guideline ends with a review checklist,** so reviewers can apply a guideline section by section without reading the whole file.

### Templates

- **Status report is a chat layout.** `status-report.md` defines the layout of the `Status` answer; it is shown in the chat in `config.language` and never written to a file.
- **Personal data inventory in the architecture document.** The architecture template carries the personal data inventory, so privacy reviews and access, export and deletion features have one place to check.
- **Threat and finding IDs.** Threat models number trust boundaries (`TB-n`) and threats (`TH-nn`); audits number findings `F-nn` across all roles, so items and reports can reference them stably.
- **Input templates.** Every input document has YAML front matter (`step`, `status`, `approved_at`, `language`) and numbered sections with a one-line guidance comment. The stack profile adds a "Quiet command forms" section and names the slot section "Parallel slot isolation", which delivery and QA reference.

### Installer

- **`--mode install` on an installed project runs an update.** A second install would overwrite the user's config, state and backlog, so the installer says so and updates instead. This keeps repeated installs idempotent.
- **Stale agent files are removed on update.** Every `factory-*` agent file is deleted before the template versions are copied, so a role removed in a later version does not linger. Agent files without the `factory-` prefix are never touched.
- **Missing starting files are restored anywhere outside `core/`,** including `input/` and `output/`, but an existing file is never overwritten. This lets new versions add starting files without touching user data.
- **The manifest keeps "created".** On update, a file the installer originally created stays `created` in the manifest even though it now exists, so its ignore rule is kept.
- **The ignore block follows the manifest.** Update refreshes the block wherever the manifest says it lives (`.gitignore`, or the exclude file after kickoff moved it, relative or absolute path), and prints a commit command when it changes a committed `.gitignore`. The Orchestrator offers the same commit at startup.
- **Top-level detection in PowerShell uses `git rev-parse --show-prefix`,** which is independent of path format and symlinks; `install.sh` compares physical paths (`pwd -P`).
- **CRLF-safe markers.** Both scripts compare marker lines with a trailing carriage return removed, so a file edited on Windows never gets a second block. A block is replaced only when its end marker follows its begin marker; a lone marker stops the installer with a message instead of guessing.
- **Byte-identical output.** Both scripts write LF line endings without a BOM, and an install by one script is left unchanged by an update from the other.
