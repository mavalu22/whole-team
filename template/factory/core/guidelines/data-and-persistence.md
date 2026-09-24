# Data and persistence

Rules for schemas, migrations and data access. The database engine, ORM or query layer and the migration tool are in `factory/input/04-stack-profile.md`. Search this file for the heading you need.

Sections: 1. Schema design · 2. Constraints and indexes · 3. Migrations · 4. Transactions · 5. Query efficiency · 6. Deletion · 7. Time · 8. Seed and test data · 9. Backups · 10. Review checklist

## 1. Schema design

- Normalize to third normal form by default: each fact stored once. Denormalize only for a measured read need, and record how the copy stays consistent.
- Every table has a primary key. Prefer surrogate keys (UUIDs, or integers kept internal) over natural keys that can change (emails, names).
- Choose types that fit the data:
  - money as integer minor units (`amount_cents`) or fixed-point decimal, with a currency column when more than one currency is possible; never floating point;
  - timestamps with time zone, stored in UTC;
  - enumerations as check-constrained text or native enums, not magic integers;
  - booleans as booleans.
- Name tables and columns consistently (stack profile), with foreign keys named after the referenced entity (`customer_id`).
- Every table has `created_at` and `updated_at` unless it is a pure join table.

## 2. Constraints and indexes

- The database enforces integrity; application checks alone are not enough:
  - `NOT NULL` on every column that must have a value;
  - `UNIQUE` on natural identifiers (email per tenant, slug);
  - foreign keys on every reference, with an explicit `ON DELETE` rule;
  - `CHECK` constraints for ranges and allowed values.
- Index every foreign key, and the columns used in frequent filters, joins and sorts. Composite index column order follows the query's equality columns first, then range or sort columns.
- Don't add indexes no query needs; each one costs writes and storage. Remove redundant ones (a prefix of another composite index).

## 3. Migrations

- Every schema change is a migration in version control, applied by the migration tool; never change a schema by hand.
- Migrations are reversible: each has a down step, or, when data loss makes that impossible, a documented forward-only fix and a backup step.
- Migrations are safe on existing data:
  - add a non-null column with a default, or in three steps (add nullable, backfill in batches, set not null);
  - rename or change a column with expand and contract: add the new one, write to both, backfill, switch reads, drop the old one in a later release;
  - avoid long locks on large tables; build indexes concurrently where the engine supports it.
- Never edit a migration that has run on a shared branch; add a new one.
- Keep data migrations (backfills) separate from schema migrations, idempotent, and batched.

## 4. Transactions

- Wrap every multi-step write that must succeed or fail together in one transaction, in the application layer.
- Keep transactions short: no network calls or user waits inside.
- Handle concurrent updates on the same row: optimistic locking with a version column, or `SELECT ... FOR UPDATE` where contention is expected.
- For work that spans the database and an external system (email, payment), write an outbox record in the same transaction and deliver it afterwards, instead of calling out inside the transaction.

## 5. Query efficiency

- Avoid N+1 queries: never query inside a loop over results. Load related rows with a join, an `IN (...)` query, or the ORM's eager-loading feature.
- Every list query has a limit (pagination).
- Select only the columns you need for large tables or wide rows.
- Use parameterized queries or the query builder for every value; never concatenate input into SQL.
- Check the query plan (`EXPLAIN`) for new queries on tables expected to grow, and add the index they need.

## 6. Deletion

- **Hard delete** by default for data with no business history, and always when a user exercises the right to erasure (`factory/core/guidelines/privacy-and-compliance.md`).
- **Soft delete** (`deleted_at`) only when the product needs recovery or history. Then every query must exclude deleted rows (a default scope or view), and unique constraints must account for them (partial unique index).
- Define what happens to dependent rows: cascade, restrict or anonymize, per the constraints document.

## 7. Time

- Store timestamps in UTC; convert to the user's time zone only for display.
- Use the database's timestamp-with-time-zone type, or ISO 8601 strings with `Z` where the engine has no such type.
- Pass the current time into domain logic instead of reading the clock inside it, so tests can fix it.

## 8. Seed and test data

- Seed scripts create the minimum data to run the product locally (an admin account for development, reference data), are idempotent, and are safe to re-run.
- Test data comes from factories or fixtures, isolated per test and per parallel slot (`FACTORY_SLOT` database name).
- Never use real personal data in seeds, fixtures or examples; generate synthetic data.

## 9. Backups

- The factory runs the product locally and does not operate backups, but the hosting guide must state the backup and restore approach for production (frequency, retention, restore test).
- Destructive migrations document the backup to take before running them.

## 10. Review checklist

- [ ] Types fit the data (money, time, enums); keys and timestamps are present.
- [ ] Constraints enforce the rules; foreign keys have explicit delete rules.
- [ ] New queries have supporting indexes; no redundant indexes added.
- [ ] Migrations are reversible or documented forward-only, and safe on existing data.
- [ ] Multi-step writes are transactional; no external calls inside transactions.
- [ ] No N+1 queries; list queries are bounded; all values are parameterized.
- [ ] Deletion behavior (hard or soft) is explicit and consistent.
- [ ] Timestamps are UTC.
- [ ] Seeds and fixtures contain no real personal data.
