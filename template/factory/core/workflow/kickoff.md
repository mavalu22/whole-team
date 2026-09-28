# Kickoff

Read when `phase: kickoff`. Kickoff runs once, on the first `Let's code`. Resume at the first step whose result is not yet recorded: each step says what it writes.

Sections: 1. Welcome · 2. Language · 3. Process · 4. Git checks · 5. Cost tip · 6. Finish

## 1. Welcome

Greet the user in `config.language` and explain the factory in 3-4 lines:

- You will define the product together in Discovery (8 short steps, each approved by them), then the factory builds it task by task, with the gates their chosen process includes, stopping at checkpoints for them to validate.
- The five commands: `Let's code` (start or resume), `Support: <description>` (report a problem or ask how something works), `Status`, `Change: <request>`, `Audit`.
- Factory files live in `factory/`, which git ignores: they exist only on this machine, so back the folder up.
- They can drop screenshots and files into `factory/attachments/` and cite them in any request.

## 2. Language

1. Show `config.language` and ask whether the user wants another language for the conversation and the input documents.
2. Explain in one line that the input documents keep the language chosen now, even if the conversation language changes later.
3. If the user picks another language, replace the `language:` line in `factory/config.yaml` with the BCP 47 tag (for example `language: pt-BR`) and continue in that language.
4. Ask in the same message whether the product documentation (README, API docs, CHANGELOG) should use the same language; write `product_docs_language` if it differs from the current value. Recommend English for products meant for a wide audience.

## 3. Process

1. Show the four process presets from `factory/core/modes.md` (section 11), translated to `config.language`. Recommend one: `standard` when nothing about the product is known yet (say it can change at any time), or `mvp`/`complete` when the user already described the product in this conversation and one preset clearly fits (a throwaway tool, or something that will hold users' data or payments).
2. Ask for the preset: `mvp`, `standard`, `complete` or `custom`.
3. **`custom`:** walk through `pipeline.stages`, `pipeline.ux_check`, `pipeline.task_size` and `pipeline.critical_full_pipeline` in turn, each with its description (`factory/core/modes.md` sections 12-14 and the safety nets of section 11 for `critical_full_pipeline`), recommending the `standard` preset's values as a starting point. Enforce the safety nets: `stages` must include `review` or `qa`; `ux_check: qa` requires `qa` in `stages`; `ux_check: review` requires `review` in `stages`. Refuse a choice that fails a safety net, explain why in one line, and ask again.
4. Write `pipeline.preset` and the keys the preset (or the custom answers) sets: `pipeline.stages`, `pipeline.ux_check`, `pipeline.task_size`, `pipeline.critical_full_pipeline`, `testing.level`, `security.audit_on_checkpoint`, `discovery.quick_steps`. `testing.level` is a recommended default here; Discovery step 7 still asks the user to confirm or change it.
5. Append a log line: `"<ISO time> process preset set: <preset>"`.
6. `ongoing` projects choose the preset here too, at the same point in kickoff, before the git checks.

## 4. Git checks

Run each check in order. In `ongoing` projects (`project.type`), ask before any git change; in `new` projects, tell the user what you did.

### 4.1 Base branch

1. Detect the default branch: the current branch (`git symbolic-ref --short HEAD`, which also works in a repository without commits), or `main` or `master` if one exists and the current branch is a feature branch.
2. If it differs from `git.base_branch`, confirm it with the user, then replace the `base_branch:` line in `factory/config.yaml`.
3. If the checked-out branch is not the base branch, ask the user whether you may switch to it (`git switch <base>`). Kickoff commits happen on the base branch.

### 4.2 Empty repository

1. If `git rev-parse --verify HEAD` fails, the repository has no commits. Tell the user.
2. Create the initial commit on the base branch with `.gitignore` only: `git add .gitignore && git commit -m "chore: initial commit"`.
3. Step 4.3 is then already satisfied.

### 4.3 Uncommitted `.gitignore`

The installer added a marked block (`# >>> whole-team >>>` ... `# <<< whole-team <<<`) to `.gitignore`. A modified tracked `.gitignore` would block every rebase, so it must be committed before delivery.

1. Check `git status --porcelain -- .gitignore`. If it prints nothing, skip this step.
2. Check `git diff -- .gitignore` (or the whole file if it is untracked). If it contains changes outside the factory block, show them to the user and ask whether to include them in the commit; if not, ask them to commit or revert those lines first.
3. `new` projects: tell the user, then commit on the base branch: `git add .gitignore && git commit -m "chore: ignore WholeTeam files"`.
4. `ongoing` projects: ask first, explaining that the commit only adds ignore rules for factory files. If the user accepts, commit as in 4.3.3.
5. If the user declines:
   1. find the local-only exclude file: `git rev-parse --git-path info/exclude` (usually `.git/info/exclude`); create it if missing;
   2. add the same block to it, with the same markers, replacing any existing block there;
   3. remove the block from `.gitignore`; if `factory/.install-manifest` says `created .gitignore` and the file is now empty, delete it;
   4. in `factory/.install-manifest`, replace the `.gitignore` line with `block <exclude path>` (for example `block .git/info/exclude`);
   5. check that `git status --porcelain --untracked-files=no` no longer lists `.gitignore`, and that `git check-ignore -q factory/state.yaml` still succeeds.

### 4.4 Integration branch

1. If the branch named by `git.integration_branch` (default `develop`) does not exist, create it from the base branch: `git branch <integration> <base>`.
2. `new` projects: create it and tell the user. `ongoing` projects: ask first; if the user prefers another existing branch, write its name to `integration_branch:`.
3. Do not check it out yet; delivery does that.

### 4.5 PR tooling

Only when `git.checkpoint_merge` is `pr`:

1. Check for a remote: `git remote`. Pick `origin` when it exists, otherwise the only remote.
2. Choose the CLI from the remote URL: `gh` for GitHub, `glab` for GitLab. Check it with `gh auth status` or `glab auth status`.
3. If the remote or the authenticated CLI is missing, tell the user in one line that checkpoints will merge locally until it is available, and how to fix it (`gh auth login` or `glab auth login`). Do not change the config.

## 5. Cost tip

Tell the user in two lines: the main session should run on a medium-tier model (Claude Code: `sonnet`; Codex: `gpt-6-sol` at medium effort), because heavy reasoning is delegated to high-tier role agents and the main session mostly coordinates. Mention they can switch now (`/model` in either tool) without losing anything, since all state is in files.

## 6. Finish

1. In `factory/state.yaml`, set:
   - `kickoff.completed_at` to the current UTC time;
   - `input_language` to the current `config.language` (quoted);
   - `phase: discovery`;
   - append a log line: `"<ISO time> kickoff done; base=<base>, integration=<integration>, language=<tag>"`.
2. Start Discovery:
   - `new` projects: step 1 in `factory/core/workflow/discovery.md`.
   - `ongoing` projects: reverse Discovery in `factory/core/workflow/ongoing-projects.md`.
