# Libraries and plugins

Rules for code that other code imports (`library`) and for extensions loaded by a host application (`plugin`). The public API, version policy, host and manifest of this product are in `factory/input/05-design-spec.md` sections 18 and 19; the pack and host commands are in `factory/input/04-stack-profile.md`. Search this file for the heading you need.

Sections: 1. Public surface · 2. Versioning and deprecation · 3. Side effects and state · 4. Dependencies · 5. Telemetry and privacy · 6. Packaging · 7. Host compatibility (plugins) · 8. Host permissions and settings (plugins) · 9. Review checklist

## 1. Public surface

- Export only what the spec lists. Everything else is internal: unexported, in an `internal` folder, or marked private as the language allows.
- Keep the surface small and consistent: one way to do each thing, names in the language's conventions, options objects instead of long parameter lists.
- Public functions validate their inputs and fail with the documented error model (typed errors, result types or error codes), never with a crash deep inside.
- Every public item has a doc comment with an example; the README shows the main use cases.
- Types or type declarations ship with the package where the ecosystem expects them.

## 2. Versioning and deprecation

- Semantic versioning: a major version for any breaking change, a minor version for additions, a patch for fixes.
- Breaking changes include: removing or renaming an export, changing a signature, a default, an error type, a thrown condition, the supported runtime range, or (for plugins) a setting, a command ID or the minimum host version.
- Deprecate before removing: mark the item deprecated in code and docs, warn once at runtime where the ecosystem does, keep it for at least one minor version, and say what replaces it.
- Every release has a CHANGELOG entry that flags breaking changes and deprecations.

## 3. Side effects and state

- No side effects on import or load: no network calls, file writes, environment changes, patching of globals or background timers until the caller or host asks.
- No global mutable state: configuration is passed in or held by an instance the caller creates. Two users of the library in one process must not affect each other.
- Never call `exit`, change the working directory, or install signal handlers in a library; return errors to the caller.
- Plugins do their work only after their activation events, and release everything (listeners, timers, processes) on deactivation.

## 4. Dependencies

- Minimal dependencies (`factory/core/guidelines/dependencies.md`): every runtime dependency becomes the user's dependency too.
- Use version ranges that allow compatible updates, and peer dependencies for frameworks the host or the caller already provides.
- No install scripts (`postinstall` and similar) unless the spec requires them.

## 5. Telemetry and privacy

- No telemetry, analytics or "phone home" calls without an explicit opt-in, documented in the README; plugins also respect the host's telemetry setting.
- Never log or send the caller's data, file contents or secrets.

## 6. Packaging

- The package contains only what users need: built code, types, license, README and CHANGELOG. Use an allowlist (for example `files` in `package.json`, include rules in `pyproject.toml`, `.vscodeignore`), never tests, fixtures, `.env` files or `factory/`.
- Metadata is complete: name, version, description, license, repository, supported runtime or host range, entry points.
- The stack profile's pack command builds the local package; check its contents list before every release.
- Build artifacts are reproducible from the tagged commit.

## 7. Host compatibility (plugins)

- Declare the supported host range in the manifest (for example `engines.vscode`), matching the spec, and use only host APIs available in the lowest supported version.
- Check host API availability before using optional or newer APIs, and degrade gracefully.
- Test in the host's test harness or development mode, as the stack profile says.

## 8. Host permissions and settings (plugins)

- Request the least privilege the stories need: only the permissions, activation events, host permissions and content scripts the spec lists.
- Settings have a namespace (`myPlugin.maxResults`), a type, a default and a description in the manifest; renaming one is a breaking change.
- Store secrets only in the host's secret storage API, never in settings or plain files.
- Webviews and panels follow the `gui` rules of `factory/core/guidelines/ui-ux-and-accessibility.md`, with a restrictive content security policy and no remote scripts.

## 9. Review checklist

- [ ] Only the exports, commands, settings and extension points in the spec are public; each has docs and an example.
- [ ] Inputs validated; errors follow the documented error model.
- [ ] No side effects on import or load; no global mutable state; no `exit` in library code.
- [ ] Dependencies minimal; peer dependencies for provided frameworks; no unneeded install scripts.
- [ ] No telemetry without opt-in; no caller data logged or sent.
- [ ] Package contents limited by an allowlist; metadata complete.
- [ ] Plugins: host range declared and respected; least-privilege permissions; secrets in the host's secret storage; resources released on deactivation.
- [ ] No breaking change to the public API, settings or host range unless the item says it is intended and the version policy allows it; CHANGELOG updated.
