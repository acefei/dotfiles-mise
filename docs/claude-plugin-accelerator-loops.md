# accelerator-loops

[acefei/agent-accelerator](https://github.com/acefei/agent-accelerator) — repeatable,
verified workflows that run around the model instead of inside one conversation.
~147 tokens always-on. Installed by `mise run setup-agents`.

## What a loop is for

A loop is work that has a finish line the machine can check, and that is too long for
one session: burn down a lint backlog, migrate call sites file by file, keep retrying a
flaky integration until it is genuinely fixed. Each iteration does a slice, records
progress, and stops when the goal is met.

If the task fits in one conversation, you don't want a loop — just do it.

## Using it

```
/setup-loops              # once per project: creates claude-loops/
/loop-create <name>       # interview, then scaffold the loop
/loop-run <name>          # run one iteration
/loop-status              # progress across all loops
/loop-stop <name>         # unschedule, keep the folder
/loop-remove <name>       # delete it (asks first)
```

State lives in `claude-loops/<name>/`, with `PROGRESS.md` as the human-readable record
— read that first when a loop looks stuck.

## Make the goal checkable

A loop is only as good as its stopping condition. "Improve the tests" will run forever;
"`pytest` exits 0 and coverage ≥ 80%" will not. Write the finish line as a command that
returns a verdict, and let the loop decide against that rather than against its own
opinion of whether it is done.
