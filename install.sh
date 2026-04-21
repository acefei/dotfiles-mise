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

# ── 1. Ensure build essentials are available ────────────────────────────────
# mise and some tools need a C toolchain and `make` to build/install.
missing=""
for cmd in make cc; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        # Allow gcc/clang to satisfy cc.
        if [ "$cmd" = "cc" ] && (command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1); then
            continue
        fi
        missing="$missing $cmd"
    fi
done
if [ -n "$missing" ]; then
    echo "Missing required build tools:$missing"
    case "$(uname -s)" in
        Darwin)
            echo "Install them with: xcode-select --install"
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                echo "Install them with: sudo apt-get update && sudo apt-get install -y build-essential"
            elif command -v dnf >/dev/null 2>&1; then
                echo "Install them with: sudo dnf groupinstall -y 'Development Tools'"
            elif command -v yum >/dev/null 2>&1; then
                echo "Install them with: sudo yum groupinstall -y 'Development Tools'"
            elif command -v apk >/dev/null 2>&1; then
                echo "Install them with: sudo apk add --no-cache build-base"
            elif command -v pacman >/dev/null 2>&1; then
                echo "Install them with: sudo pacman -Sy --noconfirm base-devel"
            fi
            ;;
    esac
    echo "Please install the missing tools and re-run this script."
    exit 1
fi

# ── 2. Install mise if missing ──────────────────────────────────────────────
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$MISE_BIN" ]; then
    echo "Installing mise..."
    curl -sSL https://mise.run | sh >/dev/null 2>&1
fi

# Ensure mise is in PATH for the rest of this script
export PATH="$HOME/.local/bin:$PATH"

# ── 3. Resolve dotfiles directory (supports curl | sh) ─────
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

# ── 4. Symlink mise.toml as global config so tools are active everywhere ────
mkdir -p "$HOME/.config/mise"
ln -sf "$DOTFILES_DIR/mise.toml" "$HOME/.config/mise/config.toml"

# ── 5. Trust and install from resolved repo ─────────────────────────────────
cd "$DOTFILES_DIR"
mise trust -y -a

# ── 6. Normalize mise task permissions ──────────────────────────────────────
if [ -d "$DOTFILES_DIR/.mise/tasks" ]; then
    chmod 755 "$DOTFILES_DIR/.mise/tasks"
    find "$DOTFILES_DIR/.mise/tasks" -type f -exec chmod 755 {} +
fi

# ── 7. Ensure a GitHub token is available for mise ──────────────────────────
# mise hits the GitHub API to list/download many tools; without auth it can hit
# rate limits and fail with 403. Priority follows mise's own resolution order:
# https://mise.jdx.dev/dev-tools/github-tokens.html
if [ -z "${MISE_GITHUB_TOKEN:-}" ] \
    && [ -z "${GITHUB_API_TOKEN:-}" ] \
    && [ -z "${GITHUB_TOKEN:-}" ]; then
    if ! command -v gh >/dev/null 2>&1; then
        echo "Installing gh CLI via mise..."
        mise install gh
    fi
    GH_BIN="$(mise which gh 2>/dev/null || command -v gh || true)"
    if [ -n "$GH_BIN" ]; then
        if ! "$GH_BIN" auth status >/dev/null 2>&1; then
            echo "Authenticating gh CLI (needed for GitHub-backed mise tools)..."
            "$GH_BIN" auth login -h github.com -p https -w
        fi
        GITHUB_TOKEN="$("$GH_BIN" auth token 2>/dev/null || true)"
        if [ -n "$GITHUB_TOKEN" ]; then
            export GITHUB_TOKEN
        fi
    fi
fi

# ── 8. Install all tools declared in mise.toml ──────────────────────────────
echo "Installing tools..."
mise install

# ── 9. Run the full bootstrap task ──────────────────────────────────────────
echo "Running bootstrap..."
mise run bootstrap
