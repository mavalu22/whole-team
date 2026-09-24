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
  last_report: null                    # short verdict of the last finished stage
```

- `last_report` is one line: `<STAGE> <VERDICT>: <summary>`, for example `REVIEW APPROVED: no findings`. It is the record that a stage finished.
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

- **Before a stage:** set the item status in `factory/tasks.md` or `factory/bugs.md`, then `stage` and `stage_started_at` in its `in_flight` entry.
- **After a stage:** set `last_report`, append the item history line, then move to the next stage.
- **Phase transitions and decisions:** a log line each.
- Never keep information only in the conversation: every decision the user makes goes into a file (an input document, the item's `Notes`, the config, or the log) before you act on it.

## 4. Resume rules

On `Let's code` (startup step 5):

1. For each `in_flight` entry, verify:
   - the branch exists (`git rev-parse --verify <branch>`);
   - in parallel mode, the worktree exists (`git worktree list`);
   - there are no stray uncommitted changes in its working directory (`git -C <dir> status --porcelain`).
2. **Stage started, report not recorded** (`last_report` is from an earlier stage or `null`): re-run that stage from the beginning. Developers commit work in progress often, so little is lost. Uncommitted changes left by an interrupted DEV stage belong to the item: tell the Developer about them in the task message so it can keep or discard them.
3. **Never re-run a finished stage** whose verdict is recorded; continue with the next one.
4. **Missing branch or worktree:** if the branch exists but the worktree is gone, recreate the worktree from the branch (`git worktree add <path> <branch>`) and reinstall dependencies. If the branch is gone, reset the item to `TODO`, remove the entry, and add a history line.
5. **Pending approvals and escalations** are re-presented before any new work.
6. **A checkpoint in progress** resumes at its first step without a log line (`factory/core/workflow/checkpoints.md` section 1).
7. After an interruption, tell the user briefly where things stand and what resumes now.

## 5. Usage limits

Sessions end without warning when a usage limit is reached. The files are always the source of truth:

- Update state before and after every stage transition (section 3), never in batches.
- Role agents commit work in progress on item branches, so an interrupted DEV stage loses at most the last few edits.
- A new session needs only `Let's code`: the startup routine and these resume rules pick up exactly where the files say work stopped.
