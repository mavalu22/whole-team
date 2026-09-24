# Audit

Read for the `Audit` command and for the audit offer during ongoing-project onboarding (`factory/core/workflow/ongoing-projects.md` section 4). Checkpoint audits are smaller and are described in `factory/core/workflow/checkpoints.md`.

Sections: 1. Start · 2. Scope · 3. Report · 4. Mapping findings · 5. Output modes

## 1. Start

1. In a `new` project with no merged code yet, explain that there is nothing to audit and stop.
2. Show the output modes from `factory/core/modes.md` (section 9), `report_first` and `tasks_directly`, with their descriptions, recommend `report_first`, and ask which one.
3. Ask whether the user wants to limit the scope (for example one module); default: the whole repository.
4. Log the audit start.

## 2. Scope

Delegate three audits with stage `AUDIT`, in parallel when the tool allows. Each task message names the report file (`factory/output/audits/AUDIT-<YYYY-MM-DD>.md`), the scope, and the path of the stack profile.

- **`security`**, at `security.audit_tier` (tier override):
  - OWASP Top 10 categories (`factory/core/guidelines/security.md`);
  - secrets in the repository **and its history** (for example `git log -p` searched for key patterns, or a scanner such as `gitleaks` if installed);
  - dependency vulnerabilities (`npm audit`, `pip-audit`, `cargo audit`, or the stack's equivalent);
  - authn and authz, input handling, configuration, logging of sensitive data.
- **`tech-lead`**: likely bugs, error handling gaps, dead code, risky patterns, broken builds or lint.
- **`qa`**: missing tests on critical paths (from `factory/input/07-testing.md`), failing or flaky tests, broken user journeys found by running the product.

Security writes the report file first from `factory/core/templates/audit-report.md`; you add the Tech Lead's and QA's findings to it (Security owns the file, but you merge the other roles' findings from their reports), numbering findings `F-01`, `F-02`, ... across all three.

## 3. Report

`factory/output/audits/AUDIT-<YYYY-MM-DD>.md` (add `-2`, `-3` for a second audit on the same day) contains:

- scope and method (commands and tools run);
- summary by severity (critical, high, medium, low);
- findings table: ID, severity, category, location (`file:line`), evidence, proposed item (bug or task);
- proposed items, grouped.

Show the user a summary in `config.language`: counts by severity and the top findings, at most 10 lines, plus the report path.

## 4. Mapping findings

- **Defects and vulnerabilities** become bugs (`factory/core/workflow/bugs-and-support.md` section 4) with priorities:
  - critical → P0; high → P1; medium → P2; low → P3.
  - Security findings get `Security review: required`.
- **Improvements** (missing tests, refactors, hardening, tooling) become tasks: the Architect drafts them with dependencies following `factory/core/workflow/backlog.md` section 3 (rule 13), followed by a new checkpoint, and the Backlog Validator checks them like any backlog change.
- During onboarding of an ongoing project, before step 8, improvements are not written to `factory/tasks.md`; they are passed to the Architect as inputs for the backlog (`factory/core/workflow/ongoing-projects.md` section 5).

## 5. Output modes

- **`report_first`:** after the report, ask the user which findings to accept, reject or reprioritize (accept all, accept by severity, or list IDs). Create items only for accepted findings. Mark rejected findings in the report as `wontfix` with the user's reason.
- **`tasks_directly`:** create every item right away, then show the user what was created (counts and IDs) and the new checkpoint, and ask for approval of the backlog change (`factory/core/workflow/change-requests.md` section 4). Bugs are created immediately; tasks wait for that approval.
