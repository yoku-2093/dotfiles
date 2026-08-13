#!/usr/bin/env bash
# 全環境で実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_OS / DOTFILES_ARCH
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

TARGET="${DOTFILES_TARGET:-${HOME}}"

# tmux のプラグインマネージャ。home/.tmux.conf が前提にしている。
TPM_DIR="${TARGET}/.tmux/plugins/tpm"
if [ -d "${TPM_DIR}" ]; then
    pkg_log "tpm: already installed"
elif ! command -v git > /dev/null 2>&1; then
    pkg_log "tpm: git が無いので飛ばす"
else
    pkg_log "tpm: installing"
    git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "${TPM_DIR}"
fi
