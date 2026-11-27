#!/usr/bin/env bash

PI_AGENT_DIR="$HOME/.pi/agent"
PI_SEED_DIR="$MISE_PROJECT_ROOT/agents/pi"
PI_SEED="$PI_SEED_DIR/settings.json"

PI_PACKAGES=(
    "npm:pi-lens@4.5.2"
    "npm:pi-web-access@0.48.0"
    "npm:pi-subagents@0.90.0"
    "npm:@ff-labs/pi-fff@0.11.0"
    "npm:context-mode@2.2.4"
)

pi_seed() {
    install -d "$PI_AGENT_DIR"
    copy_once "$PI_SEED" "$PI_AGENT_DIR/settings.json"
    copy_once "$PI_SEED_DIR/pi-fff.json" "$PI_AGENT_DIR/pi-fff.json"
    link_config "$PI_SEED_DIR/lint/ruff.toml" "$HOME/ruff.toml"
    link_config "$PI_SEED_DIR/lint/shellcheckrc" "$HOME/.shellcheckrc"
    link_config "$PI_SEED_DIR/lint/editorconfig" "$HOME/.editorconfig"
}

pi_install_packages() {
    local installed pkg failed=""
    installed=$(pi list </dev/null 2>/dev/null | sed 's/^ *//' || true)
    for pkg in "${PI_PACKAGES[@]}"; do
        if grep -qxF "$pkg" <<<"$installed"; then
            echo "Pi package already installed: $pkg"
        elif pi install "$pkg" </dev/null; then
            :
        else
            echo "Pi package failed to install: $pkg" >&2
            failed="$failed $pkg"
        fi
    done
    if [[ -n "$failed" ]]; then
        echo "Failed:$failed" >&2
        return 1
    fi
    installed=$(pi list </dev/null 2>/dev/null | sed 's/^ *//' || true)
    for pkg in "${PI_PACKAGES[@]}"; do
        if ! grep -qxF "$pkg" <<<"$installed"; then
            echo "pi list does not show $pkg after the install: its output format may have changed" >&2
            failed="$failed $pkg"
        fi
    done
    [[ -z "$failed" ]]
}

pi_check_models() {
    if [[ "${CI:-}" != "true" && "${PI_TEST_MODELS:-}" != "1" ]]; then
        echo "Model tests skipped (they call the NVIDIA API once per model). Run them with PI_TEST_MODELS=1."
        return 0
    fi
    local run=() limit=()
    if command -v timeout &>/dev/null; then
        limit=(timeout 180)
    elif command -v gtimeout &>/dev/null; then
        limit=(gtimeout 180)
    fi
    local settings="$PI_AGENT_DIR/settings.json"
    [[ -f "$settings" ]] || settings="$PI_SEED"
    if [[ -n "${NVIDIA_API_KEY:-}" ]]; then
        echo "Testing the configured NVIDIA models (key from the environment)..."
    elif command -v secrets &>/dev/null && secrets get NVIDIA_API_KEY &>/dev/null; then
        echo "Testing the configured NVIDIA models (key from the secrets store)..."
        run=(secrets exec --)
    else
        echo "No NVIDIA_API_KEY in the environment or the secrets store, skipping the model tests."
        echo "Add one with: mise run setup-secrets"
        return 0
    fi
    if ! command -v jq &>/dev/null; then
        echo "jq not installed, skipping the model tests"
        return 0
    fi

    local model passed=0 failed=0 failures=""
    while IFS= read -r model; do
        echo "--- $model"
        if ${run[@]+"${run[@]}"} ${limit[@]+"${limit[@]}"} pi -p "Reply with OK." --no-session --no-extensions --model "$model" --thinking high </dev/null; then
            echo "PASS $model"
            passed=$((passed + 1))
        else
            echo "FAIL $model"
            failed=$((failed + 1))
            failures="$failures $model"
        fi
    done < <(jq -r '.enabledModels[]' "$settings")

    echo "Model tests: $passed passed, $failed failed"
    if [[ $failed -gt 0 ]]; then
        echo "Failed:$failures" >&2
        return 1
    fi
}

setup_pi() {
    if ! pi --version &>/dev/null; then
        skip_or_fail "Pi not installed (mise install), skipping Pi setup"
        return $?
    fi
    echo "Setting up the Pi coding agent ($(pi --version))..."
    pi_seed
    pi_install_packages || return 1
    pi_check_models
}
