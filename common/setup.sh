#!/usr/bin/env bash
# 全環境で実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# やることは aqua を入れて home/.config/aquaproj-aqua/aqua.yaml のツールを
# 入れるだけ。個別のツールをここで特別扱いしない。
set -eu

log() { printf '         %s\n' "$*"; }

TARGET="${DOTFILES_TARGET:-${HOME}}"

# 更新するときは https://github.com/aquaproj/aqua-installer/releases を見て
# バージョンと sha256 を両方直す。
AQUA_INSTALLER_VERSION=v4.0.5
AQUA_INSTALLER_SHA256=451028d56959cc738564885b1dbebc2691ea038ffde04e2472e4d486a3591146
AQUA_VERSION=v2.62.3

AQUA_ROOT_DIR="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-${TARGET}/.local/share}/aquaproj-aqua}"
AQUA_BIN="${AQUA_ROOT_DIR}/bin/aqua"
AQUA_CONFIG="${XDG_CONFIG_HOME:-${TARGET}/.config}/aquaproj-aqua/aqua.yaml"

sha256_of() {
    if command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    elif command -v shasum > /dev/null 2>&1; then
        shasum -a 256 "$1" | cut -d' ' -f1
    else
        return 1
    fi
}

install_aqua() {
    local tmp installer got
    tmp="$(mktemp -d)"
    installer="${tmp}/aqua-installer"

    log "aqua: installing ${AQUA_VERSION}"
    curl -sSfL --retry 3 -o "${installer}" \
        "https://raw.githubusercontent.com/aquaproj/aqua-installer/${AQUA_INSTALLER_VERSION}/aqua-installer"

    if ! got="$(sha256_of "${installer}")"; then
        log "aqua: sha256sum も shasum も無いので検証できない。中止する"
        rm -rf "${tmp}"
        return 1
    fi
    if [ "${got}" != "${AQUA_INSTALLER_SHA256}" ]; then
        log "aqua: aqua-installer の checksum 不一致。中止する"
        log "  expected ${AQUA_INSTALLER_SHA256}"
        log "  actual   ${got}"
        rm -rf "${tmp}"
        return 1
    fi

    AQUA_ROOT_DIR="${AQUA_ROOT_DIR}" bash "${installer}" -v "${AQUA_VERSION}" > /dev/null
    rm -rf "${tmp}"
}

if ! command -v curl > /dev/null 2>&1; then
    log "aqua: curl が無いので飛ばす"
elif [ -x "${AQUA_BIN}" ]; then
    log "aqua: already installed ($("${AQUA_BIN}" -v))"
else
    install_aqua
fi

if [ -x "${AQUA_BIN}" ] && [ -f "${AQUA_CONFIG}" ]; then
    # -a: グローバル設定 (aqua.yaml) のパッケージも入れる
    # DOTFILES_AQUA_ONLY_LINK=1 なら実体を落とさず link だけ張る（初回実行が速い。
    # 実体は最初にコマンドを叩いたときに落ちてくる）
    aqua_opts="-a"
    [ -n "${DOTFILES_AQUA_ONLY_LINK:-}" ] && aqua_opts="-a -l"

    log "aqua: installing packages (${aqua_opts})"
    # shellcheck disable=SC2086
    AQUA_ROOT_DIR="${AQUA_ROOT_DIR}" AQUA_GLOBAL_CONFIG="${AQUA_CONFIG}" \
        "${AQUA_BIN}" install ${aqua_opts}
fi

# aqua の bin を PATH に載せるのは shellenv.sh の役目。rc から読んでいなければ促す。
case ":${PATH}:" in
    *":${AQUA_ROOT_DIR}/bin:"*) ;;
    *) log "PATH 未設定: rc に '. ${TARGET}/.config/dotfiles/shellenv.sh' を足す" ;;
esac
