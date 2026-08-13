#!/usr/bin/env bash
# setup.sh から source して使うヘルパー。
#
#   . "${DOTFILES_DIR}/common/lib.sh"
#   pkg_install tmux ripgrep
#
# パッケージマネージャの違い（コマンドとオプション）だけを吸収する。
# パッケージ「名」がディストロ間で違うもの（fd-find / fd、bat / batcat など）は
# 吸収できないので、そういう CLI ツールは aqua 側（common/home の aqua.yaml）で
# 入れる。ここで扱うのは aqua に無い OS 側のものだけ。
#
# 環境変数:
#   DOTFILES_PKG_DRY_RUN  1 なら実行せずコマンドを表示する

pkg_log() { printf '         %s\n' "$*"; }

# 使えるパッケージマネージャの名前を返す。無ければ 1 を返す。
pkg_manager() {
    local m
    for m in brew apt-get dnf pacman apk zypper; do
        if command -v "${m}" > /dev/null 2>&1; then
            echo "${m}"
            return 0
        fi
    done
    return 1
}

# そのまま実行する（dry-run のときだけ表示に差し替える）
pkg_run_user() {
    if [ -n "${DOTFILES_PKG_DRY_RUN:-}" ]; then
        pkg_log "(dry-run) $*"
        return 0
    fi
    "$@"
}

# root なら直接、そうでなければ sudo 経由で実行する。
# 非対話で動くことがあるので、どちらも使えない場合は失敗させる。
pkg_run() {
    if [ -n "${DOTFILES_PKG_DRY_RUN:-}" ]; then
        pkg_log "(dry-run) sudo $*"
        return 0
    fi

    if [ "$(id -u)" = 0 ]; then
        "$@"
    elif command -v sudo > /dev/null 2>&1; then
        sudo "$@"
    else
        pkg_log "root でも sudo でもないため実行できない: $*"
        return 1
    fi
}

_pkg_apt_updated=""

pkg_install() {
    [ "$#" -gt 0 ] || return 0

    local mgr
    if ! mgr="$(pkg_manager)"; then
        pkg_log "パッケージマネージャが見つからない: $*"
        return 1
    fi

    pkg_log "${mgr}: $*"

    case "${mgr}" in
        # brew は sudo で動かしてはいけない
        brew) pkg_run_user brew install "$@" ;;
        apt-get)
            # index が古いと install が失敗するので一度だけ更新する
            if [ -z "${_pkg_apt_updated}" ]; then
                pkg_run env DEBIAN_FRONTEND=noninteractive apt-get update -qq || true
                _pkg_apt_updated=1
            fi
            # sudo は環境変数を落とすので env 経由で渡す
            pkg_run env DEBIAN_FRONTEND=noninteractive \
                apt-get install -y --no-install-recommends "$@"
            ;;
        dnf) pkg_run dnf install -y "$@" ;;
        pacman) pkg_run pacman -S --needed --noconfirm "$@" ;;
        apk) pkg_run apk add --no-cache "$@" ;;
        zypper) pkg_run zypper install -y "$@" ;;
    esac
}
