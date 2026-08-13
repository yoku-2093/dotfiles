#!/usr/bin/env bash
# Linux でのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

# パッケージマネージャ (apt-get / dnf / pacman / apk / zypper) の違いは
# pkg_install が吸収する。パッケージ名自体が違うものはディストロ別レイヤーへ:
#   ./install.sh --layer linux/debian
#
#   pkg_install tmux ripgrep

pkg_log "nothing to do"
