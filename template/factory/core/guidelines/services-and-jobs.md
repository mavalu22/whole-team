# Services and jobs

Rules for processes with no direct user interface: queue workers, scheduled jobs, stream processors, daemons. The inputs, outputs, triggers and guarantees of this product are in `factory/input/05-design-spec.md` section 17; the start command is in `factory/input/04-stack-profile.md`. Search this file for the heading you need.

Sections: 1. Message contracts · 2. Idempotent handlers · 3. Retries and backoff · 4. Dead letters · 5. Timeouts and resource limits · 6. Scheduling · 7. Graceful shutdown · 8. Health checks · 9. Logs and metrics · 10. Review checklist

## 1. Message contracts

- Every input and output message or event has a schema in the spec (JSON Schema, Avro, Protobuf, or the stack's typed contract), with a version field or a versioned topic.
- Validate every incoming message against its schema before handling it; a message that fails validation goes to the dead letters (section 4), never into a retry loop.
- Changes are additive: new optional fields only. Removing or renaming a field, or changing its meaning, needs a new version that consumers can handle side by side.

## 2. Idempotent handlers

- Assume at-least-once delivery: every message can arrive twice, late or out of order.
- Make handlers idempotent: a stable message ID or a business key, stored with the result (a processed-messages table, a unique constraint, an upsert), so a repeat has no second effect.
- Write the state change and the "processed" mark in one transaction, or publish outputs with an outbox, so a crash between them cannot lose or duplicate work.
- Acknowledge a message only after its effect is committed.

## 3. Retries and backoff

- Retry only transient failures (timeouts, `503`, connection errors, lock conflicts); fail fast on validation and business errors.
- Exponential backoff with jitter (for example 1 s, 2 s, 4 s ... up to a cap), with a maximum number of attempts from configuration.
- Never retry in a tight loop, and never block the whole queue behind one failing message.

## 4. Dead letters

- A message that fails validation or exhausts its retries goes to a dead-letter queue or table, with the error, the attempt count and the time.
- Dead letters are visible (a log line at `error`, a metric) and can be replayed after a fix, by a documented command.
- Never drop a message silently.

## 5. Timeouts and resource limits

- Every outbound call (database, HTTP, queue) has a timeout; every handler has a maximum run time.
- Bound concurrency and batch sizes from configuration; never load an unbounded result set into memory.
- Release connections, file handles and locks on every path, including errors.

## 6. Scheduling

- Schedules are in configuration, in UTC, with the time zone stated when business rules need local time.
- Scheduled jobs are safe to run twice and safe to skip once: they compute their work from state (for example "everything not yet processed"), not from "since the last run".
- Prevent overlapping runs of the same job with a lock or a lease that expires.

## 7. Graceful shutdown

- On `SIGTERM` (and `SIGINT`): stop taking new messages, finish or release the in-flight ones within a configured grace period, commit offsets or acknowledgements, close connections, then exit 0.
- Messages not finished in time are released back to the queue unacknowledged, never half-applied.

## 8. Health checks

- A liveness check (the process runs and its loop is not stuck) and a readiness check (its dependencies are reachable), as an endpoint or a command, as `factory/core/guidelines/observability.md` describes.
- The health check never does heavy work or changes state.

## 9. Logs and metrics

- Structured logs (`factory/core/guidelines/observability.md`) with the message ID and a correlation ID taken from the message, or created at the entry point and passed on to every output.
- Log at `info` once per message outcome, `warn` per retry, `error` per dead letter. Never log whole payloads with personal data or secrets.
- Metrics, when the stack has them: messages processed, failed, retried and dead-lettered, handler duration, queue lag.

## 10. Review checklist

- [ ] Every input and output matches its schema in the spec; incoming messages are validated.
- [ ] Handlers are idempotent; the effect and the "processed" mark commit together; acknowledgement comes after the commit.
- [ ] Only transient errors are retried, with backoff, jitter and a maximum.
- [ ] Failed messages go to dead letters with the error; nothing is dropped silently.
- [ ] Timeouts on every outbound call; bounded concurrency and batches.
- [ ] Scheduled jobs are safe to repeat and cannot overlap.
- [ ] `SIGTERM` stops intake and finishes or releases in-flight work.
- [ ] Health check present and cheap.
- [ ] Structured logs carry the message and correlation IDs, without secrets or unnecessary personal data.
- [ ] No breaking change to a message schema unless the item says it is intended and the version policy allows it.
