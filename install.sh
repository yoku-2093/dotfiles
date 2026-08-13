#!/usr/bin/env bash
# レイヤーを重ねて適用する dotfiles のインストーラ。
#
#   ./install.sh [options]
#
# 適用されるレイヤー（汎用的なものから順に、後のものが前のものを上書きする）:
#
#   common          全環境
#   linux / macos   OS        (uname -s)
#   linux/amd64     OS + arch (uname -m)
#   <--layer で指定したもの>
#
# 自動で決まるのは uname から分かる OS とアーキテクチャだけ。
# それ以外（ラズパイ用、用途別など）は --layer で明示的に指定する。
#
#   ./install.sh --layer linux/raspberrypi
#
# 各レイヤーのディレクトリは中身が両方とも任意。無いものは飛ばす。
#
#   <layer>/home/    ここに $HOME からの相対パスで置いたものが symlink される
#   <layer>/setup.sh install 時に実行される
#
# 何度実行してもよい。既存のファイルは上書きせず退避する。
# macOS / Linux のどちらでも動くよう GNU 拡張は使わない。
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<'EOF'
usage: install.sh [options]

  --layer <name>      レイヤーを追加する（リポジトリ直下からの相対パス。複数回指定可）
  --layers "<a b c>"  自動判定を使わずレイヤーの並びを直接指定する
  --os <name>         OS の判定を上書きする (macos / linux)
  --arch <name>       アーキテクチャの判定を上書きする (amd64 / arm64 / armhf)
  --target <dir>      配置先を変える (default: $HOME)
  --backup-dir <dir>  退避先を変える (default: <target>/.dotfiles-backup)
  --skip-setup        setup.sh を実行せず symlink だけ張る
  --dry-run           何もせず、やることだけ表示する
  --list              適用されるレイヤーの状態を表示して終了する
  -h, --help          このヘルプ

同じ設定は環境変数でも渡せる（オプションが優先）:
  DOTFILES_TARGET / DOTFILES_BACKUP_DIR / DOTFILES_OS / DOTFILES_ARCH
  DOTFILES_LAYERS / DOTFILES_SKIP_SETUP

examples:
  ./install.sh
  ./install.sh --layer linux/raspberrypi      # ラズパイ用の追加分を適用する
  ./install.sh --layer linux/raspberrypi --list
  ./install.sh --layers "common linux"        # 自動判定を使わない
  DOTFILES_TARGET=$(mktemp -d) ./install.sh --dry-run
EOF
}

log() { printf '%s\n' "$*"; }
die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# --- 引数 ---------------------------------------------------------------------

extra_layers=""
layers_override="${DOTFILES_LAYERS:-}"
os_override="${DOTFILES_OS:-}"
arch_override="${DOTFILES_ARCH:-}"
target_dir="${DOTFILES_TARGET:-${HOME}}"
backup_root="${DOTFILES_BACKUP_DIR:-}"
skip_setup="${DOTFILES_SKIP_SETUP:-}"
dry_run=""
list_only=""

need_value() { [ "$2" -ge 2 ] || die "$1 には値が必要"; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        --layer)
            need_value "$1" "$#"
            extra_layers="${extra_layers} $2"
            shift 2
            ;;
        --layers)
            need_value "$1" "$#"
            layers_override="$2"
            shift 2
            ;;
        --os)
            need_value "$1" "$#"
            os_override="$2"
            shift 2
            ;;
        --arch)
            need_value "$1" "$#"
            arch_override="$2"
            shift 2
            ;;
        --target)
            need_value "$1" "$#"
            target_dir="$2"
            shift 2
            ;;
        --backup-dir)
            need_value "$1" "$#"
            backup_root="$2"
            shift 2
            ;;
        --skip-setup)
            skip_setup=1
            shift
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        --list)
            list_only=1
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            die "不明なオプション: $1"
            ;;
    esac
done

BACKUP_DIR="${backup_root:-${target_dir}/.dotfiles-backup}/$(date +%Y%m%d-%H%M%S)"

# --- OS / アーキテクチャ ------------------------------------------------------

detect_os() {
    case "$(uname -s)" in
        Darwin) echo macos ;;
        Linux) echo linux ;;
        *) die "未対応の OS: $(uname -s)。--os で指定できる" ;;
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

OS="${os_override:-$(detect_os)}"
ARCH="${arch_override:-$(detect_arch)}"

if [ -n "${layers_override}" ]; then
    layers="${layers_override}"
else
    layers="common ${OS} ${OS}/${ARCH}"
fi
layers="${layers}${extra_layers}"

for layer in ${layers}; do
    case "${layer}" in
        /* | *..*) die "レイヤー名が不正: ${layer}" ;;
    esac
done

# --- symlink ------------------------------------------------------------------

link_one() {
    local home_dir="$1" rel="$2"
    local src="${home_dir}/${rel}"
    local dest="${target_dir}/${rel}"

    if [ -L "${dest}" ]; then
        local current
        current="$(readlink "${dest}")"

        if [ "${current}" = "${src}" ]; then
            log "  skip   ${rel}"
            return 0
        fi

        # 前のレイヤー（や前回の実行）が張ったリンクは退避せず差し替える
        case "${current}" in
            "${DOTFILES_DIR}"/*) [ -n "${dry_run}" ] || rm "${dest}" ;;
        esac
    fi

    # 自分が張ったものでない実ファイル・symlink・リンク切れは退避する
    if [ -e "${dest}" ] || [ -L "${dest}" ]; then
        log "  backup ${rel} -> ${BACKUP_DIR}/${rel}"
        if [ -z "${dry_run}" ]; then
            mkdir -p "$(dirname "${BACKUP_DIR}/${rel}")"
            mv "${dest}" "${BACKUP_DIR}/${rel}"
        fi
    fi

    log "  link   ${rel}"
    if [ -z "${dry_run}" ]; then
        mkdir -p "$(dirname "${dest}")"
        ln -s "${src}" "${dest}"
    fi
}

# ディレクトリ自体は symlink にせずファイル単位で張る。
# そうしないと ~/.config のような共有ディレクトリを丸ごと奪ってしまう。
link_layer() {
    local home_dir="$1" path
    [ -d "${home_dir}" ] || return 0

    find "${home_dir}" \( -type f -o -type l \) -print | while IFS= read -r path; do
        link_one "${home_dir}" "${path#"${home_dir}"/}"
    done
}

# --- main ---------------------------------------------------------------------

log "target: ${target_dir}"
log "os:     ${OS} (${ARCH})"
log "layers: ${layers}"
[ -n "${dry_run}" ] && log "(dry-run: 何も変更しない)"

if [ -n "${list_only}" ]; then
    for layer in ${layers}; do
        dir="${DOTFILES_DIR}/${layer}"
        if [ ! -d "${dir}" ]; then
            log "  ${layer}: (ディレクトリなし)"
            continue
        fi
        count="$(find "${dir}/home" \( -type f -o -type l \) -print 2> /dev/null | wc -l | tr -d ' ')"
        setup="-"
        [ -f "${dir}/setup.sh" ] && setup="setup.sh"
        log "  ${layer}: home=${count} ${setup}"
    done
    exit 0
fi

export DOTFILES_TARGET="${target_dir}" DOTFILES_OS="${OS}" DOTFILES_ARCH="${ARCH}"

for layer in ${layers}; do
    layer_dir="${DOTFILES_DIR}/${layer}"
    [ -d "${layer_dir}" ] || continue

    log "[${layer}]"
    link_layer "${layer_dir}/home"

    if [ -f "${layer_dir}/setup.sh" ]; then
        if [ -n "${skip_setup}" ] || [ -n "${dry_run}" ]; then
            log "  skip   setup.sh"
        else
            log "  run    setup.sh"
            # 1つの setup.sh の失敗で symlink まで巻き戻したくないので続行する
            bash "${layer_dir}/setup.sh" || log "  Warning: ${layer}/setup.sh が失敗した ($?)"
        fi
    fi
done
