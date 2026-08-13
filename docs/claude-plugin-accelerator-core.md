# accelerator-core

[acefei/agent-accelerator](https://github.com/acefei/agent-accelerator) — two small,
high-leverage skills. ~193 tokens always-on. Installed by `mise run setup-agents`.

## speak-aloud

Reads Claude's replies out loud over TTS, including a Docker→host bridge so it still
works when Claude is running inside a container. Useful for long jobs you want to
follow without watching the terminal.

Needs `jq`, which this repo already installs as a mise tool.

```
/speak-aloud
```

It also ships `Stop` and `SessionEnd` hooks, so speech triggers on its own once
enabled — you don't have to invoke it per message.

## remote-ssh-ops

The safe way to run commands and edit files on another machine. Reach for it any time
work happens over SSH rather than locally — it is the primitive other skills are meant
to build on instead of hand-rolling `ssh`/`scp`.

What it gets right, and what ad-hoc SSH usually gets wrong:

- Confirms key-based login works before doing anything.
- Runs remote commands through a **login shell**, so functions and environment from
  the remote `~/.bash_profile` are actually available.
- Edits remote files pull → edit → verify → push, with a backup, instead of piping
  `sed` at a live file.

```
/remote-ssh-ops
```
