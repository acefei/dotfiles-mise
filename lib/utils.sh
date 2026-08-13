#!/usr/bin/env bash

is_mac() {
    [[ "$OSTYPE" == "darwin"* ]]
}

run_quiet() {
    local log_file
    log_file=$(mktemp)
    if "$@" >"$log_file" 2>&1; then
        rm -f "$log_file"
        return 0
    fi

    local status=$?
    cat "$log_file" >&2
    rm -f "$log_file"
    return "$status"
}

download() {
    local url=$1
    local dest=${2:-}
    if [[ -n "$dest" ]]; then
        curl -sSL -o "$dest" "$url"
    else
        curl -sSLO "$url"
    fi
}

work_in_temp_dir() {
    # DON'T set tempdir to local variable!
    tempdir=$(mktemp -d)
    cd "$tempdir"
    trap 'rm -rf "$tempdir"' EXIT
}

# Append a line to a file unless it is already there. Creates the file if
# missing and never rewrites what is already in it, so your own edits survive
# every re-run. This is how config files get wired to this repo: one include
# line, rather than replacing the file.
ensure_line() {
    local line=$1 file=$2
    mkdir -p "$(dirname "$file")"
    [[ -f "$file" ]] && grep -qxF "$line" "$file" && return 0
    printf '%s\n' "$line" >> "$file"
}
