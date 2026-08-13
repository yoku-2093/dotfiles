#!/usr/bin/env bash
# レイヤーを重ねて適用する dotfiles のインストーラ。
#
#   ./install.sh
#
# 実行環境から「レイヤー」を決めて、汎用的なものから順に適用する。
#
#   common          全環境
#   linux / macos   OS 別
#   linux-arm64     OS + アーキテクチャ別 (linux-amd64, macos-arm64, ...)
#   raspberrypi     Raspberry Pi のとき
#
# 各レイヤーのディレクトリは中身が両方とも任意。無いものは飛ばす。
#
#   <layer>/links/   ここに $HOME からの相対パスで置いたものが symlink される
#   <layer>/setup.sh install 時に実行される
#
# 何度実行してもよい。既存のファイルは上書きせず退避する。
# macOS / Linux のどちらでも動くよう GNU 拡張は使わない。
#
# 環境変数:
#   DOTFILES_TARGET      配置先 (default: $HOME)
#   DOTFILES_BACKUP_DIR  退避先 (default: $DOTFILES_TARGET/.dotfiles-backup)
#   DOTFILES_OS          OS の判定結果を上書きする (macos / linux)
#   DOTFILES_ARCH        アーキテクチャの判定結果を上書きする (amd64 / arm64 / ...)
#   DOTFILES_LAYERS      レイヤーの並びを空白区切りで直接指定する（判定を使わない）
#   DOTFILES_SKIP_SETUP  1 なら setup.sh を実行せず symlink だけ張る
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${DOTFILES_TARGET:-${HOME}}"
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-${TARGET_DIR}/.dotfiles-backup}/$(date +%Y%m%d-%H%M%S)"

log() { printf '%s\n' "$*"; }
die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# --- 環境の判定 ---------------------------------------------------------------

detect_os() {
    case "$(uname -s)" in
        Darwin) echo macos ;;
        Linux) echo linux ;;
        *) die "未対応の OS: $(uname -s)" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64 | amd64) echo amd64 ;;
        aarch64 | arm64) echo arm64 ;;
        armv6l | armv7l) echo armhf ;;
        *) uname -m ;;
    esac
}

# Raspberry Pi かどうかはアーキテクチャでは分からない（Apple Silicon や
# Graviton も arm64）。デバイスツリーのモデル名で判定する。
is_raspberrypi() {
    local model
    for model in /proc/device-tree/model /sys/firmware/devicetree/base/model; do
        if [ -r "${model}" ] && tr -d '\0' < "${model}" | grep -qi 'raspberry pi'; then
            return 0
        fi
    done
    grep -qi 'raspberry pi' /proc/cpuinfo 2> /dev/null
}

# 汎用的なものから具体的なものへ。後のレイヤーが先のレイヤーを上書きする。
detect_layers() {
    local os="${DOTFILES_OS:-$(detect_os)}"
    local arch="${DOTFILES_ARCH:-$(detect_arch)}"

    DOTFILES_OS="${os}"
    DOTFILES_ARCH="${arch}"

    echo "common ${os} ${os}-${arch}"
    if [ "${os}" = linux ] && is_raspberrypi; then
        echo raspberrypi
    fi
}

# --- symlink ------------------------------------------------------------------

link_one() {
    local links_dir="$1" rel="$2"
    local src="${links_dir}/${rel}"
    local dest="${TARGET_DIR}/${rel}"

    if [ -L "${dest}" ]; then
        local current
        current="$(readlink "${dest}")"

        if [ "${current}" = "${src}" ]; then
            log "  skip   ${rel}"
            return 0
        fi

        # 前のレイヤー（や前回の実行）が張ったリンクは退避せず差し替える
        case "${current}" in
            "${DOTFILES_DIR}"/*) rm "${dest}" ;;
        esac
    fi

    # 自分が張ったものでない実ファイル・symlink・リンク切れは退避する
    if [ -e "${dest}" ] || [ -L "${dest}" ]; then
        mkdir -p "$(dirname "${BACKUP_DIR}/${rel}")"
        mv "${dest}" "${BACKUP_DIR}/${rel}"
        log "  backup ${rel} -> ${BACKUP_DIR}/${rel}"
    fi

    mkdir -p "$(dirname "${dest}")"
    ln -s "${src}" "${dest}"
    log "  link   ${rel}"
}

# ディレクトリ自体は symlink にせずファイル単位で張る。
# そうしないと ~/.config のような共有ディレクトリを丸ごと奪ってしまう。
link_layer() {
    local links_dir="$1" path
    [ -d "${links_dir}" ] || return 0

    find "${links_dir}" \( -type f -o -type l \) -print | while IFS= read -r path; do
        link_one "${links_dir}" "${path#"${links_dir}"/}"
    done
}

# --- main ---------------------------------------------------------------------

layers="${DOTFILES_LAYERS:-$(detect_layers)}"
export DOTFILES_TARGET="${TARGET_DIR}"
export DOTFILES_OS="${DOTFILES_OS:-}" DOTFILES_ARCH="${DOTFILES_ARCH:-}"

log "target: ${TARGET_DIR}"
log "layers: ${layers}"

for layer in ${layers}; do
    layer_dir="${DOTFILES_DIR}/${layer}"
    [ -d "${layer_dir}" ] || continue

    log "[${layer}]"
    link_layer "${layer_dir}/links"

    if [ -f "${layer_dir}/setup.sh" ]; then
        if [ "${DOTFILES_SKIP_SETUP:-}" = 1 ]; then
            log "  skip   setup.sh"
        else
            log "  run    setup.sh"
            # 1つの setup.sh の失敗で symlink まで巻き戻したくないので続行する
            bash "${layer_dir}/setup.sh" || log "  Warning: ${layer}/setup.sh が失敗した ($?)"
        fi
    fi
done
