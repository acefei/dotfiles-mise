# dotfiles

[![Installation on Various OS](https://github.com/acefei/dotfiles-mise/actions/workflows/test-install.yml/badge.svg?branch=main)](https://github.com/acefei/dotfiles-mise/actions/workflows/test-install.yml)

Personal development environment for Linux and macOS, managed by [mise](https://mise.jdx.dev). Rootless - nothing requires sudo.

## Quick start

```bash
# Full bootstrap (interactive, prompts for NVIDIA API key)
curl -fsSL https://raw.githubusercontent.com/acefei/dotfiles-mise/main/install.sh | sh

# GitHub Actions / CI: pre-set NVIDIA_API_KEY env var
export NVIDIA_API_KEY=<your key>
curl -fsSL https://raw.githubusercontent.com/acefei/dotfiles-mise/main/install.sh | sh
```

## Project layout

```
dotfiles/
├── mise.toml                    # Tools, env vars, and simple tasks
├── install.sh                   # Fresh-machine bootstrap entry point
├── lib/
│   └── utils.sh                 # Shared bash helpers (is_mac, download, …)
├── shell/
│   ├── profile                  # Interactive shell setup, sourced from ~/.bash_profile
│   ├── dynamic_source_all       # Sources every shell/_* file at login
│   ├── _aliases
│   ├── _functions
│   ├── _fzf
│   ├── _git
│   ├── _prompt
│   └── _worktree
├── config/
│   ├── mise/tools.toml          # Tools + env, linked to ~/.config/mise/config.toml
│   ├── git/                     # gitconfig, gitignore_global
│   ├── tmux/                    # tmux.conf
│   └── vim/                     # vimrc, plug_installer
├── agents/
│   ├── claude/                  # settings.json, CLAUDE.md
│   ├── pi/                      # settings.json (seed for the Pi agent)
│   └── vscode/                  # settings.json, keybindings.json, extensions.txt
├── utility/                     # Scripts symlinked to ~/.local/bin
├── templates/                   # Cloud-init and Docker starter files
├── docs/                        # Reference docs (git aliases, fzf, worktrees, secrets)
└── .mise/tasks/                 # One executable script per setup-* task
```

Two mise files, on purpose: `config/mise/tools.toml` is your **global** config
(tools available in every directory), `mise.toml` holds this repo's **tasks**.

## Secrets

Tokens live in one sops-encrypted JSON file, with age as the key. The store is
safe to commit; the key is not, and lives outside every repo.

```bash
secrets init                  # create the key; it makes you confirm the backup
secrets set GITHUB_TOKEN      # prompts, input hidden
secrets exec -- claude        # only that process sees the values
```

`secrets exec` reads the store directly, so nothing is injected into your shell
just by entering a directory. Full reference: [docs/secrets.md](docs/secrets.md).

## Philosophy

**Tools** are anything `mise` can install and version-manage. **Tasks** are idempotent scripts that wire config files, generate completions, or do one-time setup steps that a package manager can't handle.

- Prefer a tool entry when: something has versioned releases and you want `mise install` / `mise upgrade` to manage it.
- Prefer a task when: setup is stateful (symlinking, building from source, writing config files) or needs OS-aware logic.
- Keep tasks idempotent — re-running `mise run bootstrap` on an existing machine should be safe.

### Link, include, or copy

How a config file is installed depends on **who writes it**, not on how often you
change it.

| Who writes it | How it is installed | Examples |
|---|---|---|
| Only you | **Symlink** — edit it in the repo and the change is live at once; `git status` here is the whole drift report | `tmux.conf`, `vimrc`, `gitignore_global`, `utility/*`, `mise/tools.toml` |
| You **and** a tool | **Include** — one line in a machine-local file pulls in the repo file, so the tool writes locally and the repo stays clean | `~/.gitconfig`, `~/.bash_profile`, `~/.bashrc` |
| Mostly the tool | **Copy once, never clobber** — the repo file is a seed, drift is expected | Claude `settings.json`, VSCode `settings.json` / `keybindings.json`, Pi `settings.json` |
| You already have your own | **Adopt** — keep what is there and attach the repo's beside it | existing `~/.claude/CLAUDE.md`, `~/.pi/agent/AGENTS.md` |

Never symlink a file a tool rewrites. `git config --global` in particular writes
*through* a symlink, so a linked `~/.gitconfig` would put machine-local values in
this repo.

An include is a single appended line in that format's own directive, so whatever
else you keep in the file survives and a re-run never adds it twice:

```gitconfig
[include]                                    # ~/.gitconfig
	path = ~/dotfiles-mise/config/git/gitconfig
```
```bash
source ~/dotfiles-mise/shell/profile         # ~/.bash_profile, ~/.bashrc
```

Because the include goes last, this repo's settings win — put machine-specific
overrides *after* it if you need the opposite.

Adoption is what the last row means: an existing `~/.claude/CLAUDE.md` gets an
`@import` of the repo file appended. Whatever was there is kept. Anything replaced is moved to `<file>.backup` exactly
once — a second run never overwrites the first backup.

`lib/utils.sh` holds one helper per strategy: `link_config`, `ensure_line`,
`copy_once`, and `backup_once` beneath them.

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

### Claude Code + VSCode

`mise run setup-agents` sets up Claude Code and VSCode together. To change which
marketplaces or plugins you get, edit the lists at the top of
`.mise/tasks/setup-agents`.

#### Claude Code plugins (from `acefei/agent-accelerator`)

| Plugin | For | Context |
| --- | --- | --- |
| `mattpocock-skills` | Idea → spec → tickets → implementation, with grilling up front | ~1.2k tok |
| `accelerator-core` | Speak replies aloud; safe remote work over SSH | ~190 tok |
| `accelerator-loops` | Long jobs that run to a checkable finish line | ~150 tok |
| `simple-english` | ASD-STE100 writing skill + `simple-english` output style | ~150 tok |
| `gh-skills` | `gh` and `gh-skill` skills from `cli/cli` | ~90 tok |

Context cost is paid in **every** session — run `claude plugin details <plugin>`
for the current figure before you add a plugin.

**VSCode** — settings, keybindings, and `extensions.txt` in `agents/vscode/`.

### Pi Coding Agent (NVIDIA NIM)

`mise run setup-pi` installs [Pi](https://github.com/earendil-works/pi) if it is missing,
seeds `~/.pi/agent/settings.json` and `models.json` once from `agents/pi/`, and tests every model
in its `enabledModels` when a key is available. Pi rewrites its settings file itself
(`/model`, `/settings`), so the task never overwrites it. To take a new model list from the
repo, delete `~/.pi/agent/settings.json` and run the task again.

| Setting | Value | Why |
| --- | --- | --- |
| `defaultModel` | `nvidia/nemotron-3-ultra-550b-a55b` | The largest free model (550B, 1M context) |
| `enabledModels` | the two free Nemotron models of build.nvidia.com (Ultra and Super VL), `moonshotai/kimi-k3.1-pro`, `minimaxai/minimax-m3.1-flash`, and `z-ai/glm-5.3-flash` | Cycle with Ctrl+P |
| `defaultThinkingLevel` | `high` | Pi's default is `medium` |

`agents/pi/models.json` adds Kimi K3.1 Pro, which is not in Pi's built-in catalog yet. It sets
only the id and the name, so Pi's defaults apply: 128k context, 16k output tokens, no reasoning
flag. Remove the entry when Pi's catalog has the model.

Pi sends no thinking parameter to NVIDIA models (checked with a local test server: the request
is the same at `medium` and `high`), so the level changes what Pi shows and allows, not the
request. The models reason on their own.

#### Extensions

`setup-pi` installs these Pi packages (the list `PI_PACKAGES` at the top of
`.mise/tasks/setup-pi`). The versions are exact. Each package runs code inside Pi, so read a
package before you raise its version.

| Package | For |
| --- | --- |
| `pi-lens` | Diagnostics from language servers and linters after each edit; blockers must be fixed first |
| `pi-web-access` | Web search, URL fetch, PDF and YouTube |
| `pi-subagents` | Delegate work to sub-agents |
| `@ff-labs/pi-fff` | Fast fuzzy file and content search |
| `context-mode` | Saves context window (license: Elastic-2.0, not an OSI open-source license) |

npm 11 holds back the install script of the dependency `@ast-grep/cli`. Pi still starts. In
Pi, `/lens-tools` shows which tools `pi-lens` found.

The key comes from one of two places:

- **The environment**: `NVIDIA_API_KEY`. Use it in CI or for a one-off run.
- **The secrets store**: `mise run setup-secrets` asks for the key (input hidden) and stores
  it. The first `secrets init` makes you type `BACKED-UP`, so this step needs a terminal.

With no key, `setup-pi` skips the model tests and still succeeds. With a key, it prints
`PASS` or `FAIL` for each model and fails if one model fails.

```bash
mise run setup-secrets      # store the key (asks on a terminal)
mise run setup-pi           # install Pi, seed settings, test the models
secrets exec -- pi          # run Pi with the key from the store
```

## Development

```bash
mise run bootstrap          # Full setup
mise run setup-pi           # Pi only
mise run setup-agents       # Claude + VSCode only
```