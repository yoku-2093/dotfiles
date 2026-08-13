#!/usr/bin/env bash
# ラズパイでのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# CLI ツールは common の aqua.yaml が入れる。64bit の Raspberry Pi OS
# (aarch64) が前提。32bit (armv7l/armhf) は多くのツールがバイナリを出して
# いないので aqua では入らず、pkg_install で apt から入れることになる。
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

# 例（apt-get が使われる。root でなければ sudo が付く）:
#   pkg_install tmux
#   pkg_install lm-sensors      # 温度
#   pkg_install avahi-daemon    # <host>.local で引ける
#
# 32bit の場合は aqua を諦めて apt から:
#   pkg_install ripgrep fd-find bat

pkg_log "nothing to do"
