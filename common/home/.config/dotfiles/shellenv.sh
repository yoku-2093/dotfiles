# dotfiles が入れたものを PATH に載せる。ログインシェルの rc から source する。
#
#   . "$HOME/.config/dotfiles/shellenv.sh"
#
# sh / bash / zsh で動くように書く。ここに秘匿情報は置かない。

# aqua で入れた CLI ツール（~/.config/aquaproj-aqua/aqua.yaml）
AQUA_ROOT_DIR="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/aquaproj-aqua}"
export AQUA_ROOT_DIR
export AQUA_GLOBAL_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/aquaproj-aqua/aqua.yaml"

# 重複して足さない
for _dotfiles_dir in "${AQUA_ROOT_DIR}/bin" "${HOME}/.local/bin"; do
    case ":${PATH}:" in
        *":${_dotfiles_dir}:"*) ;;
        *) PATH="${_dotfiles_dir}:${PATH}" ;;
    esac
done
unset _dotfiles_dir
export PATH
