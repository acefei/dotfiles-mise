#!/usr/bin/env bash

CLAUDE_MARKETPLACES=(
    "acefei/agent-accelerator"
)

CLAUDE_PLUGINS=(
    "accelerator-core@agent-accelerator"
    "accelerator-loops@agent-accelerator"
    "mattpocock-skills@agent-accelerator"
    "simple-english@agent-accelerator"
    "gh-skills@agent-accelerator"
)

ensure_claude_runnable() {
    claude --version &>/dev/null && return 0
    command -v claude &>/dev/null || return 1

    local where postinstall
    where=$(mise where "npm:@anthropic-ai/claude-code" 2>/dev/null) || return 1
    postinstall="$where/node_modules/@anthropic-ai/claude-code/install.cjs"
    [[ -f "$postinstall" ]] || return 1

    echo "Claude Code is installed but not runnable; running its postinstall"
    node "$postinstall" >/dev/null 2>&1 \
        || mise exec -- node "$postinstall" >/dev/null 2>&1 \
        || true

    claude --version &>/dev/null
}

setup_claude() {
    if ! ensure_claude_runnable; then
        echo "Claude Code CLI not available or not runnable, skipping Claude setup"
        return 0
    fi

    local claude_dir="$HOME/.claude"
    install -d "$claude_dir"

    copy_once "$MISE_PROJECT_ROOT/agents/claude/settings.json" "$claude_dir/settings.json"

    local claude_md="$claude_dir/CLAUDE.md"
    local repo_claude_md="$MISE_PROJECT_ROOT/agents/claude/CLAUDE.md"
    if [[ -e "$claude_md" && ! -L "$claude_md" ]]; then
        if grep -qF "@$repo_claude_md" "$claude_md"; then
            echo "Claude CLAUDE.md already imports the repo file"
        else
            printf '\n@%s\n' "$repo_claude_md" >> "$claude_md"
            echo "Imported the repo CLAUDE.md from your existing $claude_md"
        fi
    else
        link_config "$repo_claude_md" "$claude_md"
    fi

    local marketplace plugin marketplace_name

    for marketplace in "${CLAUDE_MARKETPLACES[@]}"; do
        echo "Registering Claude plugin marketplace: $marketplace"
        marketplace_name=$(printf '%s' "${marketplace##*/}" | tr '[:upper:]' '[:lower:]')
        claude plugin marketplace add "$marketplace" \
            || claude plugin marketplace update "$marketplace_name" \
            || true
    done

    for plugin in "${CLAUDE_PLUGINS[@]}"; do
        echo "Installing Claude plugin: $plugin"
        claude plugin install "$plugin" \
            || echo "Plugin install failed for $plugin, continuing"
    done
}
