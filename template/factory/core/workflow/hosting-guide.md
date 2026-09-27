# Hosting guide

Read at the checkpoint set by `deploy.hosting_guide` (`first_checkpoint` or `final_checkpoint`; `never` skips it), when `delivery.hosting_guide_written` is false. The factory never deploys (`deploy.target: local`) and never publishes; this guide tells the user how to host the product themselves and, for a `library` or `plugin`, how to publish it.

## Procedure

1. If the product has nothing to host and no `library` or `plugin` (for example a `cli` alone), there is no guide: tell the user in one line and go to step 6. Otherwise, delegate to `devops` with stage `DOCS`. The task message includes:
   - the target hosting platform from `factory/input/03-platform-architecture.md` (its section number), and for `library` and `plugin` the registry or marketplace;
   - the parts to write (step 3);
   - the paths of `02-stack.md`, `03-platform-architecture.md`, `04-stack-profile.md` and `06-constraints.md` (budget, compliance, availability);
   - the output path `factory/output/hosting-guide.md` and the template `factory/core/templates/hosting-guide.md`.
2. DevOps verifies current platform specifics (service names, pricing, limits, build settings, registry and marketplace rules) with web search when available, cites the sources, and records the date checked. It reuses facts already recorded with a date in the input files or ADRs instead of searching again.
3. The guide has a hosting part when the product has something to host, and a publishing part when it has `library` or `plugin`. With nothing to host, it is only a publishing guide. The hosting part covers:
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

   The publishing part covers:
   - the registry or marketplace account and ownership;
   - package metadata;
   - versioning and tags;
   - building the release artifact;
   - signing or verification, where the registry requires it;
   - publishing tokens stored as CI secrets, never in the repository;
   - a CI release workflow suggestion;
   - marketplace review times and listing requirements, verified with web search and dated like the hosting facts;
   - how to deprecate or yank a bad release.
4. The guide is written in `config.product_docs_language`.
5. Review the report: every section of its parts present, sources cited, the hosting cost labeled as an estimate. Send it back once if not.
6. Set `delivery.hosting_guide_written: true` when the checkpoint completes, and show the user a summary of at most 5 lines with the file path.

## Updates

If a `Change:` changes the target platform, the registry or marketplace, the interfaces or the stack after the guide was written, delegate an update to `devops` at the next checkpoint and say so in the checkpoint report.
