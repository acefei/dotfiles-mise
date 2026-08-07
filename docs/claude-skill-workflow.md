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
- **Never install this pack twice.** The plugin and `gh skill install mattpocock/skills`
  are two routes to the same skills; taking both leaves you with every skill duplicated,
  and the `gh skill` copies land in `~/.claude/skills/` where they shadow nothing but
  clutter everything. This repo deliberately uses the **plugin** route only — see
  `CLAUDE_PLUGINS` in `.mise/tasks/setup-agents`.

- **The official marketplace is not pre-registered.** A fresh Claude Code install
  reports `No marketplaces configured`, and installing
  `mattpocock-skills@claude-plugins-official` fails with *"Plugin not found in
  marketplace"*. `setup-agents` therefore adds `anthropics/claude-plugins-official`
  like any other marketplace before installing from it.
- **Check for a second copy after bootstrap.** The official marketplace entry is a
  SHA-pinned mirror of `mattpocock/skills`, and installing it can auto-register that
  repo's *own* marketplace (`mattpocock`) and install the plugin a second time. Verify:

  ```bash
  claude plugin list | grep -c mattpocock-skills   # must be 1
  claude plugin uninstall mattpocock-skills@mattpocock   # if it is 2
  claude plugin marketplace remove mattpocock
  ```

## Updating

```bash
claude plugin update mattpocock-skills   # restart the session to pick it up
```

Because the official entry is SHA-pinned, updates land when that pin is bumped rather
than the moment upstream ships. That lag is the deliberate trade: this repo installs
**`mattpocock-skills@claude-plugins-official`** and nothing else. The upstream
`mattpocock/skills` route is not used — its `.claude-plugin/plugin.json` does not give
a reliably resolvable version, so the pinned official entry is the one to trust.

The plugin cache under `~/.claude/plugins/cache/` is managed and is overwritten on
update. If you hand-edit a skill there, keep the change as a patch outside the cache so
it can be re-applied.
