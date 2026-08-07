# dotfiles

[![Installation on Various OS](https://github.com/acefei/dotfiles-mise/actions/workflows/test-install.yml/badge.svg?branch=main)](https://github.com/acefei/dotfiles-mise/actions/workflows/test-install.yml)

Personal development environment for Linux and macOS, managed by [mise](https://mise.jdx.dev). Rootless - nothing requires sudo.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/acefei/dotfiles-mise/main/install.sh | sh
```

## Project layout

```
dotfiles/
├── mise.toml               # Tools, env vars, and simple tasks
├── install.sh              # Fresh-machine bootstrap entry point
├── lib/
│   └── utils.sh            # Shared bash helpers (is_mac, download, …)
├── shell/
│   ├── profile             # Interactive shell setup, sourced from ~/.bash_profile
│   ├── dynamic_source_all  # Sources every shell/_* file at login
│   ├── _aliases
│   ├── _functions
│   ├── _fzf
│   ├── _git
│   ├── _prompt
│   └── _worktree
├── config/
│   ├── mise/tools.toml     # Tools + env, linked to ~/.config/mise/config.toml
│   ├── git/                # gitconfig, gitignore_global
│   ├── tmux/               # tmux.conf
│   └── vim/                # vimrc, plug_installer
├── agents/
│   ├── claude/             # settings.json, hooks/
│   └── vscode/             # settings.json, keybindings.json, extensions.txt
├── utility/                # Scripts symlinked to ~/.local/bin
├── templates/              # Cloud-init and Docker starter files
├── docs/                   # Reference docs (git aliases, fzf, worktrees, skill workflow)
└── .mise/tasks/            # One executable script per setup-* task
```

Two mise files, on purpose: `config/mise/tools.toml` is your **global** config
(tools available in every directory), `mise.toml` holds this repo's **tasks**.

## Philosophy

**Tools** are anything `mise` can install and version-manage. **Tasks** are idempotent scripts that wire config files, generate completions, or do one-time setup steps that a package manager can't handle.

- Prefer a tool entry when: something has versioned releases and you want `mise install` / `mise upgrade` to manage it.
- Prefer a task when: setup is stateful (symlinking, building from source, writing config files) or needs OS-aware logic.
- Keep tasks idempotent — re-running `mise run bootstrap` on an existing machine should be safe.

## Your config files are included, not replaced

Setup never overwrites `~/.gitconfig`, `~/.tmux.conf`, `~/.vimrc`, `~/.bash_profile`,
`~/.bashrc` or `~/.claude/CLAUDE.md`. It appends **one line** to each, using that
format's own include directive:

```gitconfig
[include]                                   # ~/.gitconfig
	path = ~/dotfiles-mise/config/git/gitconfig
```
```tmux
source-file ~/dotfiles-mise/config/tmux/tmux.conf   # ~/.tmux.conf
```
```bash
source ~/dotfiles-mise/shell/profile                # ~/.bash_profile, ~/.bashrc
```

So anything you keep in those files survives, re-running `mise run bootstrap` adds
nothing twice, and editing a file in this repo takes effect immediately. Because the
include goes last, this repo's settings win — put machine-specific overrides *after*
it if you need the opposite.

Two formats have no include mechanism, so they stay copies: `~/.claude/settings.json`
(written only if absent) and the VSCode JSON files.

## Adding a tool

Add one line to `config/mise/tools.toml` under `[tools]`, then `mise install`:

```toml
[tools]
ripgrep = "latest"                    # built-in (mise registry)
"github:owner/repo" = "latest"        # any GitHub release binary
"npm:some-cli" = "latest"             # global npm package
```

## Adding a task

Write an executable script at `.mise/tasks/setup-foo` (no extension) and add
`"setup-foo"` to the `depends` list in `mise.toml`:

```bash
#!/usr/bin/env bash
#MISE description="Install foo config"
set -euo pipefail

install -m 644 "$MISE_PROJECT_ROOT/config/foo/foo.conf" "$HOME/.foo.conf"
```

`$MISE_PROJECT_ROOT` is this repo. Make it safe to re-run — `mise run bootstrap`
runs every task, and you should be able to run it any time.

## Running tasks

```bash
mise tasks                  # what's available
mise run setup-git          # just one
mise run bootstrap          # all of them, in parallel
```

## AI agent settings

`mise run setup-agents` sets up Claude Code and VSCode together. To change which
marketplaces, plugins, or skill packs you get, edit the lists at the top of
`.mise/tasks/setup-agents`.

### Claude Code plugins

One page each — what it's for, what to type, and what it costs you in context:

| Plugin | For | Context |
| --- | --- | --- |
| [ecc](docs/claude-plugin-ecc.md) | Breadth: reviewers, build fixers and language patterns for most stacks | **~24k tok** |
| [mattpocock-skills](docs/claude-plugin-mattpocock-skills.md) | Idea → spec → tickets → implementation, with grilling up front | ~1.2k tok |
| [accelerator-core](docs/claude-plugin-accelerator-core.md) | Speak replies aloud; safe remote work over SSH | ~190 tok |
| [accelerator-loops](docs/claude-plugin-accelerator-loops.md) | Long jobs that run to a checkable finish line | ~150 tok |

That context cost is paid in **every** session. `ecc` alone is most of it — read its
page before deciding to leave it enabled.

**VSCode** — settings, keybindings, and `extensions.txt` in `agents/vscode/`.

