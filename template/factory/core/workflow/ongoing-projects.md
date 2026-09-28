# Ongoing projects

Read when kickoff finishes in a project with `project.type: ongoing`, and on resume while its reverse Discovery is in progress. Discovery rules and steps are in `factory/core/workflow/discovery.md`; this file says what changes for an existing codebase.

Sections: 1. Reverse Discovery · 2. Baseline · 3. Discovery steps · 4. Audit offer · 5. Backlog · 6. Resume

## 1. Reverse Discovery

1. **Ask for the interfaces first.** The user states them; they are never inferred from the code, because a wrong guess would spread through Discovery and the backlog. Show the "Interfaces" descriptions from `factory/core/modes.md` (section 2), translated to `config.language`, and ask which interfaces the product has, with the details step 3 of `factory/core/workflow/discovery.md` lists for each. Write `project.interfaces` and append `"<ISO time> interfaces set: [<ids>]"` to the log before continuing. Skip this step when the log already has an `interfaces set` line.
2. Delegate to `architect` with `STAGE: DISCOVERY` and the goal "reverse Discovery and baseline". The task message carries the user's interfaces with their details, and asks it to:
   1. analyse the repository: manifests and lockfiles, configs, folder structure, tests, CI files, Docker files, scripts, and the README;
   2. read the project's existing instruction files when present: `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`, `.github/copilot-instructions.md`, `CONTRIBUTING.md` (outside any WholeTeam block);
   3. draft `factory/input/02-stack.md`, `factory/input/03-platform-architecture.md` and `factory/input/04-stack-profile.md`, plus `factory/output/architecture.md` and ADRs for significant existing decisions. The analysis documents the user's interfaces, and `03-platform-architecture.md` section 1 records them as stated by the user, never marked `(inferred)`;
   4. mark every inferred item with `(inferred)`;
   5. extract the conventions from the existing code (naming, structure, error handling, test style) and from the instruction files into the stack profile. Role agents may not load those instruction files, so the stack profile is where they learn them;
   6. run the baseline (section 2);
   7. write pre-fill hints for steps 1, 5, 6 and 7 to `factory/output/drafts/prefill-hints.md`: short bullets per step, each with the file path it comes from (for example "design tokens: `src/styles/tokens.css`"). For step 5, the hints point to what exists for the stated interfaces: design tokens for `gui`, and the existing contract, CLI help text, public API or plugin manifest for the others;
   8. never add an interface the user did not list. Code that looks like one (for example HTTP routes, a `bin` entry or a plugin manifest) is reported with its evidence in `SUMMARY`.
3. Append a log line: `"<ISO time> reverse analysis done; unlisted interfaces: <ids with evidence paths, or none>"`. Read `factory/output/drafts/prefill-hints.md` section by section, when each step starts.
4. Tell the user in at most 6 lines what the factory learned: stack, architecture style, test and CI state, baseline result.
5. **Unlisted interfaces are questions, not corrections.** For each interface the Architect reported, show the evidence and ask the user whether it is in scope. Only the user's answer changes `project.interfaces`: if they add it, write the key, log it (`interfaces set`), ask for its details, and delegate to the `architect` to document it in the drafts. Otherwise leave the key as it is and log the answer.

## 2. Baseline

The Architect runs the existing checks before the factory changes anything, and writes `factory/output/baseline.md` from `factory/core/templates/baseline.md`:

1. Install dependencies with the project's own command.
2. Run the tests, the linter, the type-checker and the build with the commands the project defines (scripts, Makefile, CI config). If a command does not exist, record "not configured".
3. Record for each: the command, the date, pass or fail, counts, and the failing items (test names, error codes), without whole logs.
4. Failures in the baseline are known failures: they are not blamed on new work. Items that touch those areas note them in their `Notes`, and the Test Engineer and QA compare against the baseline.

If the baseline cannot run (missing services, secrets, unsupported OS), record why and ask the user whether to continue without it.

## 3. Discovery steps

Run the steps of `factory/core/workflow/discovery.md` in the usual order, with these changes. Quick mode (`discovery.quick_steps`, `factory/core/workflow/discovery.md` section 1, "Quick mode") applies here too, for steps 3 to 7: skip "Ask" and draft from the pre-fill hints and defaults instead of the question bank, then show the usual short summary for approval. It never changes section 1 above: the user always states the interfaces themselves.

- **Step 1 (Vision) and steps 5, 6, 7:** still conversations. Pre-fill answers the code makes evident (from the Architect's hints: product purpose from the README, design tokens from CSS, auth and session rules from config, test tools and CI from the repository), present them as recommended answers, and ask only what the code cannot answer. Step 1 also asks what the user wants to add or change in the product: this defines the backlog's scope.
- **Steps 2, 3 and 4:** confirm the drafts instead of drafting from scratch. Walk the user through each `(inferred)` item in batches of at most 4. When the user confirms an item, remove its `(inferred)` marker; when they correct it, edit the item. Planned changes (for example "move to PostgreSQL") are recorded as decisions with an ADR.
- **Step 3:** the DBA still reviews the data model as found in the code (schema files, migrations, models).
- **Step 5:** in `user_prototypes` mode, existing screenshots or design files go into `factory/input/prototypes/`; in `spec` mode, the spec describes the existing design system first. For the other interfaces, the spec describes what exists first (contract, CLI help text, public API, plugin manifest), from the hints.

## 4. Audit offer

After step 7 is approved and before step 8:

1. Offer a bug and security audit of the existing code (`factory/core/workflow/audit.md`), in 2-3 lines: what it checks and that it runs on a high tier.
2. If the user accepts, show the two output modes (`report_first`, `tasks_directly`) from `factory/core/modes.md` (section 10) with their descriptions and ask which one. Run the audit.
3. Accepted findings become bugs in `factory/bugs.md` (scheduled when delivery starts) and proposed tasks for step 8.
4. If the user declines, log it and remind them that `Audit` is available at any time.

## 5. Backlog

Step 8 runs as in `factory/core/workflow/discovery.md`, with these inputs for the Architect:

- the changes the user wants (step 1 scope);
- accepted audit items (improvements as tasks; defects are already bugs);
- the baseline, so the backlog adds tasks to fix broken tooling when the user wants it.

Foundation tasks cover only what is missing: for example, a CI pipeline if none exists, `.env.example` if missing, slot isolation, and the tooling exclusions for `factory/`. Never re-scaffold an existing project.

## 6. Resume

Reverse Discovery is complete when `factory/output/baseline.md` exists and the front matter of `02-stack.md`, `03-platform-architecture.md` and `04-stack-profile.md` has a non-null `language`. On resume:

- If it is not complete, re-run section 1 (the Architect overwrites its own drafts; the interfaces question is skipped when the log already has the answer).
- If it is complete and the `reverse analysis done` line lists unlisted interfaces the log has no answer for, ask about them first (section 1, step 5).
- If it is complete and `discovery.current_step` is `null`, start step 1.
- Otherwise resume `discovery.current_step` as usual.
