# Changelog

All notable changes to WholeTeam are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-09-24

### Added

- Project layout: `VERSION`, `.gitattributes`, and the `template/` tree that the installer copies into a target project.
- Root guide blocks for `CLAUDE.md` and `AGENTS.md`, delimited by `whole-team` markers.
- `factory/config.yaml` with commented settings, and the identical `factory/core/config.defaults.yaml` used by migrations.
- `factory/state.yaml`, the Orchestrator's runtime state.
- `factory/core/MIGRATIONS.md`, the procedure the Orchestrator follows to migrate config and state after an update.
- Starting files `tasks.md`, `tasks-graph.md` and `bugs.md`, and `output/README.md`.

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
- **Technique added: stale summary refresh.** `Status` regenerates a summary block from the `Status` lines only when it is older than the last log entry, instead of reading task blocks.
- **Technique added: parallel reviewers.** REVIEW runs the Tech Lead, DBA and UX/UI reviews of one round concurrently when the tool allows, which saves time without changing any reviewer's input.
