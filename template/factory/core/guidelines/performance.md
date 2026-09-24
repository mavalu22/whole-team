# Performance

How the product stays fast enough without premature optimization. Budgets come from `factory/input/06-constraints.md` (performance budgets) and the NFRs in `factory/input/03-platform-architecture.md`. Search this file for the heading you need.

Sections: 1. Budgets · 2. Measure before optimizing · 3. Caching · 4. Query efficiency · 5. Payload size · 6. Lazy loading · 7. Blocking I/O · 8. Review checklist

## 1. Budgets

- Use the budgets the constraints define. When they define none, use these defaults and record them in the constraints at the next change request:
  - API: p95 under 300 ms for reads and 800 ms for writes, locally with seed data;
  - web: Largest Contentful Paint under 2.5 s, Interaction to Next Paint under 200 ms, Cumulative Layout Shift under 0.1 on a mid-range mobile profile;
  - initial JavaScript under 200 KB compressed for the first route.
- A budget is a test: an item that affects a budgeted path states in its report how it was checked.

## 2. Measure before optimizing

- Don't optimize without a measurement showing a problem against a budget. Clear code first.
- Measure with the right tool: query plans (`EXPLAIN`), a profiler, request timings in logs, browser performance tools or Lighthouse for web.
- Measure again after the change and record both numbers in the report (`GET /orders p95: 900 ms -> 120 ms`).
- Obvious anti-patterns (section 4, section 7) are fixed without measurement: they are defects, not optimizations.

## 3. Caching

- Cache only what is expensive to compute and read more than it changes. Every cache has an owner, a key scheme, a time-to-live, and an invalidation rule written next to it.
- Prefer HTTP caching for public, static and versioned assets: long `Cache-Control` max-age with content-hashed file names.
- Never cache personal or authorization-dependent data in shared caches; include the user or tenant in the key when caching per user.
- A stale cache must never grant access or show another user's data.
- Start without an application cache; add one when a measurement justifies it.

## 4. Query efficiency

- No queries inside loops (N+1); load related data in one query.
- Every list is paginated with a maximum page size.
- Indexes support the filters, joins and sorts of every frequent query (`factory/core/guidelines/data-and-persistence.md`).
- Select only needed columns on wide tables; count with the database, not by loading rows.
- Batch writes when inserting or updating many rows.

## 5. Payload size

- Responses return what the client needs: no full object graphs, no unused fields in list endpoints.
- Compress responses (gzip or Brotli) at the server or proxy.
- Images: correct dimensions, modern formats (WebP or AVIF with fallback where needed), `srcset` for responsive sizes, explicit width and height.
- Fonts: at most the weights the design uses, subset where possible, `font-display: swap`.
- Upload and request size limits are set (`factory/core/guidelines/api-design.md` section 4).

## 6. Lazy loading

- Split front-end code by route; load heavy components (editors, charts, maps) when they are needed.
- Lazy-load images and iframes below the fold (`loading="lazy"`); never lazy-load the main above-the-fold image.
- Load third-party scripts asynchronously, only on pages that need them, and only after consent when they track users.
- On the server, load optional modules and connections on first use when startup time matters.

## 7. Blocking I/O

- Never block the event loop or request thread with synchronous file, network or CPU-heavy work on a request path; use the async APIs of the stack.
- Move slow work (sending email, generating files, calling slow third parties, image processing) to background jobs when a request would exceed its budget; return `202` with a status resource if the client must follow it.
- Set timeouts on every outbound call, with retries only for idempotent operations and with backoff.
- Use connection pools for the database and HTTP clients; never open a connection per request.

## 8. Review checklist

- [ ] Changes to budgeted paths report how the budget was checked.
- [ ] No N+1 queries, unbounded lists or missing indexes on new queries.
- [ ] Responses are lean; lists are paginated; compression is on.
- [ ] Images and fonts are sized and formatted per section 5.
- [ ] Heavy front-end code and below-the-fold media load lazily.
- [ ] No blocking I/O on request paths; outbound calls have timeouts.
- [ ] Any cache has a key scheme, TTL, invalidation rule, and never mixes users' data.
