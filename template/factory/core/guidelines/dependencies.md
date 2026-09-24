# Dependencies

When and how to add, pin, update and remove third-party packages. The package manager, the dependency policy and the license allowlist are in `factory/input/04-stack-profile.md` and `factory/input/06-constraints.md` (license policy). Search this file for the heading you need.

Sections: 1. Adding a dependency · 2. Licenses · 3. Pinning and lockfiles · 4. Updates · 5. Removing dependencies · 6. Review checklist

## 1. Adding a dependency

Before adding a package, check each point and state the result in your report:

1. **Need.** The standard library, the framework or an existing dependency can't do it in reasonable code (roughly 50 lines or fewer is usually better written than imported).
2. **Maintenance.** A release in the last 12 months, active issue handling, more than one maintainer or an organization behind it, and no deprecation notice.
3. **Adoption.** Widely used for this purpose in the stack's ecosystem; prefer the option the stack profile or the framework recommends.
4. **License.** On the allowlist (section 2).
5. **Size and footprint.** Reasonable install and bundle size for what it does; few transitive dependencies; for front-end code, check the bundle impact.
6. **Security.** No open `critical` or `high` advisories (run the audit tool after installing); no install scripts that download or execute unexpected code.
7. **Source.** From the official registry, spelled correctly (typosquatting check), with the expected publisher.

Add it with the package manager (never by editing the lockfile by hand), as a development dependency when only tooling or tests use it.

| Don't | Do |
|---|---|
| Add a date library to format one date | Use the platform's `Intl` or standard date formatting |
| Add a package for a 10-line helper (`is-even`, `left-pad`) | Write the helper, with a test |
| Pick the first search result | Pick the ecosystem's established option, checked against section 1 |
| Add a second library for something a dependency already does | Reuse the existing dependency |

Example justification in a report:

```text
DEPENDENCY: zod 3.x (MIT) - schema validation at the API edge; framework has none built in;
weekly releases, organization-maintained; 0 advisories (npm audit); 57 KB unpacked, no install scripts.
```

## 2. Licenses

- The allowlist comes from `factory/input/06-constraints.md`. When it defines none, allow: MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, Unlicense, CC0-1.0, Zlib, Python-2.0, MPL-2.0 (file-level copyleft; acceptable for unmodified use).
- Copyleft licenses (GPL, AGPL, LGPL in statically linked contexts, SSPL) and unknown or custom licenses need the user's explicit approval: return `BLOCKED` with the package, its license and the alternative.
- Check the license of the exact version you add, not only the repository's current one.

## 3. Pinning and lockfiles

- Commit the lockfile; CI and all installs use it (`npm ci`, `pnpm install --frozen-lockfile`, `pip install -r` with hashes or a lock tool, `cargo build --locked`, or the stack's equivalent).
- Declare version ranges as the stack profile says (for example caret ranges for libraries, exact versions for tools with breaking patch releases); the lockfile pins the exact resolved versions.
- Pin runtime versions (language, package manager) in the project's version files, as the stack profile defines.
- Pin third-party CI actions and container base images to a version or digest.

## 4. Updates

- Update dependencies in dedicated items or commits (`build(deps): update <package> to <version>`), not mixed with feature work.
- Security fixes for `critical` or `high` advisories are bugs with priority P0 or P1 and follow the bug pipeline.
- Read the changelog for major versions; update one major version at a time, with the full test suite passing.
- After updating, run the audit tool and the quiet test, lint, type-check and build commands.

## 5. Removing dependencies

- Remove a dependency in the same change that removes its last use; don't leave unused packages behind.
- Check periodically (at audits) for unused dependencies with the stack's tool (for example `depcheck`, `knip`, `deptry`, `cargo udeps`), and remove them in a dedicated commit.
- After removal, reinstall from a clean state and run the build and tests to confirm nothing relied on it transitively.

## 6. Review checklist

- [ ] Each new dependency passes the seven checks of section 1, stated in the report.
- [ ] Each license is on the allowlist, or the user approved it.
- [ ] The lockfile is updated and committed; no hand edits.
- [ ] Development-only packages are declared as development dependencies.
- [ ] The audit tool shows no new `critical` or `high` advisories.
- [ ] Dependencies no longer used are removed.
