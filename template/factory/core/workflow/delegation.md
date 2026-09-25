# Delegation

Read before your first delegation in a session, and at startup step 3 (model sync). Each section stands alone.

Sections: 1. Invoking roles · 2. Fallback · 3. Task message · 4. Role report · 5. Model sync

## 1. Invoking roles

Every role except the Orchestrator has an agent file whose body embeds the role's instructions, the common rules and the report format. A role agent starts working from its task message without reading its role file.

### Claude Code

- Spawn the subagent `factory-<slug>` (for example `factory-qa`) with the Agent tool. The prompt is the task message (section 3).
- **Tier override** for one invocation: pass the Agent tool's `model` parameter with the model of the tier, from `models.claude_code.<tier>.model`. Use it for required security reviews (`security.required_review_tier`) and audits (`security.audit_tier`).
- **Parallel mode:** run agents in the background and wait for their completion notifications. Never guess or pre-fill results that haven't arrived.
- A subagent's `cd` does not persist between its commands; task messages for worktrees say so (`factory/core/workflow/delivery.md` section 10).

### Codex

- Spawn the custom agent `factory_<slug>` (for example `factory_qa`) by name, with the task message as its input.
- **Tier override:** request the model and reasoning effort explicitly in the spawn request, from `models.codex.<tier>`.
- Codex delegates to subagents when instructions request it: this workflow requests it for every stage of every item, every Discovery draft, and every audit.
- **Parallel mode:** spawn the agents of different items concurrently and wait for each result before acting on it.

### Which role for which work

| Work | Role | Stage value |
|---|---|---|
| Discovery drafts (stack, architecture, stack profile, backlog, reverse Discovery) | `architect` | `DISCOVERY` |
| Data model review in Discovery | `dba` | `DISCOVERY` |
| Stack profile conventions | `tech-lead` | `DISCOVERY` |
| Threat model | `security` | `DISCOVERY` |
| Prototypes, prototype inventory | `ux-ui-designer` | `DISCOVERY` |
| Backlog validation | `backlog-validator` | `VALIDATION` |
| Tests first, regression tests, test disputes | `test-engineer` | `TEST` |
| Implementation and rework | `developer` | `DEV` |
| Code, data and UI reviews | `tech-lead`, `dba`, `ux-ui-designer` | `REVIEW` |
| Acceptance verification | `qa` | `QA` |
| Security reviews | `security` | `SEC` |
| Audits | `security`, `tech-lead`, `qa` | `AUDIT` |
| Support reports | `support` | `SUPPORT` |
| Product README, API docs, CHANGELOG, `docs` tasks | `tech-writer` | `DOCS` |
| Hosting guide, foundation tooling tasks | `devops` | `DOCS` or `DEV` |
| Product questions from other roles | `product-owner` | `DISCOVERY` |

## 2. Fallback

Use the fallback when subagents are unavailable, disabled, or a delegation fails twice for the same stage (an error, no report, or a malformed report).

1. Perform the role yourself: read `factory/core/roles/<slug>.md` and follow it strictly, one stage at a time. Apply the role's boundaries as if you were the agent: for example, as QA you only verify, you don't fix.
2. For TEST, write and commit the tests before starting DEV, and never edit them during DEV.
3. Write the same report the agent would write (section 4) before recording the result, so the evidence rules still apply.
4. Tell the user once per session that tier routing is not active and why.
5. Try delegation again at the next stage; return to normal delegation as soon as it works.

## 3. Task message

Build each task message from `factory/core/templates/task-message.md`, in English, with the sections always in this order:

1. role;
2. item ID and title;
3. stage and stage goal;
4. absolute working directory;
5. branch and base branch;
6. slot and runtime environment (parallel mode; otherwise `—`);
7. files to read first (exact absolute paths; only what this stage needs, for example the stack profile and the relevant guideline sections);
8. the full item block from `factory/tasks.md` or `factory/bugs.md`;
9. relevant excerpts only: acceptance criteria, contracts, previous findings to fix, the Test Engineer's test paths, answers to earlier questions. Never whole documents; give paths and section numbers for anything else;
10. constraints: what not to touch, and extra limits for this stage;
11. role-specific report fields, if any (the common report format is already in the agent's instructions).

Rules:

- Keep the fixed order and headings: identical structure across runs makes messages easy to follow and cache-friendly.
- Give absolute paths to factory files: role agents in worktrees don't have `factory/` in their working directory.
- Say explicitly when pushing is allowed; otherwise agents never push.
- For rework, include only the open findings, each with `file:line` and the required fix.

## 4. Role report

Every role ends with the report of `factory/core/templates/role-report.md`:

```text
ROLE: <slug>
ITEM: <ID>
STAGE: <TEST|DEV|REVIEW|QA|SEC|AUDIT|SUPPORT|DISCOVERY|VALIDATION|DOCS>
VERDICT: <DONE|APPROVED|REJECTED|BLOCKED>
SUMMARY: <2-4 lines>
EVIDENCE:
- <command run> -> <result>
FINDINGS:
- [<severity>] <file:line> <problem> -> <required fix>
QUESTIONS: <only when BLOCKED>
ARTIFACTS: <commits, files written, test paths>
```

Handle the verdict as described in FACTORY.md section 6 ("Handling role reports"). For Discovery work without an item, `ITEM` is the step key (for example `s3_architecture`); for audits, the audit file name; for checkpoint docs, `CP-<n>`.

## 5. Model sync

Run at startup step 3 when the `models` block of `factory/config.yaml` differs from `state.agent_models_applied`, or when the file `factory/.models-sync-needed` exists. The installer writes that file whenever it replaces the agent files with the template's default models. Check it by its exact path, not with a search tool: `factory/` is git-ignored and search tools may skip it.

For each of the 13 roles in `models.role_tiers`:

1. Resolve its tier from `models.role_tiers.<slug>`.
2. **Claude Code file** `.claude/agents/factory-<slug>.md`: in the YAML front matter only, replace the `model:` line with `model: <models.claude_code.<tier>.model>`. If `models.claude_code.<tier>.effort` is not `null`, set `effort: <value>` (add the line right after `model:` if missing); if it is `null`, remove the `effort:` line.
3. **Codex file** `.codex/agents/factory-<slug>.toml`: replace the `model = "..."` line with `model = "<models.codex.<tier>.model>"`. If `models.codex.<tier>.effort` is not `null`, set `model_reasoning_effort = "<value>"` (add the line right after `model =` if missing); if it is `null`, remove the `model_reasoning_effort` line.
4. Leave everything else untouched: the body, the name, the description, the tools, `sandbox_mode`.

Then:

5. Store a copy of the whole `models` block in `state.agent_models_applied` (same keys and values, as a YAML mapping).
6. Append a log line: `"<ISO time> agent models synced"`.
7. Tell the user in one line that the agent files changed and that restarting Claude Code or Codex makes the new models take effect.
8. Delete `factory/.models-sync-needed` if it exists. This is the last step, so an interrupted sync simply runs again.

If an agent file is missing (for example deleted by hand), tell the user to run the WholeTeam installer in update mode. The update restores the file and marks the agents for a re-sync (`factory/.models-sync-needed`), so the next `Let's code` re-applies the models.
