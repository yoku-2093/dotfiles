#!/usr/bin/env bash
# macOS でのみ実行される。install.sh から呼ばれる。
#
# 使える環境変数: DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

log() { printf '         %s\n' "$*"; }

# 例:
#   command -v brew > /dev/null 2>&1 && brew bundle --file="$(dirname "$0")/Brewfile"
#   defaults write com.apple.dock autohide -bool true

log "nothing to do"
