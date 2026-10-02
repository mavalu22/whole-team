# Quality gates

Read before an item starts (Definition of Ready) and before it merges (Definition of Done). These gates are never skipped (FACTORY.md golden rule 3).

Sections: 1. Definition of Ready · 2. Definition of Done · 3. Rejection policy · 4. Evidence rules

## 1. Definition of Ready

An item may start only when all of these hold:

- [ ] Acceptance criteria are testable: each describes observable behavior with concrete values or states (1-7 for tasks; for bugs, the `Expected` field plus the reproduction steps).
- [ ] Dependencies and `Touches` are declared.
- [ ] `Refs` are present (tasks) or `Reproduction` and `Evidence` are present (bugs).
- [ ] `Critical` (tasks) and `Security review` are set.
- [ ] The item fits `pipeline.task_size`: with `session`, one slice, at most about 7 criteria, roughly 8 production files or fewer; with `feature`, one user-visible feature, page or capability with everything it needs, still at most about 7 criteria.
- [ ] The input documents it references are approved (front matter `status: approved`).

If a check fails, fix the item before starting it: criteria with the Product Owner role, dependencies and size with the Architect, anything that needs a decision with the user.

## 2. Definition of Done

An item may merge only when all of these hold:

- [ ] Every acceptance criterion is checked: with evidence in a QA report when `qa` is one of the item's enabled stages (a criterion QA marks `MANUAL` with exact steps is recorded in the item's `Notes` for the next checkpoint's validation checklist); otherwise from the Developer's `CRITERIA` mapping in DEV, confirmed by REVIEW's traceability check when `review` is enabled.
- [ ] Required tests exist and pass, using delivery section 4's decision (testing level, bugs, critical override, docs exception): committed by the Test Engineer before DEV when TEST runs, or by the DEV role before implementation otherwise. Independent tests are unchanged except for recorded Test Engineer dispute corrections (verified by the Tech Lead when REVIEW runs); developers cannot weaken, skip or delete tests to pass a gate.
- [ ] Lint, type-check and build pass.
- [ ] TEST (when applicable) and DEV are `DONE`; every applicable REVIEW, QA and SEC gate has current `APPROVED` verdicts from all required reviewers. Required item APPROVAL is recorded. Disabled or inapplicable stages need no verdict; MERGE follows these checks.
- [ ] Docs are updated if public behavior changed (README usage, API docs).
- [ ] No secrets are in the code or the history of the branch.
- [ ] `.env.example` is updated for every new setting.
- [ ] With `per_task`, the user approved.
- [ ] After merging: the item is `DONE` in `factory/tasks.md` or `factory/bugs.md`, with the merge commit in its history.

## 3. Rejection policy

- REVIEW, QA and SEC return `APPROVED` or `REJECTED`. A rejection must carry actionable findings: `file:line`, the problem, and the required fix.
- A rejection sets `REVIEW_REJECTED`, `QA_REJECTED` or `SEC_REJECTED`, increments `Rejections`, and sends the findings back to DEV. One review round with any rejection counts as one rejection, however many reviewers rejected.
- User feedback at APPROVAL, rebase conflicts and test failures after a rebase send the item back to DEV without counting as rejections.
- When `Rejections` reaches `execution.max_rejections`, the item becomes `BLOCKED` and the user decides (`factory/core/workflow/delivery.md` section 7).
- Reviewers judge against the acceptance criteria, the stack profile and the guidelines. Preferences that no rule supports are reported as `[info]` findings and never cause a rejection.

## 4. Evidence rules

- QA and Security reports cite the commands they ran and their results: `<command> -> <result>`, for example `npm test -- --silent -> 48 passed, 0 failed`.
- Evidence quotes only the lines that matter (the failing test and its assertion, the HTTP status and the relevant body field, the lint error), never whole logs.
- Each acceptance criterion maps to at least one evidence line: `AC2: curl -s -o /dev/null -w "%{http_code}" -X POST .../login (wrong password) -> 401`.
- Screenshots are evidence only for criteria about appearance or layout; store them in `factory/output/evidence/<ID>/` (absolute path in the task message) and cite the path.
- A claim without evidence counts as not verified. The Orchestrator never checks an acceptance criterion or records a test result without evidence.
- Evidence must come from the item's current code: after rework or a rebase that changed code, rerun the applicable post-DEV gates and required item approval. Execute the existing tests again; never restart the independent test-writing stage. Preserve its commit and test paths, subject only to a recorded Test Engineer dispute correction.
