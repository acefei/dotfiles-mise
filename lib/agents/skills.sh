#!/usr/bin/env bash

SKILLS_CLI="skills@1.9.1"

SKILL_SETS=(
    "pi mattpocock/skills@49dd158d1076134a641b33efb035946536778336 grilling grill-me"
)

install_skill_set() {
    local agents source names rest name agent
    agents=${1%% *}
    rest=${1#* }
    source=${rest%% *}
    names=${rest#* }
    local args=()
    for name in $names; do
        args+=(--skill "$name")
    done
    for agent in ${agents//,/ }; do
        args+=(-a "$agent")
    done
    echo "Installing skills from $source for $agents: $names"
    DISABLE_TELEMETRY=1 DO_NOT_TRACK=1 npx --yes "$SKILLS_CLI" add "$source" "${args[@]}" -g -y </dev/null
}

setup_skills() {
    if ! command -v npx &>/dev/null; then
        echo "npx not found, skipping skills"
        return 0
    fi
    local entry failed=""
    for entry in "${SKILL_SETS[@]}"; do
        install_skill_set "$entry" || failed="$failed $(cut -d' ' -f2 <<<"$entry")"
    done
    if [[ -n "$failed" ]]; then
        echo "Failed to install skills from:$failed" >&2
        return 1
    fi
    echo "Skills installed"
}
