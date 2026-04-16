#!/usr/bin/env sh
# install.sh — Bootstrap a fresh machine from scratch.
# Installs mise (rootless), then runs: mise run bootstrap
# Usage:
#   sh install.sh
#   bash install.sh
#   curl -fsSL <raw-install-url> | sh
set -eu

MISE_BIN="$HOME/.local/bin/mise"
DEFAULT_REPO_URL="https://github.com/acefei/dotfiles-mise.git"
DEFAULT_DOTFILES_DIR="$HOME/dotfiles-mise"

# ── 1. Install mise if missing ──────────────────────────────────────────────
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$MISE_BIN" ]; then
    echo "Installing mise..."
    curl -sSL https://mise.run | sh >/dev/null 2>&1
fi

# Ensure mise is in PATH for the rest of this script
export PATH="$HOME/.local/bin:$PATH"

# ── 2. Resolve dotfiles directory (supports curl | sh) ─────
# When piped from stdin, $0 is usually "sh"; fall back to cloning.
SCRIPT_DIR=""
case "$0" in
    */*)
        if [ -f "$0" ]; then
            SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        fi
        ;;
esac

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/mise.toml" ]; then
    DOTFILES_DIR="$SCRIPT_DIR"
else
    DOTFILES_DIR="${DOTFILES_DIR:-$DEFAULT_DOTFILES_DIR}"
    REPO_URL="${DOTFILES_REPO:-$DEFAULT_REPO_URL}"

    if [ ! -f "$DOTFILES_DIR/mise.toml" ]; then
        echo "Cloning dotfiles repo to $DOTFILES_DIR..."
        git clone -q --depth=1 --single-branch "$REPO_URL" "$DOTFILES_DIR"
    fi
fi

# ── 3. Symlink mise.toml as global config so tools are active everywhere ────
mkdir -p "$HOME/.config/mise"
ln -sf "$DOTFILES_DIR/mise.toml" "$HOME/.config/mise/config.toml"

# ── 4. Trust and install from resolved repo ─────────────────────────────────
cd "$DOTFILES_DIR"
mise trust -y -a

# ── 5. Install all tools declared in mise.toml ─────────────────────────────
echo "Installing tools..."
mise install

# ── 6. Run the full bootstrap task ─────────────────────────────────────────
echo "Running bootstrap..."
mise run bootstrap
