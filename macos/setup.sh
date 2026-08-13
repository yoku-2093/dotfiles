#!/usr/bin/env bash
# macOS でのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

# pkg_install は macOS では brew を使う（sudo は付けない）
#   pkg_install tmux ripgrep
#
# その他の例:
#   defaults write com.apple.dock autohide -bool true

pkg_log "nothing to do"
