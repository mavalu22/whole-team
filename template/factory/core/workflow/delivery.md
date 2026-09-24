# Delivery

Read when `phase: delivery` or `maintenance`, and for `Let's code <ID>`. Each section stands alone: search this file by its exact path for the heading you need and read only that section.

Sections: 1. Scheduling loop · 2. Choosing the next item · 3. Starting an item · 4. Item pipeline · 5. Merge · 6. Rejections · 7. Escalations · 8. Clarifications · 9. Sequential mode · 10. Parallel mode

## 1. Scheduling loop

Repeat until you must stop for the user:

1. Re-present `delivery.pending_approvals` and `delivery.escalations`, if any, and wait for the answers they need. In parallel mode, keep other items running meanwhile.
2. If a checkpoint's conditions are met, run `factory/core/workflow/checkpoints.md`.
3. Pick the next item (section 2) and start it (section 3), up to one item in sequential mode or `execution.max_parallel_tasks` in parallel mode.
4. Advance each in-flight item through its pipeline (section 4).
5. When no item is ready and nothing is in flight:
   - if every task is `DONE` or `CANCELLED` and no bug is open, set `phase: maintenance` (if not already) and report that the product is complete;
   - if open bugs remain after all tasks, run them (section 2) and close them with a bug-fix checkpoint (`factory/core/workflow/checkpoints.md` section 5);
   - otherwise report what blocks progress (escalations, blocked items) and ask the user.

Between items, give the user a one-to-three line progress message (FACTORY.md section 9). Stop only for approvals, escalations, questions that need the user, and checkpoints.

## 2. Choosing the next item

1. **Blocking bugs first.** Read the summary block of `factory/bugs.md`. A bug is blocking when its priority is `bugs.block_features_on` or more severe (`factory/core/workflow/bugs-and-support.md` section 3). Take blocking bugs in priority order (P0 first), then by ID.
2. **Requested item.** After `Let's code <ID>`, take that item next if it is ready; otherwise tell the user what it waits for and continue with the usual order.
3. **Ready tasks.** Search `factory/tasks.md` by its exact path for the `### T-` headings and the `**Status:**`, `**Depends on:**` and `**Touches:**` lines, plus the `#CHECKPOINT` lines, instead of reading every block. A task is ready when:
   - its status is `TODO`;
   - every dependency is `DONE` (merged into the integration branch);
   - no pending checkpoint line lies before it in `factory/tasks.md` (checkpoints are barriers);
   - in parallel mode, its `Touches` do not overlap any in-flight item's `Touches`.
4. **Order.** Sequential mode: the first ready task in file order. Parallel mode: prefer tasks that unblock the most other tasks (critical path), then file order.
5. **Non-blocking bugs** run after all tasks are done, or earlier when the user asks (`Let's code B-004`).

## 3. Starting an item

1. Check the Definition of Ready (`factory/core/workflow/quality-gates.md` section 1). If it fails, fix the item with the relevant role (Product Owner for criteria, Architect for dependencies) or ask the user.
2. Build the branch name from `git.task_branch_pattern` or `git.bug_branch_pattern`: `{id}` is the item ID, `{slug}` is a short English kebab-case summary of the title (at most 5 words), even when the title is in another language.
3. Create the branch from the integration branch (section 9 or 10 for the command).
4. Update, in this order: the item's `**Branch:**` line and a history line `<date> · started`; a new `delivery.in_flight` entry (`factory/core/workflow/state-and-resume.md` section 1); the summary block.

## 4. Item pipeline

Every task and bug runs these stages in order. Before each stage, set the item's status and `in_flight[].stage`, `stage_started_at`; after each stage, record the verdict (`last_report`) and a history line. Delegate each stage with a task message (`factory/core/workflow/delegation.md`). Skip a stage only where this section says so.

### 4.1 TEST

- **Status:** `TESTING`. **Role:** `test-engineer`.
- **Runs when:** `testing.level` is `full`; or `critical` and the item has `Critical: yes`; or the item is a bug and `testing.level` is not `none` (regression test).
- **Skipped:** otherwise, and always for items of type `docs`.
- **Task message excerpts:** acceptance criteria, published contracts (API spec, shared types, UI spec paths), and for bugs the reproduction steps and evidence file.
- **Result:** tests committed on the item branch with `test(<scope>): ...`, expected to fail until DEV finishes. Record a history line with the commit and the test paths: `<date> · TEST done · <commit> · tests: <path>, <path>`. Later stages read these paths from the item block.

### 4.2 DEV

- **Status:** `IN_PROGRESS`. **Role:** `developer`.
- **Task message excerpts:** acceptance criteria, relevant contracts and design references, the Test Engineer's test paths, and on rework the findings to fix (only the open ones).
- **Result:** commits on the item branch; lint, type-check and the relevant tests pass. A `BLOCKED` verdict with "test looks wrong" goes to the Test Engineer for adjudication against the acceptance criteria (`test-engineer` with stage `TEST`); the Test Engineer either fixes the test (history line) or confirms it, and DEV resumes.
- **Bugs with `Verified: no`:** the Developer first confirms the bug. If it cannot be reproduced, it returns `BLOCKED`; ask the user whether to close it as `NOT_A_BUG` or give more details.

### 4.3 REVIEW

- **Status:** `IN_REVIEW`. **Roles:**
  - `tech-lead`, always;
  - `dba`, when `Touches` includes `db`, `data` or `migrations`;
  - `ux-ui-designer`, when `design.review_ui_items` is true and `Touches` includes a `ui/*` area.
- Run the reviewers of one round in parallel when the tool allows it; they are independent.
- All reviewers must approve. One review round with any rejection counts as **one** rejection; merge the findings of all reviewers into one list for DEV.

### 4.4 QA

- **Status:** `QA`. **Role:** `qa`.
- **Task message excerpts:** acceptance criteria, the testing level, the run commands (from the stack profile), the slot and its environment in parallel mode, design references for UI items, and the baseline's known failures in `ongoing` projects.
- **Result:** each acceptance criterion verified with evidence. Check the item's boxes (`[x]`) only for criteria the report proves. `UNRELATED_DEFECT` findings go to Support (`factory/core/workflow/bugs-and-support.md`, source `qa-unrelated`) and are not a rejection.

### 4.5 SEC

- **Status:** `SEC`. **Role:** `security`.
- **Depth:** the item's `Security review` value. A `required` review runs at `security.required_review_tier` (tier override, `factory/core/workflow/delegation.md` section 1).
- **Documentation-only diffs:** when the diff changes only documentation, the review checks only for secrets and sensitive data.

### 4.6 APPROVAL

- **Status:** `AWAITING_APPROVAL`. Only when `execution.approval_mode` is `per_task`.
- Add an entry to `delivery.pending_approvals` and present a short summary: what changed, how to try it (commands, URL), test results.
- **approve:** continue to MERGE. **Feedback:** send the item back to DEV with the feedback as findings; this does not count as a rejection.
- In parallel mode, other items continue while this one waits.

### 4.7 MERGE

See section 5.

## 5. Merge

The Orchestrator merges; never delegate it. Merge one item at a time.

1. **Check the Definition of Done** (`factory/core/workflow/quality-gates.md` section 2).
2. **Update the branch** onto the latest integration branch: `git -C <dir> rebase <integration>`, where `<dir>` is the worktree (parallel) or the project root (sequential).
   - If conflicts appear: `git -C <dir> rebase --abort`, then send the item back to DEV with a conflict note ("rebase onto `<integration>` and resolve conflicts in: <files>"). This is not a rejection. The item then runs REVIEW, QA and SEC again.
3. **Re-run tests** after a rebase that changed anything: the quiet test command from the stack profile, for the tests related to the item; with `testing.level: full`, the whole suite. A failure sends the item back to DEV with the failing lines as findings (not a rejection).
4. **Merge** from the integration branch checkout (the project root):
   - `squash`: `git switch <integration> && git merge --squash <branch> && git commit -m "<subject>" -m "<body>"`.
   - `merge`: `git switch <integration> && git merge --no-ff <branch> -m "<subject>"`.
   - **Subject:** a Conventional Commit whose description ends with the item ID, for example `feat(auth): login with email and password (T-012)`. Type: `feat` for features, `fix` for bugs, `test`, `docs` and `refactor` for those types, `build`, `ci` or `chore` for infra, `feat` or `fix` for security tasks. Scope: the main `Touches` area. English.
   - **Body:** one line per acceptance criterion delivered, and the item's gate verdicts.
   - Add a `Co-authored-by:` trailer naming the AI agent only when `git.ai_coauthor` is true. The same rule applies to every commit and PR body the factory writes.
5. **Record:** set status `DONE`, append `<date> · merged · <short hash>` to the history, update the summary block and the graph `class` line, and remove the `in_flight` entry.
6. **Clean up:** in parallel mode `git worktree remove <worktrees_dir>/<ID>`. If `git.delete_merged_branches` is true, delete the branch with `git branch -D <branch>` (a squash merge is not detected by `-d`; the recorded merge commit is the proof).
7. **Open checkpoint PR:** if a checkpoint pull request is open, push the integration branch so the PR updates.
8. **Next:** in parallel mode, in-flight branches rebase onto the new integration branch at their next stage boundary (section 10). Then check checkpoint conditions (section 1, step 2).

## 6. Rejections

- A rejection at REVIEW, QA or SEC sets `REVIEW_REJECTED`, `QA_REJECTED` or `SEC_REJECTED`, increments `**Rejections:**`, appends a history line naming the gate and the main finding, and sends the findings back to DEV. After DEV, the item runs REVIEW again and then continues through the remaining stages.
- User feedback at APPROVAL, rebase conflicts and post-rebase test failures send the item back to DEV without counting as rejections.
- When `Rejections` reaches `execution.max_rejections`, set `BLOCKED` and create an escalation (section 7).

## 7. Escalations

1. Add an entry to `delivery.escalations` (`factory/core/workflow/state-and-resume.md` section 2) and set the item `BLOCKED`.
2. **Sequential mode:** stop and ask the user. **Parallel mode:** keep other items running and ask in the main chat.
3. Show the item, the gate, the recurring finding in one or two lines, and the options:
   1. **Give guidance:** send the item back to DEV with the user's guidance; reset `Rejections` to 0 and add a history line.
   2. **Simplify or split:** cancel the item and create smaller tasks following `factory/core/workflow/backlog.md` section 6, with the Architect; or reduce the acceptance criteria with the user and continue.
   3. **Accept as-is:** continue to the next stage or merge; record the accepted finding in `**Notes:**` so it appears under "Known issues" in the next checkpoint report. If the user wants it fixed later, create a bug for it (source `support`) with a priority they confirm.
   4. **Cancel:** set `CANCELLED`, remove the worktree, keep the branch unless the user wants it deleted, and handle dependents (`factory/core/workflow/backlog.md` section 6).
4. Remove the escalation entry once the user decides, and log the decision.

## 8. Clarifications

When a role returns `BLOCKED` with a question:

1. Answer it from the inputs (read the referenced sections only), consulting the Product Owner role (`product-owner` agent, stage `DISCOVERY`) if the answer needs product judgment.
2. Ask the user only when a real decision is needed; add an entry to `delivery.escalations` with `reason: question` while waiting.
3. Re-run the same stage with the answer added to the task message. Record the answer in the item's `**Notes:**` if it affects later stages.
4. In parallel mode, other items continue meanwhile.

## 9. Sequential mode

- One item at a time, in the main working copy.
- Start: `git switch -c <branch> <integration>`.
- Run the stages one after another, each delegated to its role agent. Use the fallback in `factory/core/workflow/delegation.md` if delegation is unavailable.
- After the merge, the working copy is on the integration branch, ready for the next item.

## 10. Parallel mode

- **Ready set and choice:** section 2. Fill up to `execution.max_parallel_tasks` in-flight items. Blocking bugs are taken first and follow the same `Touches` rules.
- **Worktrees:** keep the main working copy on the integration branch. For each item:
  1. `git worktree add <worktrees_dir>/<ID> -b <branch> <integration>`;
  2. assign the lowest free slot number (1...N) and record it in `in_flight`;
  3. copy the main working copy's untracked `.env` (if it exists) into the worktree, then apply the slot settings defined in `factory/input/04-stack-profile.md` section "Parallel slot isolation";
  4. install dependencies inside the worktree with the stack profile's install command: worktrees share git history, not installed packages.
- **Runtime isolation:** use the stack profile's mechanism, for example `FACTORY_SLOT=<n>`, a port offset (base + 10 × slot) and a per-slot database name or file. Put the slot environment in every task message.
- **Delegation:** run role agents in the background, with absolute paths to the worktree and to factory files in the task message (worktrees don't contain `factory/`). In Claude Code, a subagent's `cd` does not persist between commands, so every command must be `cd <worktree> && ...` or use `git -C <worktree>`. Don't use Claude Code's own `isolation: worktree`: it branches from the default branch, not from the integration branch.
- **Merge queue:** merge one item at a time (section 5). After each merge, rebase every other in-flight branch at its next stage boundary: `git -C <worktree> rebase <integration>`; on conflicts, abort and send that item to DEV with a conflict note.
- **Approvals:** with `per_task`, finished items wait in `delivery.pending_approvals` while other items continue.
- **Checkpoints:** a checkpoint waits for every in-flight item before it to merge; items after it do not start until it completes.
- **Warning:** when parallel work starts, tell the user once not to edit files in the main working copy while it runs.
