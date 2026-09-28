# Checkpoint CP-{{n}} · {{title}}

<!-- Written by the Orchestrator in factory/output/checkpoints/CP-<n>.md (factory/core/workflow/checkpoints.md section 2, step 5), in config.language. Keep it short and practical: the user validates the product with it. -->

- **Date:** {{YYYY-MM-DD}}
- **Integration branch:** {{develop}} at {{short hash}}
- **Pull request:** {{URL or "local merge"}}

## 1. What this checkpoint delivers

<!-- 2-5 lines in user terms: what the user can now do. -->

{{summary}}

## 2. Items included

<!-- Attachments column: the paths linked to the item (factory/attachments/<ID>/...), so the user can compare during validation, or "—". -->

| ID | Title | Type | Merge commit | Attachments |
|---|---|---|---|---|
| T-{{xxx}} | {{title}} | {{type}} | {{short hash}} | {{paths or —}} |
| B-{{xxx}} | {{title}} | bug {{priority}} | {{short hash}} | {{paths or —}} |

## 3. How to try it

<!-- Exact commands from the stack profile, starting from a fresh clone of the integration branch: the common setup, then one short block per interface in project.interfaces. Leave out the blocks of other interfaces; a gui that lives inside a plugin is covered by the Plugin block. -->

1. `git switch {{integration branch}} && git pull`
2. `{{install command}}`
3. `cp .env.example .env` and set: {{settings that need a value}}

- **App (`gui`):** `{{one-command local run}}`, then open {{local URL}}.
- **API (`api`):** `{{one-command local run}}`, then `{{example request}}`.
- **CLI (`cli`):** `{{run command}} --help`, then `{{example command}}`.
- **Worker (`service`):** `{{start command}}`, then `{{how to send a test input}}`, and watch {{logs or output}}.
- **Library (`library`):** `{{pack command}}`, then in a sample project `{{install the local package}}` and `{{example usage}}`.
- **Plugin (`plugin`):** `{{launch the host in development mode}}`, then {{where to find the plugin in the host}}.

## 4. Validation checklist

<!-- Derived from the acceptance criteria of the items included: one line per thing the user should try, with the expected result. Include every MANUAL criterion from task Notes: QA could not run it, so only the user verifies it. -->

- [ ] {{action}} → {{expected result}} ({{T-xxx AC1}})
- [ ] {{action}} → {{expected result}} ({{T-xxx AC2}})
- [ ] MANUAL: {{exact steps}} → {{expected result}} ({{T-xxx AC3}}, not verified by QA)

Report any problem with `Support: <description>`.

## 5. Test results

| Check | Command | Result |
|---|---|---|
| Tests | `{{quiet test command}}` | {{passed/failed counts}} |
| Coverage | `{{coverage command}}` | {{percent}} (target {{coverage_target}}, level full only) |
| Lint | `{{quiet lint command}}` | {{result}} |
| Type-check | `{{quiet type-check command}}` | {{result}} |
| Build | `{{quiet build command}}` | {{result}} |

## 6. Audit summary

<!-- From the checkpoint audit, if security.audit_on_checkpoint is true; otherwise "Not run (audit_on_checkpoint is false)". -->

- **Findings:** critical {{n}} · high {{n}} · medium {{n}} · low {{n}}
- **Fixed before this checkpoint:** {{B-xxx, ...}}
- **Open:** {{B-xxx (P2), ...}}

## 7. Known issues

<!-- Open non-blocking bugs, findings accepted as-is (from task Notes), and baseline failures in ongoing projects. -->

- {{issue}} ({{B-xxx or T-xxx note}})

## 8. What comes next

<!-- The next checkpoint and what it delivers, and the number of tasks until then. Or, for the final checkpoint, the remaining bugs and maintenance. -->

{{next}}
