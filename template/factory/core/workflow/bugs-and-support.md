# Bugs and Support

Read for `Support:`, for bug findings from QA, audits and checkpoints, and when scheduling bugs. Each section stands alone.

Sections: 1. Format of bugs.md · 2. Support flow · 3. Scheduling · 4. Bugs from other sources

## 1. Format of bugs.md

`factory/bugs.md` starts with a summary block, then one block per bug in ID order.

```markdown
# Bugs

<!-- factory:summary:start -->
- **Updated:** 2026-02-03
- **Open by priority:** P0 0 · P1 1 · P2 2 · P3 0
- **Blocking:** B-003
- **In flight:** B-003 (DEV)
<!-- factory:summary:end -->
```

"Open" means any status other than `DONE`, `CANCELLED`, `NOT_A_BUG` and `DUPLICATE`. "Blocking" lists open bugs at or above `bugs.block_features_on`.

Bug block. Field labels are exact and always English; free text is in `state.input_language`.

```markdown
### B-003 · Login button does nothing on Safari
- **Status:** OPEN
- **Priority:** P1
- **Verified:** yes
- **Source:** support
- **Found in:** CP-2 · T-012
- **Touches:** ui/login
- **Security review:** light
- **Reproduction:**
  1. ...
- **Expected:** ...
- **Actual:** ...
- **Evidence:** factory/output/support/B-003-repro.spec.ts
- **Branch:** —
- **Rejections:** 0
- **History:**
  - 2026-01-01 · reported via Support
```

- **Heading:** `### B-NNN · <title>`, three-digit number. IDs come from `delivery.next_bug_id`, are never reused, and may have gaps.
- **Statuses:** the task statuses (`factory/core/workflow/backlog.md` section 1.4), plus `OPEN` (the entry state), `NOT_A_BUG` and `DUPLICATE`.
- **Priority:** `P0`, `P1`, `P2` or `P3`:
  - **P0:** crash, data loss, security hole, or the product is unusable.
  - **P1:** a major feature is broken and there is no workaround.
  - **P2:** broken but a workaround exists, or a minor feature is affected.
  - **P3:** cosmetic or trivial.
- **Verified:** `yes` (reproduced) or `no` (could not be tested; the Developer confirms it before fixing).
- **Sources:** `support`, `audit`, `checkpoint-audit`, `qa-unrelated`.
- **Found in:** the checkpoint and item where it appeared, when known (`CP-2 · T-012`), otherwise `—`.
- **Evidence:** path to the reproduction file, audit report or QA report excerpt location, or `—`.

## 2. Support flow

1. When the user sends `Support: <description>`, reserve the next bug ID (`delivery.next_bug_id`, then increment it) and delegate to `support` with stage `SUPPORT`. The task message contains the user's description verbatim (translated to English if needed, keeping the original too), the reserved ID, how to run the product (stack profile path), and the paths of the related input sections if obvious.
2. If Support returns `BLOCKED` with questions, relay them to the user (translated to `config.language`), then re-run Support with the answers.
3. Act on the classification in the report:
   - **Confirmed:** create the bug from the draft entry with the proposed priority (`Verified: yes`), and confirm the priority with the user in one line ("Recorded B-007 as P1: <title>. Reply with another priority to change it.").
   - **Cannot test:** create it with `Verified: no`. The Developer must confirm the bug before fixing it.
   - **Not a bug:** record it with status `NOT_A_BUG` and a history line with the reason. Explain the expected behavior to the user and suggest `Change: <request>` if they want it to work differently.
   - **Usage question:** answer it in `config.language`. No entry is created; the reserved ID stays unused.
   - **Duplicate:** record it with status `DUPLICATE` and a history line `duplicate of B-<id>`; append `<date> · duplicate report B-<new>` to the existing bug, and add any new detail to it.
4. Security bugs (vulnerabilities, data exposure, auth bypass) get `Security review: required`; others get `security.review_default`.
5. Update the summary block. Tell the user when the bug will be handled: now (blocking), or after the current tasks.
6. In `kickoff` or `discovery` phase (ongoing projects), record the bug; it is scheduled when delivery starts.

## 3. Scheduling

- A bug is **blocking** when its priority is `bugs.block_features_on` or more severe (P0 is the most severe). With the default `P1`, P0 and P1 bugs block.
- Blocking bugs run before any new task starts, P0 first, then by ID. A checkpoint cannot complete while one is open. In-flight tasks finish their current stage and continue; they are not interrupted.
- Non-blocking bugs run after all tasks are done, or earlier when the user asks (`Let's code B-004`).
- Bugs use the same pipeline as tasks (`factory/core/workflow/delivery.md` section 4), with a regression test in TEST (unless `testing.level` is `none`), on a branch from `git.bug_branch_pattern`. The bug's `Expected` field and reproduction steps are its acceptance criteria.
- In parallel mode, bugs follow the same ready-set and `Touches` rules as tasks.
- After the final checkpoint and in `maintenance`, fixed bugs are grouped into bug-fix checkpoints (`factory/core/workflow/checkpoints.md` section 5).

## 4. Bugs from other sources

- **QA (`qa-unrelated`):** an `UNRELATED_DEFECT` finding in already-merged code. Delegate it to `support` like a user report (the finding is the description), so it is reproduced and classified. The item under QA is not rejected for it.
- **Audits (`audit`) and checkpoint audits (`checkpoint-audit`):** each accepted finding with a defect becomes a bug directly, with `Verified: yes` when the finding cites reproducible evidence and `no` otherwise. Priority from the audit mapping (`factory/core/workflow/audit.md` section 4). `Evidence` points to the audit report and finding number.
- **Checkpoint verification failures** (failing suite, lint, type-check, build or coverage) are recorded with source `checkpoint-audit`, at least P1.
