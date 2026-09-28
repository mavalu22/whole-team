# Status

Read for the `Status` command. Status reads only `factory/state.yaml`, the `pipeline` block of `factory/config.yaml`, the summary blocks of `factory/tasks.md` and `factory/bugs.md`, and a listing of `factory/attachments/`; it never reads task or bug blocks.

## Procedure

1. Read `factory/state.yaml` and the `pipeline` block of `factory/config.yaml`.
2. Read the summary block of `factory/tasks.md` (the lines between `<!-- factory:summary:start -->` and `<!-- factory:summary:end -->`) and of `factory/bugs.md`.
3. Read the next `#CHECKPOINT` line: search `factory/tasks.md` by its exact path for `#CHECKPOINT` lines and take the first one after `delivery.last_checkpoint`.
4. List `factory/attachments/` by its exact path and count the files directly in its root (not in a subfolder, and not `README.md`): these are not linked to any item yet.
5. Compose the status in `config.language`, following the layout of `factory/core/templates/status-report.md`, compactly (at most 15 lines):
   - phase;
   - the process, one line (for example `Process: standard (review, qa)` or, for `custom`, `Process: custom (review, qa, ux_check: qa)`);
   - in Discovery: the current step and the approved steps (for example `Discovery · step 3 of 8 (Architecture) · approved: 1, 2`);
   - in delivery: counts per status, the current wave and the waves left;
   - in-flight items with their stage and slot;
   - pending approvals and escalations;
   - open bugs by priority, with the blocking ones flagged;
   - `<n> attachments not linked yet`, when step 4 found any;
   - the next checkpoint and what it delivers;
   - the last checkpoint;
   - the path `factory/tasks-graph.md` for the full picture.
6. Offer the single most useful next action, for example "Reply **approve** to merge CP-2", "Answer the question about T-015", or "Type `Let's code` to continue with T-013".

## Rules

- If a summary block looks stale (its `Updated` date is older than the last log line), regenerate it first with a selective search of the `**Status:**` lines, then show the status.
- Status never changes state other than refreshing summary blocks.
- Don't list every task; the graph file has the full picture.
