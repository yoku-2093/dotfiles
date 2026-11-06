#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/history.sh"

if step_done zsh.install; then
    echo "zsh はインストール済みです。"
elif command -v zsh >/dev/null 2>&1; then
    step_record zsh.install || exit 1
    echo "zsh はインストール済みです。"
elif ! command -v brew >/dev/null 2>&1; then
    echo "zsh のインストールには Homebrew が必要です。" >&2
else
    if confirm "Homebrew で zsh をインストールしますか？" --exit-on-cancel; then
        brew install zsh || exit 1
        step_record zsh.install || exit 1
    fi
fi

zsh_link="$script_dir/../.config/zsh/.zshrc"
if step_done zsh.link; then
    echo "zsh のシンボリックリンクは作成済みです。"
elif [[ -L $zsh_link && $(readlink "$zsh_link") == "$HOME/.zshrc" ]]; then
    step_record zsh.link || exit 1
    echo "zsh のシンボリックリンクは作成済みです。"
elif confirm "~/.zshrc へのシンボリックリンクを ../.config/zsh/.zshrc に作成しますか？"; then
    ln -s "$HOME/.zshrc" "$zsh_link" || exit 1
    step_record zsh.link || exit 1
fi
