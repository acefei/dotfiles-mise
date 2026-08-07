# Claude Skill Workflow

How to take an idea from nothing to shipped code using the [mattpocock-skills](https://github.com/mattpocock/skills) plugin, installed by `mise run setup-agents`.

## Mental model

The skills split on **who can invoke them**. User-invoked skills orchestrate and are
reachable only when you type them. Model-invoked skills hold the reusable discipline and
Claude reaches for them on its own.

```
you type  →  /grill-with-docs  /wayfinder  /to-spec  /to-tickets  /implement
                     │                                    │
Claude reaches for → /grilling  /domain-modeling      /tdd  /code-review
                     /research  /prototype            /codebase-design
```

## Step 0 — once per repo

```bash
/setup-matt-pocock-skills
```

Asks for your issue tracker (GitHub, Linear, or local files), your triage labels, and
where docs go. `/to-spec`, `/to-tickets`, `/triage` and `/wayfinder` all read that
config — run it first or they will guess.

## Pick a path by size

### Path A — fits in roughly one session

A feature or a contained change.

```
/grill-with-docs  →  /to-spec  →  /to-tickets  →  /implement
   align, and         spec on      tracer-bullet   builds, driving /tdd at
   build CONTEXT.md   tracker      tickets with    agreed seams, closing
   + ADRs                          blocking edges  with /code-review
```

### Path B — bigger than one agent session

A new product, a migration, anything where the route to the end is not visible yet.

```
/wayfinder ──chart──→  a map issue + decision tickets on the tracker
     │                 (names the destination, maps the frontier breadth-first,
     │                  fires /research subagents in parallel)
     │
     └────work────→  one decision ticket per session, until the fog clears
                            │
                            └──→  then Path A: /to-spec → /to-tickets → /implement
```

`/wayfinder` **is** the from-scratch entry point — it runs `/grilling` and
`/domain-modeling` internally to name the destination, so don't run
`/grill-with-docs` first or you do the same interview twice.

## Quick reference

| Skill                          | Use it when                                                        |
| ------------------------------ | ------------------------------------------------------------------ |
| `/setup-matt-pocock-skills`    | First time in a repo                                               |
| `/ask-matt`                    | You don't know which skill fits — a router over the others         |
| `/grill-with-docs`             | One coherent change; also builds `CONTEXT.md` + ADRs               |
| `/grill-me`                    | Same interview, non-code subject, no docs                          |
| `/wayfinder`                   | Work too big for one session; plan as a map of decision tickets     |
| `/to-spec`                     | Turn the current conversation into a spec on the tracker            |
| `/to-tickets`                  | Break a spec or plan into tickets with blocking edges               |
| `/implement`                   | Build from a spec or tickets                                        |
| `/triage`                      | Move incoming issues through triage roles                           |
| `/improve-codebase-architecture` | Every few days — survey for deepening opportunities               |
| `/handoff`                     | Context is running out; compact for the next agent                  |

## Gotchas

- **`/to-spec` runs no interview.** It only synthesizes what is already in the
  conversation, so it must run in the *same session* as the grilling.
- **Orchestrating skills are slash-only** (`disable-model-invocation: true`). Claude
  will not reach for `/grill-with-docs`, `/wayfinder`, `/to-spec`, `/to-tickets`,
  `/implement` or `/triage` on its own — you have to type them.
- **`/wayfinder` resolves at most one ticket per session** (research excepted). That is
  deliberate, not a limit to route around.
- **Install this pack once.** It ships both as a plugin and as a `gh skill` pack;
  taking both routes gives you every skill twice. `setup-agents` uses the plugin.

## Updating

```bash
claude plugin update mattpocock-skills   # restart the session to pick it up
```

If a skill ever looks wrong, check you have exactly one copy — `claude plugin list |
grep -c mattpocock-skills` should print `1`.
