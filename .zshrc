# ============================================================================
# POWERLEVEL10K INSTANT PROMPT
# ============================================================================
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# OH MY ZSH CONFIGURATION
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git macos brew asdf zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# ============================================================================
# COMPLETION CONFIGURATION
# ============================================================================
# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colorful completion menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Enable menu selection
zstyle ':completion:*' menu select

# Better completion for kill command
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# ============================================================================
# ZSH OPTIONS
# ============================================================================
setopt AUTO_CD              # Go to folder path without using cd
setopt AUTO_PUSHD           # Push the old directory onto the stack on cd
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd
setopt CORRECT              # Spelling correction for commands
setopt CDABLE_VARS          # Change directory to a path stored in a variable
setopt EXTENDED_GLOB        # Use extended globbing syntax

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
export EDITOR="vim"
export ANDROID_HOME=$HOME/Library/Android/sdk

# FZF Configuration
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file
setopt HIST_VERIFY               # Do not execute immediately upon history expansion

# ============================================================================
# PATH CONFIGURATION
# ============================================================================
# Consolidate all PATH additions
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# Add latest Android build-tools dynamically
if [ -d "$ANDROID_HOME/build-tools" ]; then
  export PATH="$PATH:$(ls -d $ANDROID_HOME/build-tools/* | sort -V | tail -1)"
fi

export PATH="$PATH:$HOME/.local/scripts"
export PATH="$PATH:${GOPATH:-$HOME/go}/bin"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export GOPROXY=https://proxy.golang.org,direct

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================
fcd() {
  local dir
  dir=$(find ${1:-.} -type d -not -path '*/\.*' 2> /dev/null | fzf +m) && cd "$dir"
}

# ============================================================================
# ALIASES
# ============================================================================
# Config
alias zshconfig="vim ~/.zshrc"

# Editor
alias vim="nvim"
alias vi="nvim"

# File operations
alias ls="eza"
alias cat="bat"

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts
alias gg='lazygit'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --all --decorate'
alias greset="git reset --hard HEAD"
alias gclean="git clean -fd"
alias gpum="git fetch --all;git pull origin master"

# Development
alias piru="pod install --repo-update"
alias cr="cargo run"
alias ct="cargo test"
alias cb="cargo build"

# Grep
alias grep="rg -uuu"

# ============================================================================
# KEY BINDINGS
# ============================================================================
bindkey -s '^f' "tmux-sessionizer\n"

# ============================================================================
# EXTERNAL INTEGRATIONS
# ============================================================================
# Homebrew
eval $(/opt/homebrew/bin/brew shellenv)

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# .env integration
if [ -f ~/.env ]; then
  set -o allexport
  source ~/.env
  set +o allexport
fi

# asdf Go plugin
if [ -f "${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh" ]; then
  . "${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh"
fi

# Powerlevel10k theme customization
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

