# GO TO YOUR HOME
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# If the zinit dir doesnt exist, create it and clone zinit into it
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

#Load zinit
source "${ZINIT_HOME}/zinit.zsh"

ZSH_THEME='robbyrussell'

# Snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZL::async_prompt.zsh
zinit snippet OMZP::git
zinit snippet OMZT::robbyrussell

zinit snippet OMZP::sudo
zinit snippet OMZP::docker
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::colorize
zinit snippet OMZP::command-not-found
zinit snippet OMZP::laravel
zinit snippet OMZP::composer
zinit snippet OMZP::chezmoi

# Load completions
autoload -Uz compinit && compinit

eval "$(zoxide init --cmd=cd zsh)"
eval "$(fzf --zsh)"

zinit light Aloxaf/fzf-tab

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

zinit cdreplay -q

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History config
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt promptsubst
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)EZA_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'

# fzf-tab previews (per-command)
# Directories
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

# Systemd
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Aliases and such
alias ls="eza -alh --icons=always --color=always --git"
alias zshrc='cd ~/dotfiles/zsh/.zshrc && nvim .zshrc'
alias nvimrc='cd ~/.config/nvim && nvim .'
alias gitrc='cd ~/dotfiles/.config/git && nvim .'
alias ocrc='cd ~/dotfiles/.config/opencode && nvim .'
alias tmuxrc='cd ~/dotfiles/tmux/.tmux.conf'

# Set batcat alias if bat is batcat (im looking at you ubuntu)
command -v batcat &>/dev/null && alias bat='batcat'

alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

export EDITOR='nvim'
export PATH=/home/nicklatcham:$PATH
export PATH=/home/nicklatcham/.config/composer/vendor/bin:$PATH
export PATH="/home/nicklatcham/go/bin:$PATH"
export PATH="/home/nicklatcham/.local/bin:$PATH"
export PATH="/home/nicklatcham/.lando/bin:$PATH" 
export PATH="/home/nicklatcham/.nimble/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#opencode
export PATH=/home/nicklatcham/.opencode/bin:$PATH
. "$HOME/.local/share/../bin/env"

export OPENCODE_EXPERIMENTAL=true

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/nicklatcham/.bun/_bun" ] && source "/home/nicklatcham/.bun/_bun"

[ -f "$HOME/.config/zsh/secrets" ] && source $HOME/.config/zsh/secrets

# vim: ft=zsh
