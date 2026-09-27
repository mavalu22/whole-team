# CLI design

Rules for command-line programs. The command tree, flags, exit codes and output formats of this product are in `factory/input/05-design-spec.md` section 16; the run command is in `factory/input/04-stack-profile.md`. Search this file for the heading you need.

Sections: 1. Command tree · 2. Arguments and flags · 3. Help · 4. Exit codes · 5. Output · 6. Input and prompts · 7. Configuration · 8. Errors · 9. Compatibility · 10. Review checklist

## 1. Command tree

- Every command and subcommand is in the spec, mapped to a user story. A new command is a spec change first.
- Name commands with verbs or `noun verb` pairs, consistently (`app user add`, not `app add-user` next to `app project create`).
- Keep one parser library, as the stack profile says; no hand-rolled parsing.

## 2. Arguments and flags

- Long flags in kebab-case (`--dry-run`), short aliases only for frequent flags (`-v`, `-o`, `-f`, `-q`).
- Standard meanings: `--help`/`-h`, `--version`, `--verbose`/`-v`, `--quiet`/`-q`, `--output`/`-o`, `--force`/`-f`, `--yes`/`-y`, `--no-color`.
- Flags for options, positional arguments only for the main object (`app deploy <target>`); at most two positionals.
- Accept `--` to end options. Validate every argument and report all errors of one call together.
- Destructive commands need confirmation, or `--yes` when not interactive; offer `--dry-run` where it helps.

## 3. Help

- `--help` works on every command and subcommand, prints to stdout and exits 0.
- Help shows usage, a one-line description, every flag with its default, and at least one example.
- A wrong or missing argument prints a short usage line to stderr and suggests `--help`; a mistyped command suggests the closest one.
- `--version` prints the version only.

## 4. Exit codes

- `0` on success; non-zero on any failure. Never exit 0 after an error.
- Use a small, documented set: `1` general failure, `2` usage error; further codes only when scripts need to tell failures apart, listed in the spec.
- The exit code reflects the whole command: a partial failure in a batch is non-zero unless the spec says otherwise.

## 5. Output

- Results go to stdout; progress, warnings and errors go to stderr.
- Human-readable output by default; machine-readable output with a flag (`--json`, or `--output json`). JSON output is stable: fields are only added, never renamed or removed, without a major version.
- JSON output contains no color codes, progress or log lines, and is valid even when the command fails (an error object, plus the non-zero exit code).
- Color and animation only when stdout is a TTY, and never when `NO_COLOR` is set or `--no-color` is passed.
- `--quiet` prints only what scripts need; `--verbose` adds detail, never secrets.

## 6. Input and prompts

- Read from stdin when the spec says so, and accept `-` as a file name for stdin or stdout.
- Never prompt when stdin is not a TTY: fail with a clear message naming the flag that supplies the value.
- Prompts have a default and can be answered by a flag; secrets are read without echo.
- Handle `Ctrl+C` (SIGINT): stop cleanly, remove temporary files, exit non-zero (`130` by convention).

## 7. Configuration

- Precedence, highest first: flags, environment variables, project config file, user config file, defaults. Document it in help.
- Environment variables use one prefix (`APP_TOKEN`); config files live in the platform's standard place (XDG on Linux, the equivalents on macOS and Windows).
- Credentials come from environment variables, a config file with owner-only permissions, or the OS keychain; never from a flag value alone (flags appear in shell history and process lists).

## 8. Errors

- Error messages go to stderr, say what failed and what to do next, and use the product's terms: `config file not found: ./app.toml (run "app init" to create one)`.
- No stack traces by default; show them with `--verbose` or a debug variable.
- Never print secrets, full tokens or unnecessary personal data.

## 9. Compatibility

- Commands, flags, exit codes and JSON fields are a published interface once released. Removing or renaming one is a breaking change: deprecate first (a warning on stderr for at least one minor version), then remove in a major version.
- Work on the shells and operating systems in `factory/input/03-platform-architecture.md` section 1: paths with spaces, Windows path separators and line endings where Windows is supported.

## 10. Review checklist

- [ ] Commands and flags match the spec; new ones were added to the spec first.
- [ ] `--help` works on every command, with usage, flags, defaults and an example.
- [ ] Exit code 0 on success and non-zero on every failure path.
- [ ] Results on stdout; errors, warnings and progress on stderr.
- [ ] JSON output stays valid and stable; no color or logs in it.
- [ ] No prompts when stdin is not a TTY; destructive actions confirm or need `--yes`.
- [ ] Color only on a TTY; `NO_COLOR` and `--no-color` respected.
- [ ] Configuration precedence as in section 7; no secrets taken from flags alone or printed.
- [ ] Errors are actionable, without stack traces by default.
- [ ] No breaking change to commands, flags, exit codes or JSON fields unless the item says it is intended and the version policy allows it.
