#!/bin/bash

install_node() {
    local nvm_dir installer
    nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    if [[ ! -s "$nvm_dir/nvm.sh" ]]; then
        echo "npx がないため、nvm をインストールします。"
        installer=$(mktemp) || return 1
        if ! mkdir -p "$nvm_dir" ||
            ! curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh -o "$installer" ||
            ! NVM_DIR="$nvm_dir" bash "$installer"; then
            rm -f "$installer"
            echo "nvm のインストールに失敗しました。" >&2
            return 1
        fi
        rm -f "$installer"
    fi
    export NVM_DIR="$nvm_dir"
    if ! source "$nvm_dir/nvm.sh" ||
        ! nvm install --lts ||
        ! npx --version >/dev/null 2>&1; then
        echo "npx を利用できません。Node.js のインストールと PATH を確認してください。" >&2
        return 1
    fi
}


load_nvm_if_needed() {
    if ! npx --version >/dev/null 2>&1 && [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]]; then
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        source "$NVM_DIR/nvm.sh"
    fi
}
