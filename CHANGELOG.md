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
