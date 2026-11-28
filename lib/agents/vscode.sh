#!/usr/bin/env bash

setup_vscode() {
    if ! command -v code &>/dev/null; then
        echo "VSCode not installed, skipping"
        return 0
    fi

    local vscode_dir
    if is_mac; then
        vscode_dir="$HOME/Library/Application Support/Code/User"
    else
        vscode_dir="$HOME/.config/Code/User"
    fi

    install -d "$vscode_dir"

    local file
    for file in settings.json keybindings.json; do
        copy_once "$MISE_PROJECT_ROOT/agents/vscode/$file" "$vscode_dir/$file"
    done

    local ext
    while IFS= read -r ext; do
        [[ "$ext" =~ ^#|^$ ]] && continue
        code --install-extension "$ext" --force
    done < "$MISE_PROJECT_ROOT/agents/vscode/extensions.txt"
}
