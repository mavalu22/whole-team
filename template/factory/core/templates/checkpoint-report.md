# Checkpoint CP-{{n}} · {{title}}

<!-- Written by the Orchestrator in factory/output/checkpoints/CP-<n>.md (factory/core/workflow/checkpoints.md section 2, step 5), in config.language. Keep it short and practical: the user validates the product with it. -->

- **Date:** {{YYYY-MM-DD}}
- **Integration branch:** {{develop}} at {{short hash}}
- **Pull request:** {{URL or "local merge"}}

## 1. What this checkpoint delivers

<!-- 2-5 lines in user terms: what the user can now do. -->

{{summary}}

## 2. Items included

| ID | Title | Type | Merge commit |
|---|---|---|---|
| T-{{xxx}} | {{title}} | {{type}} | {{short hash}} |
| B-{{xxx}} | {{title}} | bug {{priority}} | {{short hash}} |

## 3. How to run locally

<!-- Exact commands from the stack profile, in order, starting from a fresh clone of the integration branch. -->

1. `git switch {{integration branch}} && git pull`
2. `{{install command}}`
3. `cp .env.example .env` and set: {{settings that need a value}}
4. `{{one-command local run}}`
5. Open {{local URL}}

## 4. Validation checklist

<!-- Derived from the acceptance criteria of the items included: one line per thing the user should try, with the expected result. -->

- [ ] {{action}} → {{expected result}} ({{T-xxx AC1}})
- [ ] {{action}} → {{expected result}} ({{T-xxx AC2}})

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
