#!/usr/bin/env bash
# 手元の Mac でのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# CLI ツールは common の aqua.yaml が入れる。ここに書くのは macOS 固有のことだけ。
#   defaults write com.apple.dock autohide -bool true
set -eu
