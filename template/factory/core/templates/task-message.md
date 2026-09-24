# Task message

<!-- Built by the Orchestrator for every delegation, in English (factory/core/workflow/delegation.md section 3). Keep every section, in this order, even when its value is "—". Give excerpts, never whole documents; give absolute paths for everything else. -->

```text
ROLE: {{role_slug}}
ITEM: {{item_id}} · {{item_title}}
STAGE: {{stage}}
GOAL: {{stage_goal}}
WORKING DIRECTORY: {{absolute_working_directory}}
PROJECT ROOT: {{absolute_project_root}} (factory files are here: open them by exact path)
BRANCH: {{branch}} · BASE: {{base_branch}}
SLOT: {{slot_number_or_dash}}
RUNTIME ENV: {{slot_environment_variables_or_dash}}

READ FIRST:
- {{absolute_path_1}}
- {{absolute_path_2}} (section {{section_number}} only)

ITEM BLOCK:
{{full_item_block_from_tasks_or_bugs}}

EXCERPTS:
{{acceptance_criteria_contracts_findings_test_paths_answers}}

CONSTRAINTS:
- Push: {{push_allowed_yes_or_no}}
- {{what_not_to_touch}}
- {{stage_specific_limits}}

REPORT FIELDS:
{{role_specific_report_fields_or_none}}
```

<!-- Notes for the Orchestrator:
- STAGE is one of TEST, DEV, REVIEW, QA, SEC, AUDIT, SUPPORT, DISCOVERY, VALIDATION, DOCS.
- In parallel mode, WORKING DIRECTORY is the worktree, and CONSTRAINTS adds: "Every command must start with cd <worktree> && ... or use git -C <worktree>."
- EXCERPTS for rework contain only the open findings, each with file:line and the required fix.
- For a tier override (required security reviews, audits), set the model when spawning; the message itself does not change. -->
