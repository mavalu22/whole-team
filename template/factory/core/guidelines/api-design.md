# API design

Rules for HTTP APIs (REST-style by default). If `factory/input/03-platform-architecture.md` chose GraphQL or RPC, apply the sections on validation, errors, idempotency, auth and rate limiting, and follow the stack profile for the rest. Search this file for the heading you need.

Sections: 1. Contract first · 2. Resource naming · 3. Methods and status codes · 4. Validation at the edge · 5. Error format · 6. Pagination, filtering and sorting · 7. Idempotency · 8. Versioning · 9. Auth headers · 10. Rate limiting · 11. Review checklist

## 1. Contract first

- Define or update the contract (an OpenAPI document, or the stack's schema) before implementing an endpoint. The contract is the source for tests, clients and docs.
- The contract lists every path, method, parameter, request and response schema, error response and auth requirement.
- Generate types or validators from the contract where the stack allows; never let the code and the contract drift. A change to the contract is part of the item's diff.

## 2. Resource naming

- Paths name resources with plural nouns: `/users`, `/users/{id}`, `/users/{id}/orders`.
- Use lowercase and hyphens in paths (`/password-resets`); use one case style for JSON fields across the whole API, as set in the stack profile (`camelCase` by default).
- Nest at most one level (`/users/{id}/orders`); beyond that, use top-level resources with filters (`/orders?userId=...`).
- Actions that don't fit CRUD become sub-resources or nouns: `POST /orders/{id}/cancellation`, not `POST /cancelOrder`.
- IDs are opaque strings to clients; don't expose sequential database IDs where enumeration is a risk.

## 3. Methods and status codes

| Method | Use | Success |
|---|---|---|
| `GET` | Read; safe, no side effects | `200` |
| `POST` | Create, or trigger an action | `201` with `Location`, or `200`/`202` |
| `PUT` | Replace a whole resource; idempotent | `200` or `204` |
| `PATCH` | Partial update | `200` or `204` |
| `DELETE` | Remove; idempotent | `204` |

Errors: `400` malformed request · `401` not authenticated · `403` authenticated but not allowed · `404` not found (also for resources the caller may not know exist) · `409` conflict (duplicate, version mismatch) · `413` payload too large · `415` unsupported media type · `422` valid syntax, failed validation · `429` rate limited · `500` unexpected server error · `503` dependency unavailable.

- Never return `200` with an error in the body.
- Never return `500` for client mistakes; validate and return `4xx`.

## 4. Validation at the edge

- Validate every input at the boundary, against the contract: path and query parameters, headers, body. Reject unknown fields where mass assignment is a risk.
- Check types, required fields, formats (email, UUID, dates in ISO 8601), lengths, ranges and enumerations.
- Normalize once (trim, case-fold emails) and pass typed, validated values inward.
- Limit request body size and array lengths.
- Return all validation errors of one request together, with the field path of each.

## 5. Error format

Use RFC 9457 problem details (`Content-Type: application/problem+json`) for every error:

```json
{
  "type": "https://example.com/problems/validation-error",
  "title": "Your request is not valid.",
  "status": 422,
  "detail": "2 fields are invalid.",
  "instance": "/users",
  "errors": [
    { "field": "email", "message": "must be a valid email address" },
    { "field": "password", "message": "must have at least 12 characters" }
  ],
  "traceId": "4bf92f3577b34da6"
}
```

- `type` is a stable identifier per error kind; clients branch on it, not on `title`.
- Never include stack traces, SQL, internal hostnames or secrets. Include the request's correlation ID (`traceId`) so logs can be found.

## 6. Pagination, filtering and sorting

- Every list endpoint is paginated, with a default and a maximum page size (for example 20 and 100).
- Prefer cursor pagination (`?cursor=...&limit=20`, response `nextCursor`) for large or changing collections; offset pagination (`?page=2&pageSize=20`) is fine for small, stable ones.
- Filters are query parameters named after fields (`?status=open&createdAfter=2026-01-01`); sorting uses `?sort=createdAt,-total` (minus for descending). Allow only indexed or explicitly supported fields.
- Return pagination metadata consistently in every list response.

## 7. Idempotency

- `GET`, `PUT` and `DELETE` are idempotent by definition; keep them so.
- `POST` endpoints that create payments, orders or messages accept an `Idempotency-Key` header: store the key with the result, and return the same result for a retry with the same key.
- Retries by clients must never create duplicates or double charges.

## 8. Versioning

- Version from the first public release: a path prefix (`/v1/`) or a header, as the stack profile says.
- Additive changes (new optional fields, new endpoints) don't need a new version. Removing or renaming fields, changing types or meanings does.
- Deprecate before removing: document it, add a `Deprecation` header, and keep the old version for the announced period.

## 9. Auth headers

- Send credentials in the `Authorization` header (`Bearer <token>`) or in secure, HttpOnly cookies for browser sessions; never in URLs or query strings.
- Every endpoint declares its auth requirement in the contract; the default is authenticated. Public endpoints are listed explicitly.
- Check authorization per resource on the server (the caller owns or may access this object), not only per route.

## 10. Rate limiting

- Rate-limit authentication, password reset, sign-up, and any expensive or public endpoint, per client and per account.
- Return `429` with `Retry-After`, and `RateLimit` headers where the stack supports them.

## 11. Review checklist

- [ ] The contract is updated and matches the implementation.
- [ ] Paths are plural nouns; JSON case style is consistent.
- [ ] Methods and status codes follow section 3; no `200` with an error body.
- [ ] Every input is validated at the edge; body size is limited.
- [ ] Errors use problem details without internal details.
- [ ] Lists are paginated with a maximum page size.
- [ ] Creating endpoints with side effects support idempotency keys where retries are possible.
- [ ] Auth requirement declared; authorization checked per resource.
- [ ] Sensitive or expensive endpoints are rate-limited.
