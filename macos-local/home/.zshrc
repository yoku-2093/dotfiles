# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# .zshrc file

export TERM=xterm-256color

# dotfiles: PATH と aqua の設定
[ -f "$HOME/.config/dotfiles/shellenv.sh" ] && . "$HOME/.config/dotfiles/shellenv.sh"

# HISTORY
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000


# LANG設定 rootの場合はCに設定
export LANG=ja_JP.UTF-8
case ${UID} in
0)
    LANG=C
    ;;
esac

# ls時に色をつける
export LSCOLORS=cxfxcxdxbxegedabagacad
alias ll='ls -lGF'
alias ls='ls -GF'

# cd時にlsする
chpwd() {
	if [[ $(pwd) != $HOME ]]; then;
		ls
	fi
}

# git
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{magenta}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{yellow}+"
zstyle ':vcs_info:*' formats "%F{cyan}%c (%b)%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }

# Prompt
autoload -Uz colors && colors
PROMPT='
%B%F{red}%n@%m%f%b:%F{green}%~%f%F{cyan}$vcs_info_msg_0_%f
%F{yellow}$%f '

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Enable shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"


