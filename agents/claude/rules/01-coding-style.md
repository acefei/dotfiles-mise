# Coding style

Language-agnostic defaults. A language-specific rule file overrides this one.

## Immutability

Return new values; do not mutate arguments or shared state in place. Hidden mutation is
the most common source of bugs that only appear under concurrency or reordering.

## Keep it small

- Functions under ~50 lines, doing one thing.
- Files under ~800 lines; extract a module when a file grows past that.
- Nesting under 4 levels — use early returns instead of stacking conditionals.

## Naming

- `camelCase` for variables and functions, `PascalCase` for types and components,
  `UPPER_SNAKE_CASE` for constants (adjust to the language's own convention).
- Booleans read as predicates: `isReady`, `hasChildren`, `shouldRetry`, `canWrite`.
- Names say what a thing *is*, not what type it has.

## Errors

Handle explicitly at every level. Never swallow an exception to keep going. Log enough
context server-side to diagnose it, and show the user something they can act on.

## Avoid

- Magic numbers — name the threshold.
- Speculative abstraction — build it when the second caller appears, not before.
- Copy-paste divergence — extract when the duplication is real, not hypothetical.
