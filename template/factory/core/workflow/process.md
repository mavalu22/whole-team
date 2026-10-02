# Process

Read for the `Process` command, and whenever a request changes how much delivery process runs (for example "switch to the standard preset", or its direct translation), per the command-recognition rule (`factory/core/FACTORY.md` section 4).

Sections: 1. Showing the settings · 2. Choosing a new process · 3. Applying the change · 4. In-flight items · 5. Task size · 6. Discovery quick steps · 7. Log

## 1. Showing the settings

1. Read `factory/config.yaml`'s `pipeline` block, `testing.level`, `security.audit_on_checkpoint` and `discovery.quick_steps`.
2. Show them in `config.language`, compactly: preset, enabled optional stages, UX check, task size, critical full-pipeline override (TEST still excludes docs), testing level, checkpoint audits, and the Discovery steps currently set to quick mode. Explain that TEST runs before DEV only when tests are required; show an item's effective order when asked about its actual stages.
3. Ask whether the user wants to change the preset as a whole, or one setting. Show every option with its description from `factory/core/modes.md` (sections 11-15, and section 5 for the testing level), per the existing rule for choices (`factory/core/FACTORY.md` golden rule 7).

## 2. Choosing a new process

1. **Preset.** Switching to `mvp`, `standard` or `complete` proposes that preset's values for every key (`factory/core/modes.md` section 11); the user can still adjust individual keys afterward, which turns the preset into `custom`.
2. **Individual keys.** Change `pipeline.stages`, `pipeline.ux_check`, `pipeline.task_size`, `pipeline.critical_full_pipeline`, `testing.level`, `security.audit_on_checkpoint` or `discovery.quick_steps` one at a time, each with its description; the preset becomes `custom` once any key no longer matches a preset's values.
3. **Safety nets.** Refuse a choice where `pipeline.stages` would hold neither `review` nor `qa`, or where `pipeline.ux_check` would be `qa` without `qa` in `stages`, or `review` without `review` in `stages`. Explain why in one line and ask again.
4. **Natural language.** A request such as "switch to the standard preset" or "drop the security review stage" is routed here the same as the `Process` command.

## 3. Applying the change

1. Show the current and the new settings side by side, and ask for confirmation.
2. On confirmation, write the changed keys in `factory/config.yaml`, replacing whole lines only.
3. Append a log line: `"<ISO time> process changed: <old summary> -> <new summary>"`.
4. Continue with section 4 for in-flight items, section 5 when `pipeline.task_size` changed, section 6 when `discovery.quick_steps` changed during Discovery.

## 4. In-flight items

1. An item already in progress finishes its current stage under the settings it started with. A checkpoint in progress (`factory/core/workflow/checkpoints.md`) also finishes with the settings it started with; the new settings apply from the next checkpoint on.
2. After its current stage finishes, recompute the future effective order and tests-required decision (`factory/core/workflow/delivery.md` section 4) with the new settings. Preserve the completed prefix as history; only applicable stages still ahead follow the new settings, in canonical order. Do not repeat a completed invocation just because settings changed. Rework after changed code still reruns its downstream gates (delivery section 6).
   - Before the first DEV invocation, a newly applicable TEST runs before DEV. Once DEV has started, enabling `test` never inserts fresh independent test writing, before or after DEV. Existing Test Engineer tests remain protected. If the new testing policy requires additional tests, return to DEV for Developer-owned supplemental tests and then rerun the applicable downstream gates; record this as a separate rework round (delivery section 6), not as stages appended after the completed prefix. Do not rewrite the independent tests. Record why TEST cannot be newly scheduled for this in-flight item. New items use the new policy normally.
3. Append one history line to the item: `<date> · pipeline changed: <old effective order> -> <completed prefix plus new remaining order>`. Include DEV, required item APPROVAL and MERGE; omit disabled or inapplicable future stages, including TEST that would start after DEV. Previously completed stages remain historical facts even if the new settings disable them.
4. Items not started simply use the new settings when they start (`factory/core/workflow/delivery.md` section 3).

## 5. Task size

A `pipeline.task_size` change never edits an existing task. Offer to have the Architect propose regrouping or splitting the tasks that are not started (`factory/core/workflow/backlog.md` sections 3 and 6); the user approves the proposal before anything changes in the backlog, or says to leave it as it is.

## 6. Discovery quick steps

A `discovery.quick_steps` change applies only to Discovery steps not yet started; a step already approved stays approved, and the user can still reopen one with `Change:` (`factory/core/workflow/change-requests.md`). Tell the user in one line which of the remaining steps are now quick or full.

## 7. Log

Every application of this command appends at least the log line of section 3, step 3; an in-flight item's history line (section 4) is in addition to it, not instead of it.
