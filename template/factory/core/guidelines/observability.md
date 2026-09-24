# Observability

How the product tells you what it is doing. The logging library and format are in `factory/input/04-stack-profile.md`; observability needs are in `factory/input/03-platform-architecture.md`. Search this file for the heading you need.

Sections: 1. Structured logging · 2. Log levels · 3. Correlation IDs · 4. No personal data in logs · 5. Error reporting · 6. Health checks · 7. Basic metrics · 8. Review checklist

## 1. Structured logging

- Log as structured events (JSON in production; a readable format is fine locally), one event per line, to stdout or stderr.
- Every event has: timestamp (UTC, ISO 8601), level, message, service or module, and the correlation ID when inside a request or job.
- Put variable data in fields, not in the message: `{"msg":"order created","orderId":"o_123","items":3}`, not `"order o_123 created with 3 items"`.
- Use one logger configured at startup; no `print` or `console.log` in product code.
- Log at boundaries: incoming requests (method, route, status, duration), outgoing calls (target, status, duration), job start and end, and business events that matter (order placed, payment failed).

## 2. Log levels

| Level | Use | Example |
|---|---|---|
| `error` | An operation failed and needs attention | Payment provider returned 500 after retries |
| `warn` | Something unexpected, handled, that may need attention if repeated | Retry succeeded on the second attempt; deprecated endpoint called |
| `info` | Normal, significant events | Server started; order created; user signed in |
| `debug` | Detail for diagnosing problems; off in production by default | Cache miss for key; parsed configuration values (without secrets) |

- The level comes from configuration (`LOG_LEVEL`).
- Don't log the same error at every layer: log it once, where it is handled, with context.
- Expected outcomes (validation failure, not found) are not errors; log them at `info` or not at all.

## 3. Correlation IDs

- Accept an incoming request ID header (`traceparent` from W3C Trace Context, or `X-Request-Id`), or generate one; return it in the response headers.
- Attach it to every log event and error report for that request, and pass it to outgoing calls and background jobs.
- Include it in error responses (`traceId` in problem details) so users can quote it.

## 4. No personal data in logs

- Never log: passwords, tokens, session IDs, API keys, secrets, full card numbers, CVV, health or other sensitive data, full request or response bodies of sensitive endpoints.
- Avoid personal data (names, emails, phone numbers, addresses, IPs where the constraints treat them as personal); log internal IDs instead.
- When an identifier is needed for support, mask it (`j***@example.com`).
- Configure redaction in the logger for known sensitive field names (`password`, `token`, `authorization`, `cookie`, `secret`) as a safety net, not as the main control.

## 5. Error reporting

- Unhandled errors are caught at the top level of requests, jobs and the process, logged at `error` with the stack trace and correlation ID, and turned into a safe response (`500` problem details) or a failed job.
- The process exits on unrecoverable startup errors with a clear message; it does not keep running in a broken state.
- If the stack profile includes an error-reporting service, send errors there with the same redaction rules; the factory only configures it, never with real production credentials.

## 6. Health checks

- **Liveness** (`GET /health` or `/healthz`): returns `200` when the process is running; no dependency checks. Used by the local run and by QA to know the product started.
- **Readiness** (`GET /ready`): returns `200` only when dependencies the app needs (database, cache) are reachable; `503` otherwise.
- Health endpoints are fast, unauthenticated, reveal no versions or internals, and are excluded from request logs at `info` to avoid noise.
- CLIs and workers expose the same information through an exit code or a status command.

## 7. Basic metrics

When the architecture calls for metrics, expose at least:

- request rate, error rate and duration (p50, p95, p99) per route;
- outbound call duration and error rate per dependency;
- job counts, failures and queue depth for background work;
- process health: memory, CPU, open connections.

Use the stack's standard library (for example OpenTelemetry or a Prometheus client). Label cardinality stays bounded: route templates (`/users/{id}`), never raw paths or user IDs as labels.

## 8. Review checklist

- [ ] Logs are structured, at the right level, with the correlation ID, from the configured logger.
- [ ] No secrets, tokens or unnecessary personal data in any log event.
- [ ] Errors are logged once, where handled, with context; unexpected errors reach a top-level handler.
- [ ] Request IDs propagate to outgoing calls, jobs and error responses.
- [ ] Health and readiness endpoints exist and stay fast and unauthenticated.
- [ ] Metrics, where required, use bounded labels.
