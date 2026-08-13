# API design

For HTTP APIs you author.

## Shape

- Resources are plural nouns: `/users`, `/users/{id}/sessions`. Verbs live in the
  method, not the path.
- Use the status code that means what happened: `200` read, `201` created (with
  `Location`), `204` deleted, `400` malformed, `401` unauthenticated, `403`
  authenticated but not allowed, `404` absent, `409` conflict, `422` valid syntax but
  semantically wrong, `429` rate-limited.
- `PATCH` for partial updates, `PUT` only for genuine whole-resource replacement.

## Envelope

Answer with a consistent shape so clients can write one parser: a success indicator,
the payload (nullable on error), an error message (nullable on success), and pagination
metadata where a list is returned. Never return a bare array for a list endpoint —
you will want to add pagination later and it will be a breaking change.

## Non-negotiables

- **Paginate every list endpoint** from day one; default and cap the page size.
- **Version** before the first external consumer, not after.
- **Rate-limit** every public endpoint and say so in the response headers.
- Error messages help the caller fix the call; they never leak internals, stack
  traces, or whether an account exists.
