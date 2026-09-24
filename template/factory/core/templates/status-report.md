<!-- Layout for the Status command (factory/core/workflow/status.md). Shown in the chat in config.language, at most 15 lines; not written to a file. Omit lines that are empty. Built only from factory/state.yaml and the summary blocks. -->

**{{Phase}}** · {{Discovery step n of 8 (name) | Wave n of m}}

- **Progress:** {{approved steps: 1, 2, 3 | TODO n · IN_PROGRESS n · QA n · DONE n · CANCELLED n}}
- **In flight:** {{T-xxx (stage, slot n), B-xxx (stage) | none}}
- **Waiting for you:** {{pending approvals and escalations, one short item each | nothing}}
- **Bugs:** {{P0 n · P1 n · P2 n · P3 n}} {{(blocking: B-xxx) | }}
- **Next checkpoint:** {{CP-n · title}} ({{n}} tasks left)
- **Last checkpoint:** {{CP-n · title, merged YYYY-MM-DD | none yet}}
- **Graph:** `factory/tasks-graph.md`

**Next:** {{the single most useful next action}}
