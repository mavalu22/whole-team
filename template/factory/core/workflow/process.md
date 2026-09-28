# Process

Read for the `Process` command, and whenever a request changes how much delivery process runs (for example "switch to the standard preset", or its direct translation), per the command-recognition rule (`factory/core/FACTORY.md` section 4).

Sections: 1. Showing the settings · 2. Choosing a new process · 3. Applying the change · 4. In-flight items · 5. Task size · 6. Discovery quick steps · 7. Log

## 1. Showing the settings

1. Read `factory/config.yaml`'s `pipeline` block, `testing.level`, `security.audit_on_checkpoint` and `discovery.quick_steps`.
2. Show them in `config.language`, compactly: preset, delivery stages, UX check, task size, whether critical items always run every stage, the testing level, checkpoint audits, and the Discovery steps currently set to quick mode.
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
2. After its current stage finishes, recompute the item's enabled stages (`factory/core/workflow/delivery.md` section 4) with the new settings. Stages already recorded with a verdict are never re-run; only the stages still ahead of it follow the new list.
3. Append one history line to the item: `<date> · pipeline changed: <old enabled stages> -> <new enabled stages>`.
4. Items not started simply use the new settings when they start (`factory/core/workflow/delivery.md` section 3).

## 5. Task size

A `pipeline.task_size` change never edits an existing task. Offer to have the Architect propose regrouping or splitting the tasks that are not started (`factory/core/workflow/backlog.md` sections 3 and 6); the user approves the proposal before anything changes in the backlog, or says to leave it as it is.

## 6. Discovery quick steps

A `discovery.quick_steps` change applies only to Discovery steps not yet started; a step already approved stays approved, and the user can still reopen one with `Change:` (`factory/core/workflow/change-requests.md`). Tell the user in one line which of the remaining steps are now quick or full.

## 7. Log

Every application of this command appends at least the log line of section 3, step 3; an in-flight item's history line (section 4) is in addition to it, not instead of it.
