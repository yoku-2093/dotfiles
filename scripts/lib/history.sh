#!/bin/bash

# This file is local to the checkout and must not be committed.
setup_history_file="${SETUP_HISTORY_FILE:-$script_dir/.setup-history}"

step_done() {
    [[ -f $setup_history_file ]] && grep -Fxq -- "$1" "$setup_history_file"
}

step_record() {
    step_done "$1" || printf '%s\n' "$1" >> "$setup_history_file"
}

step_confirm() {
    local step="$1" prompt="$2"
    shift 2
    if step_done "$step"; then
        echo "このステップは過去に完了しています。"
    fi
    confirm "$prompt" "$@"
}
