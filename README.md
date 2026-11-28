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
│   ├── utils.sh                 # Shared bash helpers (is_mac, download, …)
│   └── agents/                  # One file per agent step of setup-agents
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
│   ├── herdr/                   # config.toml
│   ├── tmux/                    # tmux.conf
│   └── vim/                     # vimrc, plug_installer
├── agents/
│   ├── claude/                  # settings.json, CLAUDE.md
│   ├── pi/                      # settings.json, pi-fff.json, lint/ (ruff, shellcheck, editorconfig)
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

`secrets export --format dotenv` writes the store as a `.env` file and `secrets import FILE` reads one
back, so a store moves between machines without retyping. `secrets exec` reads the store directly, so
nothing is injected into your shell just by entering a directory. Full reference: [docs/secrets.md](docs/secrets.md).

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

`mise run setup-agents` is the one task for every agent. It runs these steps in order and
reports each step that failed, but always runs the audit last:

| Step | Source | What it does |
| --- | --- | --- |
| VSCode | `lib/agents/vscode.sh`, `agents/vscode/` | Seeds settings and keybindings once, installs the extensions |
| Claude Code | `lib/agents/claude.sh`, `agents/claude/` | Seeds settings, links `CLAUDE.md`, registers the marketplace, installs the plugins |
| Pi | `lib/agents/pi.sh`, `agents/pi/` | Seeds settings, links the lint files, installs the extensions, tests the models |
| Skills | `lib/agents/skills.sh` | Installs standalone skills for the agents each entry names |
| Audit | `lib/agents/audit.sh` | Reports a skill installed twice for one agent |

A tool that is not installed is skipped with a message, except in CI (`CI=true`), where a missing
Claude Code, Pi or Herdr fails the task. Change what gets installed by editing the
lists at the top of the matching file: `CLAUDE_MARKETPLACES` and `CLAUDE_PLUGINS`, `PI_PACKAGES`,
`SKILL_SETS`. The task depends on `setup-secrets`, which asks for the NVIDIA key (see Pi).

### Claude Code plugins (from `acefei/agent-accelerator`)

| Plugin | For | Context |
| --- | --- | --- |
| `mattpocock-skills` | Idea → spec → tickets → implementation, with grilling up front | ~1.2k tok |
| `accelerator-core` | Speak replies aloud; safe remote work over SSH | ~190 tok |
| `accelerator-loops` | Long jobs that run to a checkable finish line | ~150 tok |
| `simple-english` | ASD-STE100 writing skill + `simple-english` output style | ~150 tok |
| `gh-skills` | `gh` and `gh-skill` skills from `cli/cli` | ~90 tok |

Context cost is paid in **every** session. Run `claude plugin details <plugin>` for the current
figure before you add a plugin. Plugins go to Claude Code only. `claude` comes from
`config/mise/tools.toml`; when mise installs it without its postinstall, the task runs the
postinstall once. Claude Code rewrites `settings.json`, so it is seeded once. A `CLAUDE.md` you
already have keeps its text and gets one `@import` line for the repo file.

### Pi Coding Agent (NVIDIA NIM)

[Pi](https://github.com/earendil-works/pi) comes from `config/mise/tools.toml` (`mise install`).
The Pi step seeds `~/.pi/agent/settings.json` and `pi-fff.json` once from `agents/pi/`, installs the
extensions, and tests every model in `enabledModels` when a key is available. Pi rewrites its settings
file itself (`/model`, `/settings`), so the task never overwrites it. To take a new model list from the
repo, delete `~/.pi/agent/settings.json` and run the task again.

| Setting | Value | Why |
| --- | --- | --- |
| `defaultModel` | `nvidia/nemotron-3-ultra-550b-a55b` | The largest free model (550B, 1M context) |
| `enabledModels` | the two free Nemotron models of build.nvidia.com (Ultra and Super VL), `moonshotai/kimi-k3.1-pro`, and `minimaxai/minimax-m3.1-flash` | Cycle with Ctrl+P |
| `defaultThinkingLevel` | `high` | Pi's default is `medium` |

NVIDIA serves `moonshotai/kimi-k3.1-pro`, but Pi's built-in catalog does not list it yet. Pi
then uses it as a custom model id: it prints `No models match pattern` at start, and Ctrl+P does
not cycle to it. `--model nvidia/moonshotai/kimi-k3.1-pro` and the model tests work. The warning
goes away when Pi's catalog has the model.

Pi sends no thinking parameter to NVIDIA models (checked with a local test server: the request
is the same at `medium` and `high`), so the level changes what Pi shows and allows, not the
request. The models reason on their own.

The key comes from one of two places:

- **The environment**: `NVIDIA_API_KEY`. Use it in CI or for a one-off run.
- **The secrets store**: `mise run setup-secrets` asks for the key (input hidden) and stores
  it. The first `secrets init` makes you type `BACKED-UP`, so this step needs a terminal.

The model tests call the NVIDIA API once per model, so they run only in CI or with `PI_TEST_MODELS=1`, each
with a 180 s limit where `timeout` exists. They test the models in your effective `~/.pi/agent/settings.json`,
print `PASS` or `FAIL` per model, and fail if one model fails; with no key they are skipped. Run Pi with the
stored key: `secrets exec -- pi`.

#### Extensions

The list is `PI_PACKAGES` in `lib/agents/pi.sh`. The versions are exact. Each package runs code
inside Pi, so read a package before you raise its version.

| Package | For |
| --- | --- |
| `pi-lens` | Diagnostics from language servers and linters after each edit; blockers must be fixed first |
| `pi-web-access` | Web search, URL fetch, PDF and YouTube; keyless search unless you add a provider key to `~/.pi/agent/web-search.json` |
| `pi-subagents` | Delegate work to sub-agents |
| `@ff-labs/pi-fff` | Fast fuzzy file and content search; the seed turns off scanning of the whole home folder |
| `context-mode` | Saves context window (license: Elastic-2.0, not an OSI open-source license) |

All except the `pi-fff` seed run with their defaults. npm 11 holds back the install script of the
dependency `@ast-grep/cli`; Pi still starts. In Pi, `/lens-tools` shows which tools `pi-lens` found.

#### Lint config for pi-lens

`pi-lens` installs `shellcheck` and `shfmt` itself (downloaded to `~/.pi-lens/bin`), so
`config/mise/tools.toml` does not list them. It cannot install `ruff` on Ubuntu: its private venv has no
`pip`, and `pipx` does not help (both checked on Ubuntu 26.04). So `ruff` comes from the tools file, and
`pi-lens` uses the one on the PATH.

`pi-lens` looks for `ruff.toml`, `.shellcheckrc` and `.editorconfig` from the edited file up to and
including `$HOME`, and uses its own rules only when it finds none. The Pi step therefore links three
files from `agents/pi/lint/` into your home folder, and they apply to every project under it that
has no file of its own:

| Home file | From | Rules |
| --- | --- | --- |
| `~/ruff.toml` | `agents/pi/lint/ruff.toml` | The `[tool.ruff]` rules of `acefei/xenserver-mcp` (`pyproject.toml`; no repo of `acefei` has a `ruff.toml` file), without `target-version` and `UP`: the pi-lens autofix would otherwise rewrite old-Python code (for example `Optional[int]` to `int \| None`) in every repo that has no config of its own. Put modernizing rules in the repos that target a new Python |
| `~/.shellcheckrc` | `agents/pi/lint/shellcheckrc` | bash, follow `source` |
| `~/.editorconfig` | `agents/pi/lint/editorconfig` | Shell scripts only (`*.sh`, `*.bash`): utf-8, LF, final newline, 4 spaces, for `shfmt`. No catch-all section, so editors do not reformat patches or tab-indented code in other repos |

### Skills (Claude Code + Pi)

Standalone skills come from the pinned [`skills`](https://github.com/vercel-labs/skills) CLI, once per
entry in `SKILL_SETS` (`lib/agents/skills.sh`). Each entry is `"<agents> <repo>@<commit> <skill> ..."`,
where `agents` is `claude-code`, `pi`, or `claude-code,pi`; the commit pins the content. Each skill is on
disk once, in `~/.agents/skills` (Pi reads it), and `~/.claude/skills` links to the same folders. The
CLI telemetry is turned off. The default entry gives `grilling` and `grill-me` to Pi only, because Claude
already gets them from the `mattpocock-skills` plugin.

### Skill audit

The last step lists a skill that is installed twice. It judges per agent, because an agent loads only its
own folders (Claude: `~/.claude/skills` and enabled plugins; Pi: `~/.agents/skills` and Pi packages). It
reports a skill name in two different folders for **one** agent, for example a standalone skill that a
Claude plugin also ships. Symlinks to the same folder are not duplicates. The same skill once for Claude
(plugin) and once for Pi is only a note, because each agent needs its own copy. The audit runs on every
`setup-agents`. A duplicate fails the task in CI (`CI=true`) and only warns on your own machine, so a skill you
installed by hand does not block the setup.

### Herdr: the workspace for parallel agents

[Herdr](https://herdr.dev) is a terminal workspace that shows many coding agents side by side and
tells you which one waits for you. `mise run setup-herdr` runs after `setup-agents`. It links
`config/herdr/config.toml` to `~/.config/herdr/`, checks it with `herdr config check`, and installs the
Herdr integrations for Pi and Claude Code (a Pi extension and a Claude hook, so both report working,
idle or blocked). You start Herdr yourself with `herdr`.

| Key | Value | Why |
| --- | --- | --- |
| `theme.name` | `tokyo-night` | Dark theme |
| `update.version_check` | `false` | mise installs and updates Herdr; `herdr update` would fight it |
| `ui.agent_panel_sort` | `priority` | Agents that wait for you come first in the sidebar |
| `ui.status_indicators` | `symbols` | A distinct symbol per agent state |
| `session.resume_agents_on_restore` | `true` | Reopen Pi and Claude Code panes in their own conversation after a restart |
| `experimental.pane_history` | `false` | Pane history on disk can hold secrets |

For one task per branch, `herdr worktree create --cwd <repo> --branch <name>` makes a git worktree and a
workspace for it, so your main checkout stays untouched; `herdr worktree remove` cleans up. `herdr --help`
and `herdr --default-config` list every command and key.

## Development

```bash
mise run bootstrap          # Full setup
mise run setup-agents       # VSCode, Claude Code, Pi, skills, audit
mise run setup-herdr        # Herdr config and integrations
```