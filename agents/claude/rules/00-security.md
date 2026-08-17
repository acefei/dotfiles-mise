# Security

Applies to every project, every language.

## Never commit secrets

- No API keys, passwords, tokens or private keys in source — ever, including in
  tests, fixtures and example config.
- Read secrets from environment variables or a secret manager. Validate at startup
  that required ones are present, and fail loudly if not.
- If a secret is ever exposed, rotate it. Removing the commit is not enough.
- Never echo a secret into logs, a command line (visible in `ps`), or an error message.
  Write it to a `600` file or pass it on stdin instead.

## Validate at the boundary

Everything crossing a trust boundary is untrusted: user input, API responses, file
contents, environment. Validate with a schema where one exists, and fail fast with a
clear message rather than coercing silently.

## The usual suspects

- **SQL injection** — parameterised queries only; never string-concatenate a query.
- **Path traversal** — resolve and confirm the path stays inside the intended root.
- **XSS** — escape on output; never interpolate untrusted text into HTML.
- **Command injection** — pass argument arrays, not shell strings. Avoid `shell=True`.

## Before any commit touching auth, payments, or user data

Say plainly what the change lets an attacker do that they could not do before. If the
answer is "nothing", say why. Security-sensitive changes get a review pass of their own.
