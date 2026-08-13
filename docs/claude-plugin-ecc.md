# ECC ("everything claude code")

[affaan-m/ECC](https://github.com/affaan-m/ECC) — the big one. 375 skills, 67 agents,
7 hooks and the `chrome-devtools` MCP server. Installed by `mise run setup-agents`.

## Know this first: it costs ~24k tokens of context in every session

That is roughly an order of magnitude more than every other plugin here combined, and
you pay it whether or not you use ECC that day. It buys breadth — a reviewer, a build
fixer and a patterns guide for most languages you are likely to touch. Decide
deliberately whether you want that breadth loaded all the time.

```bash
claude plugin details ecc      # see the per-component cost breakdown
claude plugin disable ecc      # turn it off; enable again when you want it
```

## Start here

```
/ecc-guide          # what's in the box and how the pieces fit
/ecc-recipes        # worked end-to-end examples
```

## What you'll actually reach for

| Need | Try |
| --- | --- |
| Review code you just wrote | `/code-review`, or the language reviewer (`/go-review`, `/react-review`, `/python-review`, …) |
| A build is broken | `/build-fix`, or the language build resolver |
| Security pass before a commit | `/security-scan`, `/security-review` |
| Plan a feature | `/plan`, `/plan-prd`, `/blueprint` |
| Tests | `/tdd-workflow`, `/test-coverage`, `/e2e-testing` |
| Language or framework conventions | `<lang>-patterns`, e.g. `/golang-patterns`, `/react-patterns` |

Most of these are model-invoked too — Claude will reach for them when the task fits,
so you often don't need to type anything.

## Keeping it lean

ECC is designed to be trimmed to the repo you're in:

```
/agent-sort         # sort skills into what this repo needs vs the rest
/skill-stocktake    # what's installed, what's actually used
/config-gc          # drop config you've stopped using
/ecc-tools-cost-audit
```

## Related

- [Claude skill workflow](claude-plugin-mattpocock-skills.md) — a smaller, opinionated
  pipeline that overlaps ECC on review and TDD. If both are enabled, prefer one
  vocabulary per task rather than mixing them mid-flow.
