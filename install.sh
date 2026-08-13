#!/usr/bin/env bash
# 環境ごとの dotfiles インストーラ。
#
#   ./install.sh --env <name>
#
# 適用されるのは common と、指定した環境のディレクトリだけ。後のものが前のものを
# 上書きする。
#
#   common          全環境に共通（常に適用）
#   <env>           ona / macos-local / raspberrypi（--env / DOTFILES_ENV で指定）
#
# OS もアーキテクチャも自動判定しない。環境を指定しなければ common だけを置く。
# CLI ツールの OS / arch 差は aqua が吸収するので、レイヤーを分ける必要はない。
#
# 各環境のディレクトリは中身が両方とも任意。無いものは飛ばす。
#
#   <env>/home/     ここに $HOME からの相対パスで置いたものが symlink される
#   <env>/setup.sh  install 時に実行される
#
# setup.sh には DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV が渡る。
# OS のパッケージ導入は common/lib.sh の pkg_install を使う。
#
# 何度実行してもよい。既存のファイルは上書きせず退避する。
# macOS / Linux のどちらでも動くよう GNU 拡張は使わない。
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# common 以外のトップレベルディレクトリ = 選べる環境
available_envs() {
    find "${DOTFILES_DIR}" -mindepth 1 -maxdepth 1 -type d -print |
        sed "s|^${DOTFILES_DIR}/||" |
        grep -v -e '^\.' -e '^common$' |
        sort
}

usage() {
    cat <<'EOF'
usage: install.sh [--env <name>] [options]

  --env <name>        環境を指定する (省略すると common だけを置く)
  --target <dir>      配置先を変える (default: $HOME)
  --backup-dir <dir>  退避先を変える (default: <target>/.dotfiles-backup)
  --skip-setup        setup.sh を実行せず symlink だけ張る
  --dry-run           何もせず、やることだけ表示する
  --list              適用される内容を表示して終了する
  -h, --help          このヘルプ

同じ設定は環境変数でも渡せる（オプションが優先）:
  DOTFILES_ENV / DOTFILES_TARGET / DOTFILES_BACKUP_DIR / DOTFILES_SKIP_SETUP

examples:
  ./install.sh --env ona
  ./install.sh --env macos-local
  DOTFILES_ENV=raspberrypi ./install.sh
  ./install.sh                                 # common だけ
  ./install.sh --env ona --target "$(mktemp -d)" --dry-run
EOF
    printf '\nenvs:\n'
    available_envs | sed 's/^/  /'
}

log() { printf '%s\n' "$*"; }
die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# --- 引数 ---------------------------------------------------------------------

env_name="${DOTFILES_ENV:-}"
target_dir="${DOTFILES_TARGET:-${HOME}}"
backup_root="${DOTFILES_BACKUP_DIR:-}"
skip_setup="${DOTFILES_SKIP_SETUP:-}"
dry_run=""
list_only=""

need_value() { [ "$2" -ge 2 ] || die "$1 には値が必要"; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        --env)
            need_value "$1" "$#"
            env_name="$2"
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

# 環境を指定しなければ common だけ。自動判定はしない。
if [ -z "${env_name}" ]; then
    layers="common"
else
    case "${env_name}" in
        */* | .* | *..*) die "環境名が不正: ${env_name}" ;;
    esac

    if ! available_envs | grep -q "^${env_name}$"; then
        die "そんな環境は無い: ${env_name}（$(available_envs | tr '\n' ' ')）"
    fi

    layers="common ${env_name}"
fi
BACKUP_DIR="${backup_root:-${target_dir}/.dotfiles-backup}/$(date +%Y%m%d-%H%M%S)"

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
log "env:    ${env_name:-(指定なし: common だけ)}"
[ -n "${dry_run}" ] && log "(dry-run: 何も変更しない)"

if [ -n "${list_only}" ]; then
    for layer in ${layers}; do
        dir="${DOTFILES_DIR}/${layer}"
        if [ ! -d "${dir}" ]; then
            log "[${layer}] (ディレクトリなし)"
            continue
        fi
        log "[${layer}]"
        find "${dir}/home" \( -type f -o -type l \) -print 2> /dev/null |
            sed "s|^${dir}/home/|  home   |"
        [ -f "${dir}/setup.sh" ] && log "  setup  setup.sh"
    done
    exit 0
fi

export DOTFILES_DIR DOTFILES_TARGET="${target_dir}" DOTFILES_ENV="${env_name}"

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
