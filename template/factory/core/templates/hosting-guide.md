# Hosting guide - {{product name}} on {{platform}}

<!-- Written by DevOps in factory/output/hosting-guide.md (factory/core/workflow/hosting-guide.md), in config.product_docs_language. The factory never deploys: this guide is for the user. Verify platform specifics with web search, cite every source with its URL and the date checked, and reuse dated facts from the inputs and ADRs. -->

- **Written:** {{YYYY-MM-DD}} · **Checkpoint:** CP-{{n}}
- **Platform chosen in Discovery:** {{platform}} (03-platform-architecture.md §{{n}})

## 1. Prerequisites and accounts

<!-- Accounts to create, CLIs to install (with versions), billing notes, and the permissions needed. -->

- {{account or tool}}: {{purpose}}

## 2. Service mapping

| Product part | Service on {{platform}} | Plan or size | Notes |
|---|---|---|---|
| App | {{service}} | {{plan}} | {{notes}} |
| Database | {{service}} | {{plan}} | {{backups, version}} |
| Storage | {{service or not applicable}} | {{plan}} | {{notes}} |
| Background jobs | {{service or not applicable}} | {{plan}} | {{notes}} |

## 3. Environment variables

<!-- Every variable from .env.example, with where its production value comes from. Never include real values. -->

| Variable | Purpose | Source in production |
|---|---|---|
| {{NAME}} | {{purpose}} | {{platform secret, managed database URL, provider dashboard}} |

## 4. Build and start

- **Build command:** `{{command}}`
- **Start command:** `{{command}}`
- **Runtime version:** {{version}}
- **Port:** {{how the platform provides it}}
- **Health check path:** `{{/health}}`

## 5. Database provisioning and migrations

1. {{create the database}}
2. {{set the connection variable}}
3. {{run migrations: command, and when (release phase, pre-deploy step)}}
4. **Backups:** {{frequency, retention, how to restore; test a restore once}}

## 6. Domain and TLS

<!-- Custom domain setup, DNS records, certificate provisioning and renewal, and HTTP to HTTPS redirects. -->

{{steps}}

## 7. CI/CD deployment suggestion

<!-- How the user could deploy from the base branch after each checkpoint merge: the platform's git integration or a CI job. The factory does not set this up to run. -->

{{suggestion}}

## 8. Estimated monthly cost

**Estimate** as of {{YYYY-MM-DD}}, for {{assumptions: traffic, storage, plan}}. Prices change; check the sources before deciding.

| Item | Low | High |
|---|---|---|
| {{service}} | {{amount}} | {{amount}} |
| **Total** | **{{amount}}** | **{{amount}}** |

## 9. Rollback

<!-- How to return to the previous release (platform rollback, redeploying the previous tag cp-n), and how to handle migrations that are not backward compatible. -->

{{steps}}

## 10. Post-deploy checklist

- [ ] Health check returns 200.
- [ ] Sign-in and the main journeys work.
- [ ] Environment variables are set; no default secrets.
- [ ] HTTPS enforced; security headers present.
- [ ] Logs are visible and contain no secrets.
- [ ] Backups are scheduled and a restore was tested.
- [ ] {{product-specific check}}

## Sources

- {{title}} - {{URL}} (checked {{YYYY-MM-DD}})
