# dotfiles

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
│   ├── dynamic_source_all  # Sources every shell/_* file at login
│   ├── _aliases
│   ├── _functions
│   ├── _fzf
│   ├── _git
│   ├── _prompt
│   └── _worktree
├── config/
│   ├── git/                # gitconfig, gitignore_global
│   ├── tmux/               # tmux.conf
│   └── vim/                # vimrc, plug_installer
├── agents/
│   ├── claude/             # settings.json, hooks/
│   └── vscode/             # settings.json, keybindings.json, extensions.txt
├── utility/                # Scripts symlinked to ~/.local/bin
├── templates/              # Cloud-init and Docker starter files
├── docs/                   # Reference docs (git aliases, fzf, worktrees)
└── .mise/tasks/            # Complex setup scripts (OS detection, loops, etc.)
```

## Philosophy

**Tools** are anything `mise` can install and version-manage. **Tasks** are idempotent scripts that wire config files, generate completions, or do one-time setup steps that a package manager can't handle.

- Prefer a tool entry when: something has versioned releases and you want `mise install` / `mise upgrade` to manage it.
- Prefer a task when: setup is stateful (symlinking, building from source, writing config files) or needs OS-aware logic.
- Keep tasks idempotent — re-running `mise run bootstrap` on an existing machine should be safe.

## Adding a tool

Add one line to `mise.toml` under `[tools]`:

```toml
[tools]
ripgrep = "latest"                    # built-in (mise registry)
"github:owner/repo" = "latest"        # any GitHub release binary
```

Then run `mise install`.

## Adding a task

Simple one-liners go inline in `mise.toml`:

```toml
[tasks.setup-foo]
description = "Symlink foo config"
run = "ln -sf $MISE_PROJECT_ROOT/config/foo/foo.conf ~/.foo.conf"
```

Tasks with OS detection, loops, or multiple steps go in `.mise/tasks/setup-foo` (executable script, no extension). Add the task name to the `depends` list under `[tasks.bootstrap]`.

## Running individual tasks

```bash
mise run setup-git
mise run setup-vscode
mise run bootstrap          # runs all tasks
```

## AI agent settings

- **Claude Code**: settings and hooks live in `agents/claude/`. The `setup-claude` task symlinks them to `~/.claude/`.
- **VSCode**: settings, keybindings, and extension list live in `agents/vscode/`. The `setup-vscode` task symlinks them and installs extensions.
- **skillfile**: Install `skillfile` from `github:eljulians/skillfile` (already in `mise.toml`). Configure a `Skillfile` in this repo to manage AI skills across agents.

