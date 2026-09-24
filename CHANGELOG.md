# Changelog

All notable changes to WholeTeam are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/).

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
