#!/usr/bin/env bash
# 手元の Mac でのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# CLI ツールは common の aqua.yaml が入れるので、ここに書くのは
# 「aqua では入らないもの」と「macOS 固有の設定」だけ。
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

# 例（brew が使われる。sudo は付かない）:
#   pkg_install tmux eza
#
# GUI アプリや macOS の設定はここに書く:
#   pkg_run_user brew install --cask wezterm
#   defaults write com.apple.dock autohide -bool true

pkg_log "nothing to do"
