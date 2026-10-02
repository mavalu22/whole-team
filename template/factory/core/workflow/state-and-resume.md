# State and resume

Read at startup step 5, and whenever you edit `in_flight`, `pending_approvals` or `escalations`. `factory/state.yaml` is written only by the Orchestrator, with small in-place edits.

Sections: 1. In-flight entries · 2. Other delivery entries · 3. Writing state · 4. Resume rules · 5. Usage limits

## 1. In-flight entries

`delivery.in_flight` holds one entry per item in progress:

```yaml
- id: T-012
  stage: QA            # TEST | DEV | REVIEW | QA | SEC | APPROVAL | MERGE
  branch: task/T-012-login-with-email
  worktree: factory/.worktrees/T-012   # null in sequential mode
  slot: 2                              # null in sequential mode
  started_at: 2026-01-01T10:00:00Z
  stage_started_at: 2026-01-01T11:20:00Z
  last_report: null                    # current stage's verdict; cleared on entry
```

- `last_report` is one line: `<STAGE> <VERDICT>: <summary>`, for example `REVIEW APPROVED: no findings`. It describes the current stage's invocation, not an earlier round; clear it on every stage entry. `DONE` or `APPROVED` completes that invocation; `BLOCKED` or `REJECTED` requires the corresponding recovery procedure.
- `stage` is the current position in the item's effective order (`factory/core/workflow/delivery.md` section 4): applicable TEST, DEV, enabled REVIEW, QA and SEC, APPROVAL only with `per_task`, then MERGE. The start history records that full order, for example `pipeline: test, dev, review, qa, sec, merge`; disabled or inapplicable stages are never set here.
- Test paths, merge commits and findings are recorded in the item's history in `factory/tasks.md` or `factory/bugs.md`, not here.

## 2. Other delivery entries

```yaml
pending_approvals:
  - kind: item                 # item | checkpoint
    id: T-012                  # or CP-2
    since: 2026-01-02T09:00:00Z
    pr: null                   # checkpoint pull request URL, when one exists
escalations:
  - id: T-015
    reason: max_rejections     # max_rejections | question | conflict | validation
    since: 2026-01-02T10:00:00Z
    summary: "QA: export times out above 10,000 rows"
last_checkpoint:
  id: CP-2
  merged_at: 2026-01-05T16:00:00Z
  commit: 3f9c2ab
  tag: cp-2                    # null when tags are off
```

`log` entries are single quoted strings: `"<ISO time> <event>"`. Keep them short; the log is append-only.

## 3. Writing state

- **Before a stage:** set the item status in `factory/tasks.md` or `factory/bugs.md`, then `stage`, `stage_started_at` and `last_report: null` in its `in_flight` entry, before delegation. On rework, first record the new round's order in history (delivery section 6); an old DEV or gate verdict cannot complete this new invocation.
- **After a stage:** set `last_report`, append the item history line, then move to the next applicable stage. Keep the previous round's evidence in history, but use only the current round's verdicts to advance.
- **Phase transitions and decisions:** a log line each.
- Never keep information only in the conversation: every decision the user makes goes into a file (an input document, the item's `Notes`, the config, or the log) before you act on it.

## 4. Resume rules

On `Let's code` (startup step 5):

1. For each `in_flight` entry, verify:
   - the branch exists (`git rev-parse --verify <branch>`);
   - in parallel mode, the worktree exists (`git worktree list`);
   - there are no stray uncommitted changes in its working directory (`git -C <dir> status --porcelain`).
   Reconcile the entry with the latest history round first: a `rework` marker after the entry's recorded verdict invalidates that verdict and requires DEV with `last_report: null`, even if the old report also says DEV. Pending test disputes are resumed before implementation.
2. **Stage started, report not recorded** (`last_report` is `null`, or a legacy entry contains an earlier stage's report): resume the current invocation. For unfinished TEST before DEV, preserve any committed tests and finish the initial test-writing work; do not start DEV until the TEST commit and paths are recorded. Uncommitted changes left by an interrupted DEV stage belong to the item: tell the Developer about them in the task message so it can keep or discard them. Re-running MERGE is safe because it starts with the resume check (`factory/core/workflow/delivery.md` section 5, step 1).
3. **Completed current invocation:** when its `DONE` or `APPROVED` verdict is recorded, finish any missing history record, then continue to the next applicable stage without re-delegating the completed invocation. `BLOCKED` and `REJECTED` reports instead resume clarification, dispute, rejection or escalation handling. Recorded verdicts from an earlier rework round do not count: changed code requires the applicable downstream gates again (delivery section 6). Completed TEST is retained across every rework round; executing its tests again is not a new TEST stage.
   - **Pending test dispute:** if history has `TEST dispute pending` without a matching resolution, resume only that dispute against the criteria and contracts, then DEV. Keep `stage: DEV`; do not launch fresh test writing.
   - **Legacy ordering:** normalize a recorded DEV-first pipeline to the canonical effective order before advancing. If DEV has already started, do not insert a fresh TEST invocation. Recover an existing pre-DEV TEST commit and its paths from history/git when available. An entry that requests unfinished TEST after implementation without such a commit is inconsistent: preserve the work, set `BLOCKED` and ask for a recovery decision rather than writing tests from the implementation.
4. **Missing branch or worktree:** if the branch exists but the worktree is gone, recreate the worktree from the branch (`git worktree add <path> <branch>`) and reinstall dependencies. If the branch is gone, first run the already-merged check (`factory/core/workflow/delivery.md` section 5, step 1.2): if it finds the commit, finish the record step (step 6 there) with that hash instead. Otherwise reset the item to `TODO`, remove the entry, and add a history line.
5. **Pending approvals and escalations** are re-presented before any new work. A checkpoint approval that the log already records, or whose checkpoint is already merged, is not asked again: finish it (`factory/core/workflow/checkpoints.md` section 4, "Resuming").
6. **A checkpoint in progress** resumes at its first step without a log line: section 1 of `factory/core/workflow/checkpoints.md` for the procedure, and its section 4 ("Resuming") after approval.
7. After an interruption, tell the user briefly where things stand and what resumes now.

## 5. Usage limits

Sessions end without warning when a usage limit is reached. The files are always the source of truth:

- Update state before and after every stage transition (section 3), never in batches.
- Role agents commit work in progress on item branches, so an interrupted DEV stage loses at most the last few edits.
- A new session needs only `Let's code`: the startup routine and these resume rules pick up exactly where the files say work stopped.
