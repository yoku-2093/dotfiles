#!/usr/bin/env bash
# Raspberry Pi 用の追加分。自動判定はしないので明示指定した時だけ実行される。
#
#   ./install.sh --layer linux/raspberrypi
#
# 使える環境変数: DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

log() { printf '         %s\n' "$*"; }

log "nothing to do"
