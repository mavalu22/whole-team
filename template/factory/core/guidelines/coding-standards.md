# Coding standards

Rules every change follows, whatever the stack. Stack specifics (naming case, formatter, linter rules, folder layout) live in `factory/input/04-stack-profile.md`; when they conflict with this file, the stack profile wins. Search this file for the heading you need.

Sections: 1. Naming · 2. Functions and size · 3. Single responsibility · 4. No magic values · 5. Immutability · 6. Error handling · 7. No dead code · 8. Comments · 9. Formatting · 10. Small focused changes · 11. Review checklist

## 1. Naming

- Names say what a thing is or does, in English, without abbreviations except well-known ones (`id`, `url`, `http`).
- Functions are verbs (`calculateTotal`, `sendInvite`); booleans read as questions (`isActive`, `hasAccess`); collections are plural (`orders`).
- Use the domain's words from `factory/input/01-product-vision.md` consistently: one concept, one name, everywhere.
- Name the unit when a number has one: `timeoutMs`, `priceCents`, `maxSizeBytes`.

| Don't | Do |
|---|---|
| `data`, `info`, `tmp`, `obj`, `handle()` | `invoice`, `userProfile`, `pendingEmails`, `retryPayment()` |
| `flag`, `check` | `isExpired`, `canEdit` |
| `timeout = 30` | `timeoutSeconds = 30` |

## 2. Functions and size

- A function does one thing at one level of abstraction. Aim for 30 lines or fewer; above 50, split it unless it is a flat mapping or table.
- At most 3-4 parameters; group more into a named options object or type.
- Return early for invalid cases instead of nesting; keep nesting to 3 levels or fewer.
- Files stay focused: above about 300 lines, look for a second responsibility to extract.

## 3. Single responsibility

- A module, class or function has one reason to change. Business rules don't live in HTTP handlers, UI components or database adapters (`factory/core/guidelines/architecture.md`).
- Don't mix I/O and pure logic: compute in pure functions, then perform I/O at the edges. Pure functions are easier to test.
- Reuse before writing: search for an existing helper first; don't create a second one that does the same thing.

## 4. No magic values

- Literals with meaning become named constants or configuration: limits, timeouts, URLs, roles, status strings, feature flags.
- Values that differ between environments come from configuration (environment variables), never from code.
- Obvious literals (`0`, `1`, `""`, `true`) in obvious places are fine.

```text
Don't: if (attempts > 5) lock(user, 900)
Do:    if (attempts > MAX_LOGIN_ATTEMPTS) lock(user, LOCKOUT_SECONDS)
```

## 5. Immutability

- Declare variables as constant by default; make them mutable only when they must change.
- Don't mutate inputs; return new values. Copy before sorting or changing a collection you received.
- Shared mutable state (module-level variables, singletons holding data) needs a stated reason and protection against concurrent access.

## 6. Error handling

- Handle every error explicitly: recover, translate to a domain error, or propagate. Never swallow one silently (no empty `catch`).
- Validate input at the boundary (`factory/core/guidelines/api-design.md`), then trust it inside.
- Fail fast on programmer errors and invalid configuration at startup; handle expected failures (not found, conflict, timeout) as normal outcomes.
- Error messages for users are helpful and safe; details (stack traces, SQL, paths) go to logs, never to responses.
- Always release resources (files, connections, locks) on every path, with the language's structured mechanism (`finally`, `using`, `with`, `defer`).

## 7. No dead code

- Delete unused code, parameters, imports, files and feature flags; git keeps the history.
- No commented-out code, no debugging output (`console.log`, `print`, `dump`) in commits.
- No speculative generality: don't add parameters, hooks or abstractions for needs no item has.

## 8. Comments

- Comments explain **why**: a constraint, a trade-off, a workaround with its reason, a link to a standard or an issue. The code explains what.
- Public interfaces (exported functions, API handlers, library modules) get a short doc comment: purpose, parameters, errors.
- Keep comments true: update or delete them with the code they describe.
- Don't write `TODO` notes in the code; record follow-ups in your report so they become backlog items.

## 9. Formatting

- The formatter and linter configured in the stack profile decide formatting. Don't hand-format against them, and don't mix formatting-only changes into a functional change.
- Run the format and lint commands before committing; fix lint errors rather than disabling rules. A rule disabled inline needs a comment with the reason.

## 10. Small focused changes

- A change does one thing: the item it belongs to. Refactors of unrelated code become separate items.
- Prefer several small commits that each build and pass tests over one large commit.
- Keep diffs reviewable: rename or move files in a separate commit from edits to them.

## 11. Review checklist

- [ ] Names are clear, consistent with the domain, and carry units.
- [ ] Functions are small, single-purpose, with few parameters and shallow nesting.
- [ ] No magic values; environment-specific values come from configuration.
- [ ] Inputs are not mutated; mutable state is justified.
- [ ] Every error is handled or propagated; no empty catch; resources are released.
- [ ] No dead code, commented-out code or debug output.
- [ ] Comments explain why; public interfaces are documented.
- [ ] Formatter and linter pass without new disabled rules.
- [ ] The change stays within the item's scope.
