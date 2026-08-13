#!/usr/bin/env bash
# Linux でのみ実行される。install.sh から呼ばれる。
#
# 使える環境変数: DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
#
# ディストリ差やコンテナ差はここで見る。パッケージの導入など sudo が要る処理は
# 非対話で失敗し得るので、失敗しても install 全体を止めないようにする。
set -eu

log() { printf '         %s\n' "$*"; }

# 例:
#   command -v apt-get > /dev/null 2>&1 && sudo apt-get install -y tmux || log "skip"

log "nothing to do"
