# Backlog

Read in Discovery step 8, for change requests, for audits that add tasks, and whenever you edit `factory/tasks.md` or `factory/tasks-graph.md`. The Architect reads sections 1 and 3 to generate; the Backlog Validator reads sections 1 and 4 to validate. Each section stands alone: search this file by its exact path for the heading you need.

Sections: 1. Format of tasks.md · 2. Graph · 3. Generation rules · 4. Validation · 5. Writing the backlog · 6. Changes after approval

## 1. Format of tasks.md

### 1.1 Top of file

```markdown
# Tasks

<!-- factory:summary:start -->
- **Updated:** 2026-01-10
- **Statuses:** TODO 21 · IN_PROGRESS 1 · QA 1 · DONE 9 · CANCELLED 1
- **Current wave:** 3 of 7
- **Next checkpoint:** CP-2 · Accounts and profiles (4 tasks left)
- **In flight:** T-012 (QA, slot 1), T-014 (DEV, slot 2)
<!-- factory:summary:end -->
```

The Orchestrator maintains the summary after every status change. `Statuses` lists only statuses with a count above zero, in the order of the status list in 1.4. Use `—` for empty values.

### 1.2 Body

- `## Wave N` headings, in increasing order.
- Task blocks in ID order under their wave.
- Checkpoint lines between waves, each on its own line. The file ends with a checkpoint line.

### 1.3 Task block

Field labels are exact and always English. Free text is in `state.input_language`.

```markdown
### T-012 · Login with email and password
- **Status:** TODO
- **Type:** feature
- **Wave:** 3
- **Critical:** yes
- **Security review:** required
- **Depends on:** T-008, T-010
- **Touches:** auth, api/users, ui/login
- **Refs:** 01-product-vision.md US-03; 02-stack.md §5; ADR-002
- **Branch:** —
- **Rejections:** 0
- **Acceptance criteria:**
  - [ ] AC1: ...
- **Notes:** —
- **History:**
  - 2026-01-01 · created
```

- **Heading:** `### T-NNN · <title>`, with a three-digit number (`T-001`; `T-1000` after `T-999`).
- **Critical:** `yes` or `no`. **Security review:** `light` or `required`.
- **Depends on:** comma-separated task IDs, or `—`.
- **Branch:** `—` until the item starts; then the branch name.
- **Acceptance criteria:** 1-7 items, `  - [ ] AC<n>: <testable statement>`. The Orchestrator checks a box (`[x]`) only when a QA report gives evidence for it.
- **History:** one line per event, `  - YYYY-MM-DD · <event>`, newest last.

### 1.4 Values

- **Types:** `feature`, `infra`, `test`, `docs`, `refactor`, `security`.
- **Statuses:** `TODO`, `TESTING`, `IN_PROGRESS`, `IN_REVIEW`, `QA`, `SEC`, `AWAITING_APPROVAL`, `DONE`, `REVIEW_REJECTED`, `QA_REJECTED`, `SEC_REJECTED`, `BLOCKED`, `CANCELLED`.
- **Touches:** a short, stable vocabulary of areas (`auth`, `db`, `data`, `migrations`, `api/<resource>`, `ui/<screen>`, `infra`, `ci`, `docs`). The vocabulary lives in `factory/input/04-stack-profile.md`; reuse it, and add a new area there before using it.
- **Refs:** stable IDs (`US-03`, `ADR-002`) or numbered sections of input files (`02-stack.md §5`), never heading text, because headings may be translated. Separate entries with `;`.

### 1.5 Checkpoint line

```text
#CHECKPOINT CP-1 · Foundations running locally
```

`CP-<n>` numbers increase in file order. The title says what the user can run and validate at that point.

## 2. Graph

`factory/tasks-graph.md` holds a Mermaid `flowchart LR` with four parts, in this order:

1. `classDef` lines for `todo`, `active`, `done`, `blocked`, `cancelled` and `checkpoint` (already in the starting file; keep them).
2. Between `%% factory:nodes:start` and `%% factory:nodes:end`: one subgraph per wave with its task nodes, checkpoint nodes, and edges.
3. Between `%% factory:status:start` and `%% factory:status:end`: one `class <node> <class>` line per task.

Node and edge syntax:

```text
  subgraph W3["Wave 3"]
    T012["T-012 · Login with email and password"]
  end
  CP1{{"CP-1 · Foundations running locally"}}:::checkpoint
  T008 --> T012
  W2 --> CP1 --> W3
```

- Node IDs drop the hyphen: `T-012` → `T012`. Labels keep the ID and title; escape `"` in titles as `#quot;`.
- Draw every dependency edge. Draw each checkpoint between the subgraphs of the waves it separates.
- Status to class: `TODO` → `todo`; `TESTING`, `IN_PROGRESS`, `IN_REVIEW`, `QA`, `SEC`, `AWAITING_APPROVAL`, `REVIEW_REJECTED`, `QA_REJECTED`, `SEC_REJECTED` → `active`; `DONE` → `done`; `BLOCKED` → `blocked`; `CANCELLED` → `cancelled`.
- **More than 40 tasks:** write one Mermaid block per checkpoint section (the tasks between two checkpoint lines), each under a `## CP-<n> · <title>` heading, each with its own nodes and status markers. A dependency on a task of an earlier section is drawn as a node with the ID only, and that node also gets a `class` line.
- **Editing:** when a status changes, edit only that task's `class` line (search for `class T012 `; with split diagrams, edit every match). Regenerate nodes and edges only when the backlog changes.

## 3. Generation rules

The Architect follows these rules and writes the result to `factory/output/drafts/backlog-draft.md`, in the body format of section 1 (waves, task blocks with final IDs, checkpoint lines), without the summary block.

1. **Decompose by module.** Derive the modules from `factory/input/03-platform-architecture.md`.
2. **Foundation first.** Create the foundation tasks, in this order when applicable:
   1. project scaffold per the stack profile, including tooling exclusions for `factory/`;
   2. CI pipeline;
   3. local run with one command, plus `.env.example` and slot isolation;
   4. data model and initial migrations;
   5. API contracts and shared types (for example OpenAPI);
   6. design system base (tokens → theme);
   7. authentication skeleton, if needed.
3. **Vertical slices.** Features are vertical slices that are testable end to end ("Login works end to end", not "login screen" plus "login endpoint").
4. **Session-sized tasks.** Every task fits comfortably in one agent session: one slice, at most about 7 acceptance criteria, and roughly 8 production files or fewer. Split larger work.
5. **Real dependencies only.** Declare a dependency only when a task needs code, a contract or data produced by another task. Never create cycles.
6. **Compute waves.** A task's wave is 1 + the highest wave among its dependencies (wave 1 if it has none). Then, while two tasks in the same wave share a `Touches` area, move the one that unblocks fewer tasks to the next wave, and recompute the waves of the tasks that depend on it.
7. **Number last.** Draft tasks with temporary keys. When the waves are final, assign IDs (`T-001`, `T-002`, ...) in wave order, foundation tasks first within a wave, and rewrite every `Depends on` with the final IDs. Every dependency then appears earlier in the file, and file order, ID order and wave order agree.
8. **Mark critical tasks.** `Critical: yes` for auth, payments, personal data, core business rules and data integrity; `no` otherwise.
9. **Mark security reviews.** `Security review: required` for authn/authz, payments, personal data, file upload, parsing of untrusted input, crypto, secrets, permissions and public endpoints. Everything else gets `config.security.review_default`.
10. **Place checkpoints.** Propose checkpoints at wave boundaries, at points where the user can run and validate something meaningful. At least one is required, and the file always ends with one.
11. **Reference inputs.** Every task has `Refs` to the user stories, ADRs or input sections it implements.
12. **Initial fields.** `Status: TODO`, `Branch: —`, `Rejections: 0`, `Notes: —` (or a short note), one history line `<date> · created`.
13. **Later additions.** Tasks added after approval (change requests, audits) take the next free IDs (`delivery.next_task_id`). By default they go after the last task, followed by a new checkpoint (`delivery.next_checkpoint_id`). If the user wants them sooner, insert them before the next pending checkpoint instead; their IDs are then higher than those of some tasks after them, which is allowed. In both cases, recompute the waves from the insertion point to the end of the file so the validation rules hold.

## 4. Validation

The Backlog Validator checks `factory/tasks.md` or the draft against this list and reports every violation with the task ID or line. It never rewrites the backlog.

- [ ] All required fields are present, in the order of section 1.3, with the exact labels.
- [ ] Every value is one of the allowed values (section 1.4); `Critical` is `yes` or `no`; `Security review` is `light` or `required`.
- [ ] IDs are unique and never reused; `CANCELLED` tasks keep theirs. In the initial backlog, IDs are sequential and in file order.
- [ ] Every dependency exists and appears earlier in the file.
- [ ] Every task's `Wave` equals the `## Wave N` heading it sits under, and is higher than the waves of all its dependencies.
- [ ] Waves never decrease in file order, and no two tasks in one wave share a `Touches` area.
- [ ] Each checkpoint line sits between two different waves, checkpoint numbers increase in file order, and the last line of the task list is a checkpoint.
- [ ] Every task has 1-7 testable acceptance criteria (observable behavior, no vague words such as "fast" or "user-friendly" without a measure).
- [ ] Every task has at least one `Refs` entry in the allowed format (stable ID or `<file> §<n>`).
- [ ] `Critical` and `Security review` are consistent with rules 8 and 9 of section 3, judged from the title, criteria and `Touches`.
- [ ] Foundation tasks exist for the applicable items of rule 2, and the first scaffold task (new projects) includes the tooling exclusions for `factory/`.

## 5. Writing the backlog

After approval of the draft (Discovery step 8, change requests, audits), the Orchestrator:

1. Writes the body into `factory/tasks.md` below the summary block, or applies the change as small edits for later additions.
2. Updates the summary block.
3. Regenerates the nodes and edges of `factory/tasks-graph.md` and the status block.
4. Updates `delivery.next_task_id` and `delivery.next_checkpoint_id` in `factory/state.yaml`.

## 6. Changes after approval

- Never delete a task: set `CANCELLED`, keep its ID, and add a history line with the reason.
- Tasks that depended on a cancelled task: drop the dependency or cancel them too, as the user decides; then recompute waves.
- Unstarted tasks may be edited (title, criteria, dependencies, `Touches`); add a history line `<date> · changed: <what> (<reason>)`.
- Tasks that are `DONE` are never edited; new tasks modify their result.
- After any structural change, run the Backlog Validator on `factory/tasks.md` and regenerate the graph.
