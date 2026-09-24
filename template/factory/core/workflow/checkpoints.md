# Checkpoints

Read when a checkpoint's conditions are met, or when a checkpoint approval is pending. A checkpoint merges the integration branch (`git.integration_branch`) into the base branch (`git.base_branch`) after checks the user can trust.

Sections: 1. When a checkpoint is reached · 2. Procedure · 3. Merge · 4. After approval · 5. Bug-fix checkpoints

## 1. When a checkpoint is reached

A checkpoint `CP-<n>` in `factory/tasks.md` is reached when:

- every task before its line is `DONE` or `CANCELLED`;
- no blocking bug is open (`factory/core/workflow/bugs-and-support.md` section 3);
- in parallel mode, no item before it is in flight.

Record the start in `factory/state.yaml` with a log line (`"<ISO time> CP-<n> started"`) and run the procedure. Each step records its result as a log line, so a resumed session continues at the first step without one.

## 2. Procedure

1. **Audit.** If `security.audit_on_checkpoint` is true, delegate to `security` with stage `AUDIT` at `security.audit_tier`: audit everything merged since the last checkpoint (the diff `git diff <last checkpoint tag or base>...<integration>`). Findings become bugs with source `checkpoint-audit` (`factory/core/workflow/bugs-and-support.md` section 1). Blocking ones are fixed through the delivery pipeline before continuing; then restart this procedure at step 2.
2. **Verify.** On the integration branch, run the full test suite, lint, type-check and build with the stack profile's quiet commands. With `testing.level: full`, also check `testing.coverage_target`. Each failure becomes a bug with source `checkpoint-audit` (a broken build or failing suite is at least P1), fixed before continuing.
3. **Docs.** Delegate to `tech-writer` with stage `DOCS`: update the product `README.md` (what it is, how to run, how to test), the API docs and `CHANGELOG.md` (an entry for this checkpoint), in `config.product_docs_language`. The Tech Writer commits on a short branch `docs/cp-<n>`, which you merge like an item (section 5 of `factory/core/workflow/delivery.md`, without TEST, QA or SEC; the Tech Lead reviews).
4. **Hosting guide.** If this is the checkpoint set by `deploy.hosting_guide` (`first_checkpoint`: the first one; `final_checkpoint`: the last line of `factory/tasks.md`) and `delivery.hosting_guide_written` is false, run `factory/core/workflow/hosting-guide.md`. Show the user a summary of at most 5 lines.
5. **Report.** Write `factory/output/checkpoints/CP-<n>.md` from `factory/core/templates/checkpoint-report.md`: tasks and bugs included, how to run locally, a validation checklist derived from the acceptance criteria, known issues (including accepted findings from task `Notes`), audit summary, test results, and what comes next. Write it in `config.language`.
6. **Merge preparation.** Section 3.
7. **Approval.**
   - `per_task` or `per_checkpoint`: stop. Add an entry to `delivery.pending_approvals` (kind `checkpoint`). Show the short report (at most 15 lines) and the validation checklist. Tell the user to validate, to report problems with `Support: <description>` (the pull request updates automatically as bugs are fixed on the integration branch), and to reply **approve** to merge.
   - Before waiting, make sure every decision from the conversation is recorded in the files, then tell the user they can start a fresh session (`/clear` in Claude Code, or a new chat in Codex) before continuing; `Let's code` resumes from the files.
   - `none`: continue without stopping.

## 3. Merge

- **`git.checkpoint_merge: pr`**, with a remote and an authenticated `gh` or `glab` (checked at kickoff step 3.5; check again with `gh auth status` or `glab auth status`):
  1. push both branches: `git push origin <base> <integration>`;
  2. write the body from `factory/core/templates/pr-body.md` to a temporary file outside the repository (for example in the system temp folder);
  3. open the pull request: `gh pr create --base <base> --head <integration> --title "<title>" --body-file <file>`, or `glab mr create --source-branch <integration> --target-branch <base> --title "<title>" --description "$(cat <file>)"`. The title is English: `Checkpoint CP-<n>: <English title>`;
  4. record the pull request URL in the pending approval entry and in the report.
- **Otherwise** (`local`, or no remote or CLI): prepare a local merge; nothing is pushed. Tell the user the merge will be local.

## 4. After approval

After the user replies **approve** (or immediately with `approval_mode: none`):

1. Merge:
   - pull request: `gh pr merge <number> --merge` (or `glab mr merge <number>`), then `git switch <base> && git pull --ff-only origin <base>`;
   - local: `git switch <base> && git merge --no-ff <integration> -m "chore(release): checkpoint CP-<n> <English title>"`.
2. If `git.tag_checkpoints` is true: `git tag -a cp-<n> -m "Checkpoint CP-<n>"`; in pull request mode, push the tag (`git push origin cp-<n>`).
3. Switch back to the integration branch: `git switch <integration>`.
4. In `factory/state.yaml`: set `delivery.last_checkpoint` (shape in `factory/core/workflow/state-and-resume.md` section 2), remove the pending approval entry, set `delivery.hosting_guide_written` if the guide was written, and append a log line.
5. If every task is now `DONE` or `CANCELLED`, set `phase: maintenance`.
6. Tell the user it is merged and what comes next, then continue with the next wave (`factory/core/workflow/delivery.md` section 1).

If the user reports problems instead, handle them with Support; blocking bugs are fixed on the integration branch before the approval is asked again with an updated report.

## 5. Bug-fix checkpoints

After the final checkpoint, and during `maintenance`, when a batch of bug fixes is done (no blocking bug open and no bug in flight), create a bug-fix checkpoint `CP-<n> · Bug fixes`, where `<n>` is `delivery.next_checkpoint_id` (then increment it). It is not written to `factory/tasks.md`; it exists in the report, the log and `delivery.last_checkpoint`. It follows the same procedure (sections 2 to 4), with the bugs fixed since the last checkpoint as its content.
