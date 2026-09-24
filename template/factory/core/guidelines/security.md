# Security

Security rules for every change, the OWASP mapping used in audits, and the two review checklists. Stack-specific libraries and settings are in `factory/input/04-stack-profile.md`; product-specific threats are in `factory/output/threat-model.md`. Search this file for the heading you need; reviewers read only the checklist for their depth.

Sections: 1. OWASP Top 10 mapping · 2. Input validation and output encoding · 3. Authentication and authorization · 4. Sessions and tokens · 5. Passwords · 6. Secrets · 7. Dependencies · 8. Security headers and CORS · 9. File uploads · 10. Logging · 11. Light review checklist · 12. Required review checklist

## 1. OWASP Top 10 mapping

Audits check every category; reviews check the ones the diff touches. Category names follow the OWASP Top 10; newer editions regroup them, and the rows below cover both the 2021 and later lists.

| Category | What to check | Section |
|---|---|---|
| Broken access control | Server-side authorization per resource; no IDOR; deny by default; CORS not permissive | 3, 8 |
| Cryptographic failures | TLS assumed in production; sensitive data encrypted at rest where required; strong hashing for passwords; no custom crypto | 5, 6 |
| Injection | Parameterized queries; no shell or template injection; output encoding | 2 |
| Insecure design | Threat model covers the feature; abuse cases; rate limits on sensitive flows | 12 |
| Security misconfiguration | Debug off; safe defaults; security headers; no default credentials; minimal error details | 8, 10 |
| Vulnerable and outdated components / supply chain | Audited dependencies; lockfile committed; trusted sources; CI actions pinned | 7 |
| Identification and authentication failures | Password policy; lockout or throttling; secure session handling; MFA where required | 3, 4, 5 |
| Software and data integrity failures | No unsafe deserialization; signed or verified updates and webhooks | 2 |
| Security logging and monitoring failures | Security events logged without sensitive data; alerts possible | 10 |
| Server-side request forgery | Outbound requests to user-supplied URLs restricted by allowlist | 2 |
| Mishandling of exceptional conditions | Errors fail closed; no sensitive details in errors; resources released | 2, 10 |

## 2. Input validation and output encoding

- Treat everything from outside the process as untrusted: request data, headers, cookies, files, webhooks, third-party responses, environment in multi-tenant setups.
- Validate at the edge with allowlists (types, formats, lengths, ranges, enumerations); reject what doesn't match (`factory/core/guidelines/api-design.md` section 4).
- **SQL and queries:** parameterized queries or the query builder only.
- **Shell:** avoid invoking a shell; if unavoidable, pass arguments as an array, never interpolate input.
- **HTML:** rely on the framework's automatic escaping; never insert untrusted input as raw HTML. If rich text is needed, sanitize with a maintained sanitizer and an allowlist.
- **Deserialization:** parse only data formats (JSON) into validated types; never deserialize untrusted input into objects of arbitrary classes.
- **Redirects and URLs:** allow only relative paths or allowlisted hosts for redirects; for server-side fetches of user-supplied URLs, allowlist hosts and block private and link-local address ranges.
- **Webhooks:** verify signatures and timestamps before processing.

## 3. Authentication and authorization

- Deny by default: every route requires authentication unless listed as public in the contract.
- Check authorization on the server for every request and every resource: the caller has the role **and** owns or may access this object. Never rely on hidden UI or client checks.
- Use one central authorization mechanism (policy functions, middleware), not ad-hoc checks scattered in handlers.
- Return `404` rather than `403` for resources the caller must not know exist.
- Use a well-maintained auth library or managed service; never implement token signing or password storage by hand.
- Throttle login, sign-up, password reset and MFA attempts per account and per IP; lock or slow down after repeated failures as the constraints require.
- Password reset and email verification tokens are single-use, random (at least 128 bits), stored hashed, and expire (for example within 1 hour).
- Re-authenticate for sensitive actions (changing email or password, deleting the account).

## 4. Sessions and tokens

- Browser sessions: cookies with `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict`), and a bounded lifetime; rotate the session ID on login and privilege change; invalidate it on logout on the server.
- Cookie-based sessions need CSRF protection for state-changing requests (SameSite plus a CSRF token or origin check).
- Tokens (for example JWT): short-lived access tokens, verified signature and algorithm (reject `none`), checked `exp`, `iss` and `aud`; refresh tokens stored server-side or rotated and revocable.
- Never store tokens in `localStorage` when a cookie session is possible; never put tokens in URLs.

## 5. Passwords

- Hash with Argon2id (preferred) or bcrypt, with parameters from current OWASP guidance (for example Argon2id with 19 MiB memory, 2 iterations, parallelism 1; bcrypt cost 10 or more). Never use fast hashes (MD5, SHA-1, plain SHA-256) for passwords.
- Minimum length 12 (or the constraints' policy), maximum at least 64; allow all characters; check against a list of breached or common passwords when possible. No composition rules that force patterns.
- Compare secrets in constant time.

## 6. Secrets

- Secrets come from environment variables or a secret store; `.env` files stay out of git (`.env.example` has placeholders only).
- Never log, print, return or commit a secret. Never put one in client-side code or build artifacts.
- If a secret is committed, treat it as leaked: report it as `critical`, recommend rotation, and remove it from the code (history rewriting is the user's decision).
- Use separate secrets per environment; development secrets are not production secrets.

## 7. Dependencies

- Add dependencies only per `factory/core/guidelines/dependencies.md`: needed, maintained, license-compatible, from the official registry.
- Commit the lockfile; install with the lockfile (for example `npm ci`).
- Run the dependency audit tool at SEC for items that add or update dependencies, and at every audit; `critical` and `high` advisories with a fix available block the item.
- Pin third-party CI actions to a version or commit.

## 8. Security headers and CORS

- Set, via the framework or a middleware: `Content-Security-Policy` (no `unsafe-inline` scripts where avoidable), `Strict-Transport-Security` (production), `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `frame-ancestors` in CSP (or `X-Frame-Options: DENY`).
- CORS: allow only the known origins from configuration; never reflect arbitrary origins with credentials; never `*` with credentials.
- Remove headers that reveal versions (`X-Powered-By`).

## 9. File uploads

- Limit size and count; check type by content (magic bytes), not only extension or `Content-Type`; allowlist types.
- Store uploads outside the web root or in object storage, with generated names; never use the client's file name as a path.
- Serve user files with `Content-Disposition: attachment` or from a separate domain; never execute them.
- Scan or re-encode risky formats (images, documents) when the constraints require it.

## 10. Logging

- Log security events: logins and failures, lockouts, permission denials, password and email changes, admin actions, validation failures at unusual rates.
- Never log passwords, tokens, session IDs, secrets, full payment data or unnecessary personal data; mask identifiers where needed (`factory/core/guidelines/observability.md`).
- Errors fail closed: on an unexpected error during an authorization or validation step, deny the action.
- Responses to users contain no stack traces, SQL or internal details.

## 11. Light review checklist

Start from the diff (`git diff <base>...<branch>`). For documentation-only diffs, check only the last two items.

- [ ] **Input validation:** every new input is validated at the edge with allowlists.
- [ ] **Authn/authz:** new routes require authentication unless explicitly public; authorization is checked per resource on the server.
- [ ] **Injection:** queries parameterized; no shell or template injection; no raw HTML from untrusted input.
- [ ] **XSS/CSRF:** output encoded by the framework; state-changing cookie-authenticated requests are CSRF-protected.
- [ ] **Unsafe deserialization:** none; only data formats parsed into validated types.
- [ ] **Dependency additions:** each justified, license-compatible, and free of known `critical` or `high` advisories.
- [ ] **Error leakage:** no stack traces or internals in responses.
- [ ] **Sensitive logging:** no secrets, tokens or unnecessary personal data in logs.
- [ ] **Secrets and sensitive data:** no keys, passwords, tokens, internal hostnames or real personal data in code, config, docs or examples.

## 12. Required review checklist

Everything in section 11, plus:

- [ ] **Threat-model delta:** new assets, actors, entry points or trust boundaries recorded in `factory/output/threat-model.md`, with mitigations.
- [ ] **Abuse cases:** for each new entry point, enumeration, brute force, replay, mass assignment, IDOR, privilege escalation and resource exhaustion were considered and are prevented or accepted with a reason.
- [ ] **Data-flow tracing:** untrusted input followed from entry to every sink (database, file system, shell, HTML, logs, outbound requests), beyond the diff.
- [ ] **Personal data:** collected only as needed, protected at rest and in transit as the constraints require, covered by retention and deletion rules.
- [ ] **Crypto and tokens:** standard libraries, current algorithms, random values from a CSPRNG, expirations set.
- [ ] **Rate limits** on authentication, reset, sign-up and expensive endpoints.
- [ ] **Security headers and CORS** as in section 8 for new surfaces.
- [ ] **Dependency audit tool** run, with results recorded.
