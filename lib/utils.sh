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

restore_backup() {
    local file=$1
    if [[ -e "${file}.backup" ]]; then
        mv "${file}.backup" "$file"
    fi
}
