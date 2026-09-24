# Git

How the factory uses git in the product repository. Branch names and merge settings come from the `git` block of `factory/config.yaml`; the task message gives each role its branch. Search this file for the heading you need.

Sections: 1. Branch model · 2. Conventional Commits · 3. Commits on item branches · 4. Staging · 5. Merges into the integration branch · 6. Co-author trailer · 7. Rebase rules · 8. What never goes into git · 9. Tags · 10. Checkpoint pull requests · 11. Checklist

## 1. Branch model

| Branch | Config key | Purpose | Who writes |
|---|---|---|---|
| Base (default `main`) | `git.base_branch` | Stable; receives the integration branch at each checkpoint | Orchestrator (checkpoint merges only) |
| Integration (default `develop`) | `git.integration_branch` | Every finished item is merged here | Orchestrator (item merges only) |
| Item branches | `git.task_branch_pattern`, `git.bug_branch_pattern` | One per task or bug: `task/T-012-login-with-email`, `bug/B-003-safari-login-button` | Role agents (TEST, DEV) |
| Checkpoint docs | — | `docs/cp-<n>` for the Tech Writer's checkpoint docs | Tech Writer |

- Item branches start from the latest integration branch and are deleted after merging when `git.delete_merged_branches` is true.
- `{slug}` is short English kebab-case (at most 5 words), even when the title is in another language.

## 2. Conventional Commits

Format: `<type>(<scope>): <description>`, in English, imperative mood, lowercase description, no final period, 72 characters or fewer in the subject.

| Type | Use |
|---|---|
| `feat` | A new user-visible capability |
| `fix` | A bug fix |
| `test` | Adding or correcting tests |
| `refactor` | Code change without behavior change |
| `docs` | Documentation only |
| `build` | Build system, dependencies, packaging |
| `ci` | CI configuration |
| `perf` | Performance improvement |
| `chore` | Maintenance that fits nothing else |

- Scope: the main `Touches` area (`auth`, `api-users`, `ui-login`); omit it when the change is global.
- Body (optional): what and why, wrapped at 72 characters. Footer: `BREAKING CHANGE: <description>` when applicable.

Examples:

```text
feat(auth): add login with email and password
fix(orders): refund payment when an order is cancelled
test(auth): cover lockout after failed logins
refactor(billing): extract tax calculation into a pure function
build: pin node to 22 LTS
```

## 3. Commits on item branches

- Commit early and often: after each meaningful step that builds, so an interrupted session loses little. Work-in-progress commits are fine on item branches; the squash merge produces the final commit.
- Every commit message still follows Conventional Commits.
- Never commit on the integration or base branch as a role agent.

## 4. Staging

- Stage files by explicit path: `git add src/auth/login.ts tests/auth/login.test.ts`.
- Never use `git add -A`, `git add .`, `git add -u` or `git commit -a`: they can pick up factory files, local notes or secrets.
- Before committing, check `git status --porcelain` and `git diff --cached --stat`: only the files you meant to change are staged.

## 5. Merges into the integration branch

Done by the Orchestrator (`factory/core/workflow/delivery.md` section 5):

- `git.merge_strategy: squash` (default): one commit per item. Subject: a Conventional Commit ending with the item ID, for example `feat(auth): login with email and password (T-012)` or `fix(ui-login): make login button work on Safari (B-003)`.
- `git.merge_strategy: merge`: `--no-ff` merge with the same subject style, keeping the branch history.
- The body lists the acceptance criteria delivered and the gate verdicts.

## 6. Co-author trailer

- Add a `Co-authored-by: <agent name> <address>` trailer naming the AI agent **only** when `git.ai_coauthor` is true.
- The rule applies to every commit and every pull request body the factory writes, including role agents' commits.
- When it is false (the default), no commit, pull request title or body mentions the AI tool.

## 7. Rebase rules

- Update an item branch with `git rebase <integration>` before merging, and in parallel mode after other items merge.
- Rebase only branches that no one else uses: item branches are local to the factory.
- On conflicts, resolve keeping both intents or abort (`git rebase --abort`) and hand the item back to DEV.
- Never force-push the base or integration branch. Never rewrite history of a branch that was pushed and shared, except item branches the factory owns.
- Never rewrite history to remove a leaked secret without the user's decision; report it instead.

## 8. What never goes into git

- Anything under `factory/`.
- The factory agent files (`.claude/agents/factory-*.md`, `.codex/agents/factory-*.toml`).
- Any file that holds a WholeTeam block: `CLAUDE.md`, `AGENTS.md`, `CLAUDE.local.md`, `AGENTS.override.md` created or edited by the installer.
- `.env` and any file with real secrets; local databases and uploads; build output and dependency folders (per the stack's ignore rules).

The one exception is `.gitignore` with the factory block, committed at kickoff.

## 9. Tags

- When `git.tag_checkpoints` is true, tag the base branch after each checkpoint merge: `git tag -a cp-<n> -m "Checkpoint CP-<n>"`.
- Push tags only in pull request mode, together with the checkpoint flow.
- Never move or delete an existing tag.

## 10. Checkpoint pull requests

- Title (English): `Checkpoint CP-<n>: <title>`.
- Body from `factory/core/templates/pr-body.md`: summary, items included, how to validate, test results, audit summary.
- Merged with a merge commit (not squash), so the base branch keeps the integration history.

## 11. Checklist

- [ ] Work is on the item branch named in the task message.
- [ ] Commit messages follow Conventional Commits, in English.
- [ ] Files were staged by explicit path; nothing under `factory/` or with a factory block is staged.
- [ ] No secrets, `.env` files or build output in the diff.
- [ ] No co-author trailer unless `git.ai_coauthor` is true.
- [ ] No force-push to shared branches.
