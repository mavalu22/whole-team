# Hosting guide - {{product name}} on {{platform}}

<!-- Written by DevOps in factory/output/hosting-guide.md (factory/core/workflow/hosting-guide.md), in config.product_docs_language. The factory never deploys or publishes: this guide is for the user. Verify platform and registry specifics with web search, cite every source with its URL and the date checked, and reuse dated facts from the inputs and ADRs. Two parts: hosting (sections 1-10) when the product has something to host, publishing (section 11) when it has a library or plugin. Leave out the part that does not apply; with no hosting part, the title is "Publishing guide - {{product name}} on {{registry}}". -->

- **Written:** {{YYYY-MM-DD}} · **Checkpoint:** CP-{{n}}
- **Platform chosen in Discovery:** {{platform}} (03-platform-architecture.md §{{n}})
- **Registry or marketplace:** {{registry}} (library or plugin only)

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

## 11. Publishing

<!-- Only for a library or plugin. The factory never publishes: every step is for the user. -->

### 11.1 Account and ownership

<!-- The registry or marketplace account, the organization or publisher ID, who owns it, and two-factor authentication. -->

{{steps}}

### 11.2 Package metadata

<!-- The fields the registry or marketplace requires or displays (name, description, license, repository, keywords, icon, host range), and where each lives in the product. -->

{{fields}}

### 11.3 Versioning and tags

<!-- The version policy from 05-design-spec.md, how to bump the version, and the git tag for each release. -->

{{steps}}

### 11.4 Building the release artifact

- **Build command:** `{{command}}`
- **Pack command:** `{{command}}`
- **Check the contents:** `{{command that lists the packed files}}`

### 11.5 Signing or verification

<!-- Signing, provenance or publisher verification, where the registry requires or supports it; otherwise "Not required by {{registry}}". -->

{{steps}}

### 11.6 Publishing tokens

<!-- How to create a scoped token (or set up trusted publishing), and its name as a CI secret. Never in the repository. -->

{{steps}}

### 11.7 CI release workflow suggestion

<!-- A workflow that builds, checks and publishes on a version tag. The factory does not set this up to run. -->

{{suggestion}}

### 11.8 Review times and listing requirements

<!-- Marketplace review times and listing requirements, verified with web search and dated. -->

{{facts}} (checked {{YYYY-MM-DD}})

### 11.9 Deprecating or yanking a bad release

<!-- How to deprecate, yank or unpublish a release on this registry, its limits, and how to publish the fix. -->

{{steps}}

## Sources

- {{title}} - {{URL}} (checked {{YYYY-MM-DD}})
