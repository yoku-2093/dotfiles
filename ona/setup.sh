#!/usr/bin/env bash
# ona (Gitpod Flex) の使い捨て環境でのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# CLI ツールは common の aqua.yaml が入れるので、ここに書くのは
# 「aqua では入らない OS 側のもの」と「この環境固有の設定」だけ。
set -eu

# shellcheck source=common/lib.sh
. "${DOTFILES_DIR}/common/lib.sh"

# 例（apt-get が使われる。root でなければ sudo が付く）:
#   pkg_install tmux
#
# rc は環境側が持っているので、PATH を通すには次を一度足す:
#   . "$HOME/.config/dotfiles/shellenv.sh"

pkg_log "nothing to do"
