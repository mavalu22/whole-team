# Hosting guide

Read at the checkpoint set by `deploy.hosting_guide` (`first_checkpoint` or `final_checkpoint`; `never` skips it), when `delivery.hosting_guide_written` is false. The factory never deploys (`deploy.target: local`); this guide tells the user how to host the product themselves.

## Procedure

1. Delegate to `devops` with stage `DOCS`. The task message includes:
   - the target hosting platform from `factory/input/03-platform-architecture.md` (its section number);
   - the paths of `02-stack.md`, `03-platform-architecture.md`, `04-stack-profile.md` and `06-constraints.md` (budget, compliance, availability);
   - the output path `factory/output/hosting-guide.md` and the template `factory/core/templates/hosting-guide.md`.
2. DevOps verifies current platform specifics (service names, pricing, limits, build settings) with web search when available, cites the sources, and records the date checked. It reuses facts already recorded with a date in the input files or ADRs instead of searching again.
3. The guide covers:
   - prerequisites and accounts;
   - the service mapping (app, database, storage, background jobs);
   - environment variables with their sources (which service or secret store provides each);
   - build and start commands;
   - database provisioning and migrations;
   - domain and TLS;
   - a CI/CD deployment suggestion;
   - an **estimated** monthly cost range, labeled as an estimate with the date;
   - rollback;
   - a post-deploy checklist.
4. The guide is written in `config.product_docs_language`.
5. Review the report: every section present, sources cited, the cost labeled as an estimate. Send it back once if not.
6. Set `delivery.hosting_guide_written: true` when the checkpoint completes, and show the user a summary of at most 5 lines with the file path.

## Updates

If a `Change:` changes the target platform or the stack after the guide was written, delegate an update to `devops` at the next checkpoint and say so in the checkpoint report.
