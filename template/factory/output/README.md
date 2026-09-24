# Output

Documents the factory produces while it works. Like everything under `factory/`, this folder is ignored by git: it lives only on this machine, so back it up (see the WholeTeam README).

Files are written by the role named below, through the Orchestrator. Subfolders are created on demand, the first time something is written to them.

## Folders

| Folder | Contents | Written by | When |
|---|---|---|---|
| `adr/` | Architecture Decision Records, `ADR-NNN-<slug>.md` | Architect | Discovery steps 2 and 3, and whenever a significant decision changes |
| `audits/` | Audit reports, `AUDIT-<YYYY-MM-DD>.md` | Security, with the Tech Lead and QA | `Audit` command, ongoing-project onboarding |
| `checkpoints/` | Checkpoint reports, `CP-<n>.md` | Orchestrator | At every checkpoint |
| `drafts/` | Working drafts, such as `backlog-draft.md` | Architect | Discovery step 8 and change requests |
| `support/` | Reproduction scripts and tests, `B-<id>-repro.*` | Support | `Support:` reports |

## Files

| File | Contents | Written by | When |
|---|---|---|---|
| `architecture.md` | The architecture document: components, data model, integrations, NFRs, ADR index | Architect | Discovery step 3; updated by change requests |
| `threat-model.md` | STRIDE-lite threat model: assets, actors, trust boundaries, mitigations, open risks | Security | Discovery step 6; updated by required reviews and audits |
| `hosting-guide.md` | How to host the product on the platform chosen in Discovery | DevOps | At the checkpoint set by `deploy.hosting_guide` |
| `baseline.md` | Test, lint and build results before the factory changed anything | Architect | Ongoing projects, during reverse Discovery |

The templates for these documents are in `factory/core/templates/`.
