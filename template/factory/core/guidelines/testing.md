# Testing

How the factory writes and runs tests. The level (`none`, `critical`, `full`), critical areas, E2E flows and test data strategy are in `factory/input/07-testing.md`; tools and commands are in `factory/input/04-stack-profile.md`. Search this file for the heading you need.

Sections: 1. Test pyramid · 2. Naming · 3. Structure · 4. Deterministic tests · 5. Test data and fixtures · 6. Behavior, not implementation · 7. Regression tests for bugs · 8. Flaky tests · 9. Coverage policy · 10. Test Engineer independence · 11. Review checklist

## 1. Test pyramid

| Level | What it tests | Dependencies | Share |
|---|---|---|---|
| Unit | One function, class or module's rules | None; collaborators replaced by simple fakes | Most tests |
| Integration | A module with its real infrastructure: an endpoint with the database, a repository with SQL, an adapter against a local stand-in | Real local database and services; external APIs faked at the network boundary | Fewer |
| End-to-end (E2E) | A user journey through the running product (UI or public API) | The whole product, locally | Few: only the flows in `07-testing.md` |

- Put each test at the lowest level that can prove the behavior.
- Business rules get unit tests; contracts (API, persistence) get integration tests; journeys get E2E tests.

## 2. Naming

- A test name states the behavior and the condition: `returns 423 after 5 failed logins`, `total includes tax for EU customers`.
- Tests written from acceptance criteria start with the criterion ID: `AC2: locks the account after 5 failed logins`.
- Group tests by the unit or feature under test (a `describe` block, a test class, a file per module).
- Follow the stack profile for test file names and locations.

## 3. Structure

- Arrange, act, assert: set up, perform one action, check the outcome. Separate the three parts with blank lines when the test is longer than a few lines.
- One behavior per test. Several assertions are fine when they describe one outcome.
- Keep setup visible: a reader understands the test without opening many helpers. Use builders or factories for noisy objects.
- Assert specific values (`expect(status).toBe(423)`), not just truthiness.

## 4. Deterministic tests

- No real network calls to third parties; fake them at the boundary.
- No sleeping or waiting on wall-clock time: fix the clock, or wait for a condition with a timeout.
- Fix random seeds; generate IDs deterministically in tests when they matter.
- No order dependence: each test creates what it needs and cleans up (transactions rolled back, per-test schemas or records).
- Parallel slots: tests use the slot's database and ports from `FACTORY_SLOT`, never a shared one.

## 5. Test data and fixtures

- Use factories or builders with sensible defaults, overriding only the fields the test cares about.
- Keep fixtures small and synthetic; never use real personal data.
- Seed reference data once per suite if needed, in a way that is safe to re-run.
- E2E data: create through the product's own API or seed commands, not by editing tables behind the product's back, unless the stack profile says otherwise.

## 6. Behavior, not implementation

- Test through public interfaces: exported functions, HTTP endpoints, UI as a user sees it (roles, labels, text), not private methods or internal state.
- Don't assert on log text, internal call counts or private data structures unless an acceptance criterion requires it.
- Mock only what you don't own or what is slow or nondeterministic (external APIs, clock, randomness). Prefer fakes with real behavior over mocks that assert calls.
- A refactor that keeps behavior must not break tests; if it does, the tests were coupled to implementation.

## 7. Regression tests for bugs

- Every bug fix starts with a test that reproduces it and fails on the current code (unless the testing level is `none`).
- Name it after the bug: `B-007: login returns 401 (not 500) for an unknown email`.
- Keep it permanently in the suite at the lowest level that reproduces the bug.

## 8. Flaky tests

- A flaky test passes and fails on the same code. It is a defect, not noise.
- When a test fails, rerun it once in isolation. If it passes, it is flaky: report it as a finding (QA) or a bug; never ignore it.
- Fix the cause (shared state, timing, order, real network) rather than adding retries.
- Quarantining (skipping) a flaky test needs a bug that tracks it and the user's knowledge; never skip silently.

## 9. Coverage policy

| `testing.level` | Automated tests | Suite runs | Coverage |
|---|---|---|---|
| `none` | None; QA verifies by running the product | Existing tests, if any, at checkpoints | Not measured |
| `critical` | Items with `Critical: yes`, and a regression test for every bug | Related tests while developing; the item's tests in QA; the full suite at checkpoints | Not enforced |
| `full` | Every item except `docs` items | Full suite before every merge and at every checkpoint | `testing.coverage_target` (line coverage) enforced at checkpoints |

- Coverage is a floor, not a goal: a covered line is not a tested behavior. Reviewers still check that criteria are tested.
- Exclude generated code, configuration and `factory/` from coverage.

## 10. Test Engineer independence

These rules keep tests an independent check on the implementation:

1. The Test Engineer writes tests **before** implementation, from the acceptance criteria and the published contracts (API specs, shared types, UI spec), never from the new implementation.
2. The tests are committed on the item branch (`test(<scope>): ...`) before DEV starts, and are expected to fail until DEV finishes.
3. The Developer never modifies, skips or deletes those tests. If a test looks wrong, the Developer returns `BLOCKED` and the Test Engineer adjudicates against the criteria.
4. The Tech Lead verifies the tests are unchanged since their TEST commit, except for recorded dispute fixes.
5. The Developer may add further tests of its own; they don't replace the Test Engineer's.
6. In the fallback (no subagents), the Orchestrator writes and commits the tests before DEV and never edits them during DEV.

## 11. Review checklist

- [ ] Tests exist at the level the testing policy requires, one or more per acceptance criterion.
- [ ] Names state behavior and criterion IDs.
- [ ] Tests are deterministic: no real network, sleeps, shared state or order dependence.
- [ ] Tests use public interfaces, not implementation details.
- [ ] Bugs have a regression test named with the bug ID.
- [ ] Test Engineer tests are unchanged since their commit.
- [ ] No skipped tests without a tracking bug.
