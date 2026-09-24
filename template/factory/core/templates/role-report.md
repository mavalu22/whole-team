# Role report

<!-- Every role agent ends its work with this report, in English. The block below is identical to the one embedded in every agent file. Replace each <...> with the value; keep the field names and their order. -->

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

## Field rules

- **ROLE:** the role slug, for example `qa`.
- **ITEM:** `T-012` or `B-003`; for Discovery work the step key (for example `s3_architecture`); for audits the report file name; for checkpoint docs `CP-<n>`.
- **VERDICT:**
  - `DONE`: work stages (TEST, DEV, DOCS, DISCOVERY drafts, SUPPORT) finished.
  - `APPROVED` or `REJECTED`: gate stages (REVIEW, QA, SEC, VALIDATION). `REJECTED` needs at least one finding that requires a fix.
  - `BLOCKED`: you need a decision or information; put the question in `QUESTIONS`, with your recommended answer.
- **SUMMARY:** results, not process. 2-4 lines.
- **EVIDENCE:** one line per check, `<command> -> <result>`, quoting only the lines that matter (the failing test and its assertion, the lint error, the HTTP status). QA maps each acceptance criterion: `AC2: <command> -> <result>`. Never paste whole logs. Write `- none` when the stage runs no commands.
- **FINDINGS:** one line per finding, or `- none`. Severity values:
  - reviews, QA and validation: `blocker`, `major` (both require a fix; the verdict is `REJECTED`), `minor` (fix if the item returns to DEV anyway), `info` (never a reason to reject);
  - SEC and audits: `critical`, `high`, `medium` (require a fix), `low` (recorded as a known issue);
  - QA only: `UNRELATED_DEFECT` for defects in already-merged code outside the item; not a rejection.
- **QUESTIONS:** only when `BLOCKED`; otherwise `none`.
- **ARTIFACTS:** short commit hashes with subjects, files written, test paths; or `none`.

Role-specific fields, when a role file or the task message asks for them, follow `ARTIFACTS`, one per line, in `NAME: value` form.
