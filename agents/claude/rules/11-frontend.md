# Frontend

## Rendering

- Derive state; do not duplicate it. Two sources of truth drift apart.
- Keep components small and mostly presentational; push data-fetching to the edge.
- Every list item gets a stable key that is not the array index.

## Accessibility is not optional

Semantic elements before ARIA (`<button>`, not a `<div>` with a click handler). Every
interactive element is reachable and operable by keyboard, has a visible focus state,
and has an accessible name. Colour is never the only carrier of meaning. Target
WCAG 2.2 AA contrast.

## Performance

Measure before optimising. Then: lazy-load below-the-fold and route-level code, give
images explicit dimensions to avoid layout shift, and avoid re-rendering a whole list
when one row changes.

## State

Local state first. Lift only when genuinely shared, and reach for a store only when
prop-passing becomes the problem rather than a mild annoyance.
