<!-- Body of the checkpoint pull request, integration branch -> base branch (factory/core/workflow/checkpoints.md section 3). English. Written to a temporary file outside the repository and passed with --body-file. Add a Co-authored-by trailer only when git.ai_coauthor is true. -->

## Checkpoint CP-{{n}}: {{English title}}

{{two to four lines: what this checkpoint delivers, in user terms}}

## Items

| ID | Title | Type |
|---|---|---|
| T-{{xxx}} | {{English title}} | {{type}} |
| B-{{xxx}} | {{English title}} | bug {{priority}} |

## How to validate

1. `{{install command}}`
2. `cp .env.example .env` and set {{settings}}
3. `{{one-command local run}}`, then open {{local URL}}
4. Check:
   - [ ] {{action}} → {{expected result}}
   - [ ] {{action}} → {{expected result}}

## Test results

- Tests: {{passed/failed counts}} (`{{quiet test command}}`)
- Lint, type-check, build: {{results}}
- Coverage: {{percent, or "not enforced at this testing level"}}

## Audit summary

- Findings: critical {{n}} · high {{n}} · medium {{n}} · low {{n}}
- Fixed: {{B-xxx, ...}} · Open: {{B-xxx (P2), ...}}

## Known issues

- {{issue, or "None"}}
