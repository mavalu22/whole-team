---
step: s4_stack_profile
status: draft        # draft | approved
approved_at: null
language: null       # set to input_language when first written
---

# Stack profile

## 1. Folder structure
<!-- The repository tree to top-level module folders, with what each folder holds and where tests live. -->

## 2. Naming
<!-- Case and naming rules for files, folders, types, functions, variables, constants, database objects, test files, and branches' {slug}. -->

## 3. `Touches` vocabulary
<!-- The allowed Touches areas (e.g. auth, db, data, migrations, api/<resource>, ui/<screen>, infra, ci, docs), each with the folders it covers. -->

## 4. Commands
<!-- Exact commands, run from the project root: install, dev, test, lint, type-check, format, build (plus migrate and seed when relevant). -->

## 5. Quiet command forms
<!-- For test, lint, type-check and build: the command variant that prints only failures and a summary, plus how to run a single test verbosely. -->

## 6. Lint, format and type-check configuration
<!-- Tools, config files, strictness choices (e.g. TypeScript strict), pre-commit hooks yes or no. -->

## 7. Testing tools
<!-- Unit, integration and E2E tools; test file naming and location; coverage tool and command. -->

## 8. Error handling
<!-- How errors are represented, propagated and turned into responses or messages; error types and the API error format. -->

## 9. Logging
<!-- Logging library, format per environment, levels, correlation ID handling, redaction of sensitive fields. -->

## 10. Configuration and env
<!-- How configuration is loaded and validated, naming of environment variables, .env.example rules. -->

## 11. Dependency policy
<!-- Version range style, lockfile, license allowlist reference, how dependencies are added and audited (audit command). -->

## 12. Framework patterns and anti-patterns
<!-- Patterns to follow and patterns to avoid for the chosen frameworks, as checkable rules with short examples. -->

## 13. Tooling exclusions for `factory/`
<!-- Where factory/ is excluded in each tool: test runner, linter, formatter, type-checker, bundler, coverage, Docker build context (.dockerignore). -->

## 14. Parallel slot isolation (ports, database)
<!-- How FACTORY_SLOT sets the port (e.g. base + 10 x slot), the database name or file, and any other per-slot resource. -->

## 15. Open questions
<!-- Questions still unanswered; remove each when resolved, or mark it "accepted as open" with the user's agreement. -->
