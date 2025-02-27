bindkey -v

export LANG=ja_JP.UTF-8
export CLICOLOR=1
# export LSCOLORS=cxdxcxdxbxegedabagacad

autoload -Uz compinit
compinit

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust \
    zdharma-continuum/fast-syntax-highlighting

### End of Zinit's installer chunk

eval "$(starship init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# alias

alias ls="eza --icons auto"
alias ll="eza -hlmU --icons --git"

# alias note='nvim $(date +%Y%m%d%H%M%S).md'
function note() {
    id="$(node ~/./scripts/unique-id/uuidv7.js)"
    title=$1
    if [ -z "$title" ]; then
        title="Note"
    fi
    nvim "${id}_${title}.md"
}

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

alias md-to-pdf='md-to-pdf --config-file ~/.scripts/md-to-pdf/config.js'
