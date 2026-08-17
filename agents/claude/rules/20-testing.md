# Testing

## What to test

Test **observable behaviour**, not implementation. A test that breaks when you rename
a private method — while the behaviour is unchanged — is a liability, not coverage.

Three layers, all of them:

- **Unit** — a function or component in isolation.
- **Integration** — the seams: API endpoints, database access, external clients.
- **End-to-end** — the few flows whose breakage would be an incident.

## Shape

Arrange–Act–Assert, with names that state the behaviour:

```
test("returns an empty list when no records match the query")
test("throws when the API key is missing")
test("falls back to substring search when the index is unavailable")
```

Not `test("works")`.

## Discipline

- Write the failing test first, watch it fail for the right reason, then make it pass.
  A test you never saw fail has not been tested.
- Target 80% coverage as a floor, but treat an uncovered branch as the question
  "what happens here?" rather than a number to game.
- Tests are isolated and order-independent: no shared mutable fixtures, no reliance on
  a previous test's leftovers.
- Fix the implementation, not the test — unless the test encodes the wrong expectation,
  in which case say so explicitly.
