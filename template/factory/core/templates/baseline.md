# Baseline - {{YYYY-MM-DD}}

<!-- Written by the Architect in factory/output/baseline.md during reverse Discovery of an ongoing project (factory/core/workflow/ongoing-projects.md section 2), in English, before the factory changes anything. Failures recorded here are known failures and are not blamed on new work. Quote only the lines that matter; never whole logs. -->

- **Commit:** {{short hash}} on {{branch}}
- **Environment:** {{OS, runtime versions, package manager version}}

## 1. Commands and results

| Check | Command | Result | Summary |
|---|---|---|---|
| Install | `{{command}}` | {{pass|fail}} | {{e.g. 812 packages, 3 deprecation warnings}} |
| Tests | `{{command or "not configured"}}` | {{pass|fail|not configured}} | {{e.g. 210 passed, 4 failed, 2 skipped}} |
| Lint | `{{command or "not configured"}}` | {{pass|fail|not configured}} | {{e.g. 37 errors, 120 warnings}} |
| Type-check | `{{command or "not configured"}}` | {{pass|fail|not configured}} | {{e.g. 12 errors}} |
| Build | `{{command or "not configured"}}` | {{pass|fail|not configured}} | {{summary}} |

## 2. Known failures

<!-- Every failing test, lint rule or build error, grouped, with the lines that identify it. Items that touch these areas note them, and QA compares against this list. -->

### Tests

- `{{test file}} > {{test name}}`: {{assertion or error line}}

### Lint and type-check

- `{{rule or error code}}`: {{count}} occurrences, e.g. `{{file:line}}`

### Build

- {{error line, or "none"}}

## 3. Could not run

<!-- Checks that could not run, and why (missing services, secrets, unsupported OS). Record the user's decision to continue without them. -->

- {{check}}: {{reason}} · {{user decision and date}}

## 4. Notes

<!-- Anything else that affects delivery: slow suites, flaky tests observed across two runs, required services, outdated runtimes. -->

- {{note}}
