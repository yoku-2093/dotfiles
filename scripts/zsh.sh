#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/history.sh"

if step_confirm zsh.install "Homebrew で zsh をインストールしますか？"; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "zsh のインストールには Homebrew が必要です。" >&2
        exit 1
    fi
    brew install zsh || exit 1
    step_record zsh.install || exit 1
fi

zsh_link="$script_dir/../.config/zsh/.zshrc"
if step_confirm zsh.link "~/.zshrc へのシンボリックリンクを ../.config/zsh/.zshrc に作成しますか？"; then
    ln -s "$HOME/.zshrc" "$zsh_link" || exit 1
    step_record zsh.link || exit 1
fi
