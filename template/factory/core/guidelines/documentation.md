# Documentation

The product's own documentation: README, API docs, CHANGELOG and ADRs. Product docs are written in `config.product_docs_language` (the task message names it); code identifiers, commands and file names stay as they are. Factory documents (inputs, outputs) follow their own language rules and are not product docs. Search this file for the heading you need.

Sections: 1. Principles · 2. Product README · 3. API docs · 4. CHANGELOG · 5. ADRs · 6. Code-level docs · 7. Review checklist

## 1. Principles

- Docs describe what exists and works now, on the branch being merged. Plans and future features stay out.
- Every command in the docs is copied from the stack profile or the project's scripts, and was run at least once.
- Write for the reader's task: how to install, run, use, test, contribute. Short sections, numbered steps for procedures, examples before explanations.
- Keep one source of truth: generate API reference from the contract when possible, and link instead of duplicating.
- Update docs in the same change as the behavior they describe; the Tech Writer consolidates at checkpoints.

## 2. Product README

`README.md` at the repository root, with these sections in this order (omit a section only if it doesn't apply):

1. **Title and summary:** what the product is and who it is for, in 2-3 sentences.
2. **Features:** the main capabilities delivered so far, as a short list.
3. **Requirements:** runtimes and versions, package manager, services (database, Docker).
4. **Getting started:** clone, install, configure (`cp .env.example .env` and which values to set), run with the one-command local run, and the local URL.
5. **Usage:** the main tasks a user or client performs, with short examples.
6. **Testing:** how to run tests, lint and type-check.
7. **Project structure:** the top-level folders and what they hold, briefly.
8. **Configuration:** a pointer to `.env.example`, and the settings that matter most.
9. **Deployment:** a pointer to the hosting guide the user keeps, if they chose to publish it; the factory itself never deploys.
10. **License.**

Keep content the user wrote; edit only the sections that changed.

## 3. API docs

- For HTTP APIs, the contract (OpenAPI or the stack's schema) is the reference. Keep descriptions, examples and error responses in it; publish or render it as the stack profile says (for example `docs/api.md` generated from it, or a docs route in development).
- Each endpoint documents: method and path, purpose, auth requirement, parameters, request body with an example, responses with examples (success and each error `type`), pagination and rate limits.
- For libraries and CLIs: every public function or command with its signature or usage line, parameters or flags, return values or output, errors, and an example.
- Examples use synthetic data only: no real emails, tokens or hostnames.

## 4. CHANGELOG

`CHANGELOG.md` follows Keep a Changelog 1.1:

```markdown
# Changelog

## [Unreleased]

## [CP-2] - 2026-02-14
### Added
- Password reset by email.
### Fixed
- Login button works on Safari.
```

- One section per checkpoint (`[CP-<n>]`, or a semantic version if the project uses versions), newest first, with the date.
- Groups in this order, only when non-empty: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- One line per user-visible change, written for users; internal refactors and test-only changes are left out.
- Never rewrite released sections, except to fix a factual error.

## 5. ADRs

- Architecture Decision Records live in `factory/output/adr/` (factory documents, in English, from `factory/core/templates/adr.md`) and follow `factory/core/guidelines/architecture.md` section 6.
- If the user wants decisions visible in the product repository, the Tech Writer may summarize accepted ADRs in `docs/architecture.md` in the product docs language, linking the decisions by number.

## 6. Code-level docs

- Public interfaces get a doc comment in the language's standard format (JSDoc, docstrings, rustdoc): purpose, parameters, return value, errors.
- Comments explain why, not what (`factory/core/guidelines/coding-standards.md` section 8).
- Generated docs build without warnings when the stack generates them.

## 7. Review checklist

- [ ] Docs match the merged behavior; no planned features described as done.
- [ ] Every command exists and was run.
- [ ] README sections follow section 2; user-written content is preserved.
- [ ] Every new or changed public interface is documented with examples and errors.
- [ ] CHANGELOG has a correctly grouped entry for the checkpoint.
- [ ] Docs are in the product docs language; examples use synthetic data.
