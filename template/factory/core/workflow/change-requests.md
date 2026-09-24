# Change requests

Read for `Change: <request>`. A change request modifies something already approved: a Discovery document, the backlog, or delivered behavior. Everything goes back through the same approvals and gates.

Sections: 1. Triage · 2. Reopen and update the inputs · 3. Impact on the backlog · 4. Validate and approve · 5. During Discovery

## 1. Triage

1. Restate the request in one or two lines and confirm it with the user if it is ambiguous.
2. Identify the affected Discovery steps: which input files and sections the change touches (for example "US-04 in `01-product-vision.md`; `03-platform-architecture.md` §5"). Search the input files by exact path for the stable IDs and section numbers involved.
3. If the request is really a defect ("it should already do X"), offer to handle it as `Support:` instead.
4. Pause the start of new items. In-flight items finish their current stage; unaffected items continue after the change is approved.
5. Log the change request start in `factory/state.yaml`.

## 2. Reopen and update the inputs

1. Set each affected step's `status: reopened` in `factory/state.yaml` and `status: draft` in the file's front matter.
2. Discuss the change with the user, one decision at a time, using the step's owners and delegation from `factory/core/workflow/discovery.md` (for example the Architect for a stack change, with a new or superseding ADR).
3. Update the input files with small edits. Keep section numbers stable: add new sections at the end of the relevant list, never renumber.
4. Re-run the affected step's checklist, then ask for re-approval with a summary of what changed. On approval, set the step back to `approved` with the new `approved_at`.

## 3. Impact on the backlog

Delegate the impact analysis to `architect` (stage `DISCOVERY`), with the change summary, the paths of the updated inputs, and `factory/tasks.md`. The Architect returns a proposal in `factory/output/drafts/backlog-draft.md` that lists only the changes:

- **Unstarted tasks** (`TODO`): update, split or cancel them. Cancelled tasks become `CANCELLED`, are never deleted, and keep their IDs; IDs are never reused.
- **In-flight tasks:** if the change affects them, finish the current stage, then either continue with updated criteria (the item returns to DEV) or cancel them, as the user decides.
- **Done tasks:** never edited; create new tasks that modify their result.
- **New tasks:** take the next free IDs and are appended after the existing tasks, followed by a new checkpoint, unless the user asks to insert them before the next pending checkpoint (`factory/core/workflow/backlog.md` section 3, rule 13).

## 4. Validate and approve

1. Delegate to `backlog-validator` to check the proposal applied to the backlog (at most 2 fix rounds with the Architect).
2. Present the diff of the backlog to the user: tasks added, changed, cancelled; new or moved checkpoints; the effect on the next checkpoint. Keep it to at most 15 lines, and give the draft path for details.
3. On approval, apply it (`factory/core/workflow/backlog.md` section 5), regenerate the graph, log it, and resume delivery.
4. If the user rejects it, restore the previous input approvals only if the inputs were not changed; otherwise continue the discussion.

## 5. During Discovery

- A change to the current step is part of the conversation: no `Change:` procedure is needed.
- A change to an approved step during Discovery follows sections 1 and 2. Later steps that depend on it (for example the stack profile after a stack change) are reopened too if their content is affected; tell the user which ones.
- Before step 8 is approved, there is no backlog impact to analyse.
