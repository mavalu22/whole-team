# Changing WholeTeam

- `template/` holds the files the installers copy into projects. Everything else, including `scripts/`, `.github/` and these instruction files, maintains WholeTeam and is never installed.
- To change a role, edit `template/factory/core/roles/<slug>.md`, then apply the same change to the embedded role text in `template/root/.claude/agents/factory-<slug>.md` and `template/root/.codex/agents/factory-<slug>.toml`. Keep the three copies hand-maintained. Do not make agents read the role file at runtime. A preamble change goes into all 26 agent files. Adding or removing a role means its role file and both agents; the Orchestrator is the main session and has no agent files.
- Keep `template/factory/config.yaml` and `template/factory/core/config.defaults.yaml` byte-identical.
- Before every commit, run `python3 scripts/check.py` and fix every problem it reports. CI runs it on every pull request to main.
- Make atomic Conventional Commits in English. Add a `CHANGELOG.md` line under `## [Unreleased]` for each change.
- Never add AI attribution to commits or pull requests: no `Co-authored-by:` trailer, no "Generated with ..." line and no other tool attribution.
- **Releases:** every release commit `chore(release): X.Y.Z` on `main` gets an annotated tag `vX.Y.Z` and a GitHub release whose notes are that version's `CHANGELOG.md` section. Keep tag messages and release notes free of attribution.
