# Code review

The checklist the Tech Lead applies in the REVIEW stage, with the severity levels and the finding format. DBA and UX/UI reviewers use the same severities and format with their own checklists. Search this file for the heading you need.

Sections: 1. Method · 2. Review checklist · 3. Severity levels · 4. Finding format · 5. Verdict · 6. Rework rounds

## 1. Method

1. Scope the change: `git diff <base>...<branch> --stat`, then the diff file by file.
2. Read the item's acceptance criteria first; review the diff against them.
3. Open code outside the diff only to follow a concrete concern: a caller of a changed function, a contract, a shared helper.
4. Run the quiet lint and type-check commands from `factory/input/04-stack-profile.md`; record the result lines.
5. Check the Test Engineer's tests are unchanged: `git diff <TEST commit> <branch> -- <test paths>` (commit and paths are in the item history).

## 2. Review checklist

**Correctness**
- [ ] Every acceptance criterion is implemented, and each is traceable to code in the diff.
- [ ] Edge cases the criteria imply are handled: empty input, limits, duplicates, concurrency, time zones.
- [ ] Errors are handled or propagated explicitly; failures don't leave partial state.

**Scope**
- [ ] The diff contains only what the item needs; no unrelated refactors, renames or formatting.
- [ ] No features beyond the criteria; follow-ups are reported, not implemented.

**Stack-profile conformance**
- [ ] Folder structure, naming, patterns and anti-patterns follow `factory/input/04-stack-profile.md`.
- [ ] Module boundaries and dependency direction follow `factory/core/guidelines/architecture.md`.

**Readability**
- [ ] Code follows `factory/core/guidelines/coding-standards.md`: clear names, small functions, no magic values, no dead code, comments explain why.

**Errors and logging**
- [ ] User-facing errors are safe and helpful; internals go to logs.
- [ ] Logging follows `factory/core/guidelines/observability.md`: structured, right level, no secrets or unnecessary personal data.

**Performance red flags**
- [ ] No queries in loops (N+1), no unbounded lists, no blocking I/O on hot paths, no large payloads without pagination (`factory/core/guidelines/performance.md`).

**Tests**
- [ ] Tests exist at the required level and pass (lint, type-check and test evidence present).
- [ ] The Test Engineer's tests are unmodified (or the dispute fix is recorded).
- [ ] New tests are deterministic and test behavior (`factory/core/guidelines/testing.md`).

**Dependencies**
- [ ] Each added dependency is justified, maintained and license-compatible (`factory/core/guidelines/dependencies.md`); the lockfile is updated.

**Data**
- [ ] Migrations are reversible or documented forward-only, and safe on existing data.

**Configuration and secrets**
- [ ] New settings are read from the environment and listed in `.env.example`.
- [ ] No secrets or credentials in the diff.

**Docs**
- [ ] Public behavior changes are reflected in the API contract and product docs.

## 3. Severity levels

| Severity | Meaning | Examples | Effect |
|---|---|---|---|
| `blocker` | The item is wrong or unsafe | An acceptance criterion not met; data loss; a test modified; a secret committed; a broken build | Must be fixed; verdict `REJECTED` |
| `major` | A real defect or rule violation that will cause problems | Unhandled error path; N+1 on a list endpoint; missing validation; convention broken in a way that affects maintainability; missing required test | Must be fixed; verdict `REJECTED` |
| `minor` | A small issue that does not affect behavior | A magic number; an unclear name; a missing doc comment on a public function | Fix if the item returns to DEV for another reason; recorded otherwise |
| `info` | A suggestion or preference no rule requires | An alternative structure; a possible future refactor | Never a reason to reject |

Security reviews use `critical`, `high`, `medium`, `low` (`factory/core/roles/security.md`).

## 4. Finding format

One line per finding:

```text
- [<severity>] <file:line> <problem> -> <required fix>
```

- **Location:** the file and line in the branch's version. For a missing piece, the file and line where it belongs.
- **Problem:** what is wrong and why, citing the criterion, rule or guideline (`AC2`, `coding-standards §6`).
- **Required fix:** the concrete change that resolves it, specific enough to act on without discussion.

Examples:

```text
- [blocker] src/orders/service.ts:88 AC3 not met: cancelled orders still charge the card -> call payments.refund before setting status cancelled
- [major] src/orders/routes.ts:21 body not validated (api-design §4) -> validate against the CreateOrder schema and return 422 with field errors
- [minor] src/orders/service.ts:40 magic value 30 (coding-standards §4) -> use ORDER_EXPIRY_MINUTES
```

## 5. Verdict

- `REJECTED` when at least one `blocker` or `major` finding exists.
- `APPROVED` otherwise; list `minor` and `info` findings for the record.
- Never reject for preferences no rule supports; never approve with an open `blocker` or `major`.

## 6. Rework rounds

1. Check that each previous finding is fixed, and say so per finding in the summary.
2. Review only the changes since the last reviewed commit (`git diff <last reviewed commit>..<branch>`), unless the fixes changed the design; then review the whole diff again.
3. Don't raise new `minor` findings on unchanged code in later rounds; raise new `blocker` or `major` findings wherever they are.
