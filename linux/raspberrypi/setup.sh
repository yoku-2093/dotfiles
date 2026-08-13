#!/usr/bin/env bash
# Raspberry Pi 用の追加分。自動判定はしないので明示指定した時だけ実行される。
#
#   ./install.sh --layer linux/raspberrypi
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

pkg_log "nothing to do"
