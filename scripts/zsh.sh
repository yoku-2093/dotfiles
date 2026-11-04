#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"

if command -v zsh >/dev/null 2>&1; then
    echo "zsh はインストール済みです。"
elif ! command -v brew >/dev/null 2>&1; then
    echo "zsh のインストールには Homebrew が必要です。" >&2
else
    if confirm "Homebrew で zsh をインストールしますか？" --exit-on-cancel; then
        brew install zsh
    fi
fi

if confirm "~/.zshrc へのシンボリックリンクを ../.config/zsh/.zshrc に作成しますか？"; then
    ln -s ~/.zshrc ../.config/zsh/.zshrc
fi
