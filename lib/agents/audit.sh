#!/usr/bin/env bash

audit_hash_file() {
    if command -v sha256sum &>/dev/null; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

audit_skill_name() {
    local name
    name=$(awk 'NR == 1 && $0 != "---" { exit }
                NR > 1 && $0 == "---" { exit }
                /^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }' "$1/SKILL.md" | tr -d "\"'")
    printf '%s' "${name:-$(basename "$1")}"
}

audit_add_skill() {
    local label=$1 dir=${2%/} real
    [[ -f "$dir/SKILL.md" ]] || return 0
    real=$(cd "$dir" && pwd -P)
    printf '%s\t%s\t%s\t%s\n' "$label" "$(audit_skill_name "$dir")" "$(audit_hash_file "$dir/SKILL.md")" "$real" >>"$AUDIT_ROWS"
}

audit_add_children() {
    local label=$1 base=$2 dir
    [[ -d "$base" ]] || return 0
    for dir in "$base"/*/; do
        audit_add_skill "$label" "$dir"
    done
}

audit_claude_plugins() {
    if ! command -v claude &>/dev/null || ! command -v jq &>/dev/null; then
        echo "claude or jq not found: Claude plugin skills are not audited"
        return 0
    fi
    local id path manifest skill
    while IFS=$'\t' read -r id path; do
        manifest="$path/.claude-plugin/plugin.json"
        if [[ -f "$manifest" ]] && [[ -n "$(jq -r '.skills[]? // empty' "$manifest")" ]]; then
            while IFS= read -r skill; do
                audit_add_skill "claude-plugin:$id" "$path/${skill#./}"
            done < <(jq -r '.skills[]?' "$manifest")
        else
            audit_add_children "claude-plugin:$id" "$path/skills"
        fi
    done < <(claude plugin list --json 2>/dev/null \
        | jq -r '.[] | select(.enabled == true and ((.installPath // "") != "")) | [.id, .installPath] | @tsv')
}

audit_pi_packages() {
    command -v pi &>/dev/null || return 0
    local path
    while IFS= read -r path; do
        audit_add_children "pi-package:$(basename "$path")" "$path/skills"
    done < <(pi list </dev/null 2>/dev/null | sed -n 's/^    \(\/.*\)$/\1/p')
}

audit_report() {
    local total folders dups
    total=$(wc -l <"$AUDIT_ROWS" | tr -d ' ')
    folders=$(cut -f4 "$AUDIT_ROWS" | sort -u | wc -l | tr -d ' ')

    awk -F'\t' 'BEGIN { OFS = "\t" }
        { a = ($1 ~ /^(claude-)/) ? "claude" : "pi"; print $0, a }' "$AUDIT_ROWS" >"$AUDIT_ROWS.agent"

    sort -t$'\t' -k5,5 -k2,2 -k4,4 "$AUDIT_ROWS.agent" | awk -F'\t' '
        function flush(   i) {
            if (n > 1) {
                dup++
                printf "DUPLICATE for %s: %s\n", agent, cur
                for (i = 1; i <= n; i++) printf "    %s\n      %s  sha256:%s\n", lab[i], dir[i], substr(h[i], 1, 12)
            }
            n = 0
        }
        {
            key = $5 SUBSEP $2
            if (key != curkey) { flush(); curkey = key; cur = $2; agent = $5 }
            if (n > 0 && dir[n] == $4) lab[n] = lab[n] ", " $1
            else { n++; lab[n] = $1; dir[n] = $4; h[n] = $3 }
        }
        END { flush(); print "SUMMARY " dup + 0 }' >"$AUDIT_ROWS.names"

    sort -t$'\t' -k2,2 "$AUDIT_ROWS.agent" | awk -F'\t' '
        function note() { if (nd > 1 && na > 1) printf "NOTE: %s is on disk once per agent (claude and pi each need their own copy)\n", cur }
        $2 != cur { note(); cur = $2; nd = 0; na = 0; sd = ""; sa = "" }
        {
            if (index(sd, "|" $4 "|") == 0) { nd++; sd = sd "|" $4 "|" }
            if (index(sa, "|" $5 "|") == 0) { na++; sa = sa "|" $5 "|" }
        }
        END { note() }' >"$AUDIT_ROWS.notes"

    grep -v '^SUMMARY ' "$AUDIT_ROWS.names" || true
    cat "$AUDIT_ROWS.notes"
    dups=$(awk '/^SUMMARY / { print $2 }' "$AUDIT_ROWS.names")
    echo "Skill audit: $total skill entries in $folders folders, $dups duplicate group(s)"
    if [[ "$dups" -gt 0 ]]; then
        echo "Remove one copy: a SKILL_SETS entry in lib/agents/skills.sh, or a plugin in lib/agents/claude.sh."
        return 1
    fi
    return 0
}

audit_skills() {
    AUDIT_ROWS=$(mktemp)
    audit_add_children "claude-skills" "$HOME/.claude/skills"
    audit_add_children "agents-skills" "$HOME/.agents/skills"
    audit_claude_plugins
    audit_pi_packages

    local status=0
    audit_report || status=1
    rm -f "$AUDIT_ROWS" "$AUDIT_ROWS.agent" "$AUDIT_ROWS.names" "$AUDIT_ROWS.notes"
    return "$status"
}
