# Audit report - {{YYYY-MM-DD}}

<!-- Written in factory/output/audits/AUDIT-<YYYY-MM-DD>.md (factory/core/workflow/audit.md). Security creates the file; the Orchestrator merges the Tech Lead's and QA's findings. English. Evidence cites commands and the lines that matter, never whole logs; mask secrets. -->

- **Trigger:** {{Audit command | ongoing-project onboarding | checkpoint CP-n}}
- **Output mode:** {{report_first|tasks_directly}}
- **Commit audited:** {{short hash}} on {{branch}}

## 1. Scope

<!-- What was audited: the whole repository, a module, or a commit range. Anything explicitly excluded. -->

{{scope}}

## 2. Method

<!-- Roles and tiers, and every command and tool run. -->

| Role | Tier | Commands and tools |
|---|---|---|
| security | {{tier}} | {{dependency audit, secret search in files and history, manual review of OWASP categories}} |
| tech-lead | {{tier}} | {{build, lint, type-check, targeted code search}} |
| qa | {{tier}} | {{test suite twice, journeys run}} |

## 3. Summary by severity

| Severity | Count | Maps to |
|---|---|---|
| critical | {{n}} | P0 |
| high | {{n}} | P1 |
| medium | {{n}} | P2 |
| low | {{n}} | P3 |

{{two to four lines on the overall state and the most important findings}}

## 4. Findings

<!-- One row per finding, numbered F-01, F-02, ... across all roles. Category: an OWASP category, bug, error handling, test gap, dead code, build, dependency. Proposed item: bug (defects and vulnerabilities) or task (improvements). -->

| ID | Severity | Category | Location | Evidence | Proposed item | Decision |
|---|---|---|---|---|---|---|
| F-{{nn}} | {{severity}} | {{category}} | {{file:line}} | {{command -> result}} | {{bug P1 | task}} | {{accepted -> B-xxx/T-xxx | wontfix: reason | pending}} |

## 5. Proposed items

### Bugs

- F-{{nn}} → {{title}} · {{priority}} · Touches: {{areas}}

### Tasks

- F-{{nn}} → {{title}} · depends on {{T-xxx or —}} · Touches: {{areas}}

<!-- Tasks go after the last task with a new checkpoint, unless the user asks otherwise (factory/core/workflow/backlog.md section 3, rule 13). -->
