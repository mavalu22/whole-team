# Delivery instruction consistency checks

These scenarios review the product instructions in [delivery.md](../template/factory/core/workflow/delivery.md#4-item-pipeline), not an installed factory or an executable scheduling engine. Check the selected order against role invocation, task constraints, history, state, resume and the Definition of Done. The expected orders omit disabled and inapplicable stages. Required tests must be committed before implementation, even when written within DEV.

## Initial delivery

In the first table, use the preset's stages, `critical_full_pipeline: true`, `Security review: light`, and `approval_mode: per_checkpoint` unless the row says otherwise. `critical` means the explicit `Critical: yes` flag, not bug priority. `none` in the owner column means no new automated tests; existing-suite execution remains governed by the testing policy.

| ID | Preset | Testing level | Item / override | Required test owner | Effective order |
|---|---|---|---|---|---|
| M01 | mvp | none | Ordinary feature | none | `DEV, REVIEW, MERGE` |
| M02 | mvp | none | Critical feature | Test Engineer | `TEST, DEV, REVIEW, QA, SEC, MERGE` |
| M03 | mvp | none | Ordinary feature, required security review | none | `DEV, REVIEW, SEC, MERGE` |
| M04 | mvp | none | Bug | none | `DEV, REVIEW, MERGE` |
| M05 | mvp | none | Documentation task | none | `DEV, REVIEW, MERGE` |
| S01 | standard | critical | Ordinary feature | none | `DEV, REVIEW, QA, MERGE` |
| S02 | standard | critical | Critical feature | Test Engineer | `TEST, DEV, REVIEW, QA, SEC, MERGE` |
| S03 | standard | critical | Bug | DEV (regression) | `DEV, REVIEW, QA, MERGE` |
| S04 | standard | critical | P0 bug, required security review | DEV (regression) | `DEV, REVIEW, QA, SEC, MERGE` |
| S05 | standard | critical | Documentation task | none | `DEV, REVIEW, QA, MERGE` |
| S06 | standard | critical | Critical documentation task | none | `DEV, REVIEW, QA, SEC, MERGE` |
| C01 | complete | critical | Ordinary feature | none | `DEV, REVIEW, QA, SEC, MERGE` |
| C02 | complete | critical | Critical feature | Test Engineer | `TEST, DEV, REVIEW, QA, SEC, MERGE` |
| C03 | complete | critical | Bug | Test Engineer (regression) | `TEST, DEV, REVIEW, QA, SEC, MERGE` |
| C04 | complete | full | Ordinary feature | Test Engineer | `TEST, DEV, REVIEW, QA, SEC, MERGE` |
| C05 | complete | none | Ordinary feature | none | `DEV, REVIEW, QA, SEC, MERGE` |
| C06 | complete | full | Documentation task | none | `DEV, REVIEW, QA, SEC, MERGE` |
| C07 | complete | none | Critical documentation task | none | `DEV, REVIEW, QA, SEC, MERGE` |
| C08 | complete | none | Bug | none | `DEV, REVIEW, QA, SEC, MERGE` |
| C09 | complete | critical | Ordinary feature, required security review | none | `DEV, REVIEW, QA, SEC, MERGE` |
| A01 | complete | critical | Bug, per-task approval | Test Engineer (regression) | `TEST, DEV, REVIEW, QA, SEC, APPROVAL, MERGE` |
| A02 | mvp | none | Ordinary feature, per-task approval | none | `DEV, REVIEW, APPROVAL, MERGE` |
| A03 | complete | full | Ordinary feature, approval mode none | Test Engineer | `TEST, DEV, REVIEW, QA, SEC, MERGE` |

For custom configurations, set `ux_check: none` and `approval_mode: per_checkpoint` unless noted. Each configuration retains REVIEW or QA. Stage-list order must not affect execution order.

| ID | Configured stages | Testing level | Item / override | Critical full pipeline | Required test owner | Effective order |
|---|---|---|---|---|---|---|
| X01 | qa | full | Ordinary feature | false | DEV | `DEV, QA, MERGE` |
| X02 | sec, test, qa | full | Ordinary feature, per-task approval | false | Test Engineer | `TEST, DEV, QA, SEC, APPROVAL, MERGE` |
| X03 | qa | none | Critical feature | false | none | `DEV, QA, MERGE` |
| X04 | test, qa | critical | Critical feature | false | Test Engineer | `TEST, DEV, QA, MERGE` |
| X05 | test, review | critical | Ordinary feature | false | none | `DEV, REVIEW, MERGE` |
| X06 | review | full | Critical feature | false | DEV | `DEV, REVIEW, MERGE` |
| X07 | review | full | Documentation task | false | none | `DEV, REVIEW, MERGE` |
| X08 | qa | none | Ordinary feature, required security review | false | none | `DEV, QA, SEC, MERGE` |
| X09 | review | none | Critical feature | true | Test Engineer | `TEST, DEV, REVIEW, QA, SEC, MERGE` |
| X10 | qa | none | Critical documentation task | true | none | `DEV, REVIEW, QA, SEC, MERGE` |

For all 33 cases, the start history contains the entire effective order in lower case, `in_flight.stage` begins at its first stage, and skipped stages never receive a status or completion verdict. QA and REVIEW check required tests only when those gates run; DEV and the Definition of Done still enforce the testing policy when either gate is absent. Infra DEV follows the same test ownership rules through DevOps. Documentation DEV is assigned to the Tech Writer; applicable SEC examines only secrets and sensitive data in documentation-only diffs.

## Rework, process changes and interruptions

| ID | Starting condition | Expected continuation and evidence |
|---|---|---|
| R01 | Initial TEST interrupted with some tests committed | Resume that pre-DEV invocation, preserve committed tests, record the finished commit and paths, then DEV. Do not implement while TEST remains unfinished. |
| R02 | TEST DONE recorded in state, history update interrupted | Recover the missing artifact/history record and advance once to DEV; do not re-delegate completed TEST. |
| R03 | DEV interrupted after completed TEST | Resume DEV with its work in progress and the existing tests; no fresh TEST. |
| R04 | REVIEW rejects after initial TEST and DEV | Increment rejections once for the review round, record rework, clear the old report, run DEV then every applicable post-DEV gate; preserve the TEST commit. |
| R05 | QA or SEC rejects after earlier approvals | Count the rejecting round, fix in DEV, rerun all applicable downstream gates, including earlier approved gates; no fresh TEST. |
| R06 | User feedback at item APPROVAL | Rework DEV and applicable downstream gates, request current item approval again, then MERGE. Do not increment rejections or rewrite independent tests. |
| R07 | MERGE rebase conflict or post-rebase test failure | Return to DEV, execute existing tests and rerun the applicable downstream gates and approval, then MERGE. No rejection count and no fresh TEST. |
| R08 | Successful rebase changes code after gates approved | Execute existing tests and rerun applicable REVIEW, QA, SEC and item APPROVAL; repeat the Definition of Done before merging. An unchanged rebase needs no extra round. |
| R09 | Interrupted rework transition leaves old DEV DONE or gate approval in state | The newer rework marker invalidates the old verdict. Enter DEV with last_report null; only verdicts from the new round can advance it. |
| R10 | Applicable TEST becomes enabled before any DEV invocation | Schedule TEST before DEV; record the updated effective order, then follow the new settings for future stages. |
| R11 | TEST becomes enabled or testing policy adds coverage after DEV started | Never insert fresh TEST. Add Developer-owned supplemental tests through DEV if needed, preserve independent tests, rerun applicable gates, and record why no new TEST was scheduled. |
| R12 | Process disables a completed or future gate | Keep the completed verdict as history; omit disabled future invocations. Required SEC and the critical override still apply. |
| R13 | Interrupted test dispute | Keep pipeline stage DEV, resume only the pending dispute against criteria/contracts, record correction or confirmation, clear the report and resume DEV. No fresh suite and no Developer changes to independent tests. |
| R14 | Custom QA-only item needs rework with per-task approval | Continue DEV, QA, APPROVAL, MERGE; do not invent TEST, REVIEW or SEC invocations. Required existing tests still run. |
| R15 | Another parallel item merges while initial TEST is unfinished | Finish and commit TEST before rebasing at the next boundary or resolving conflicts in DEV. After DEV, changed-code rebases invalidate applicable gate evidence as in R08. |
| R16 | Legacy history says DEV then TEST | Normalize remaining stages. Reuse and record an existing pre-DEV TEST commit if present. If it requests unfinished applicable TEST after implementation without that commit, preserve work and BLOCK for a recovery decision. |
| R17 | Branch missing on resume but merge already recorded in git | Complete the existing merge record idempotently; never restart item delivery or test writing. |
| R18 | Critical docs item at none, critical or full level | Omit TEST and new automated tests; retain enabled or forced REVIEW, QA, SEC and required item APPROVAL, then MERGE. |

Also compare each canonical role changed by the delivery rules with its complete embedded body in both Claude Markdown and Codex TOML. Parse the Codex TOML, compare config/default comments, and check every literal pipeline history example is a subsequence of the canonical order ending in MERGE. These checks verify distributed instructions and documented flows; they do not claim to execute agent decisions.
