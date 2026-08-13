#!/usr/bin/env bash
# 全環境で実行される。install.sh から呼ばれる。
#
# 使える環境変数: DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

TARGET="${DOTFILES_TARGET:-${HOME}}"

log() { printf '         %s\n' "$*"; }

# tmux のプラグインマネージャ。.tmux.conf が前提にしている。
TPM_DIR="${TARGET}/.tmux/plugins/tpm"
if [ -d "${TPM_DIR}" ]; then
    log "tpm: already installed"
elif ! command -v git > /dev/null 2>&1; then
    log "tpm: git が無いので飛ばす"
else
    log "tpm: installing"
    git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "${TPM_DIR}"
fi
