# Backend

## Data access

- Put data access behind a repository interface: `findAll`, `findById`, `create`,
  `update`, `delete`. Business logic depends on the interface, not the driver.
- **N+1 queries are a defect.** Join or batch. Watch for them whenever a loop contains
  an `await`.
- Every query that can return many rows takes a `LIMIT`. Unbounded queries are an
  outage waiting for a large customer.
- Migrations are forward-only and reversible in effect; never edit a migration that
  has run anywhere.

## Concurrency and failure

- Assume every network call can fail, hang, or be delivered twice. Set timeouts,
  retry idempotent operations with backoff, and make handlers idempotent where a
  retry could duplicate an effect.
- A background job that can run twice must be safe to run twice.

## Observability

Log structured events with enough identifiers to trace one request end to end. Log the
decision and its inputs, not just the outcome — "rejected because X was 3, limit is 2"
beats "rejected".
