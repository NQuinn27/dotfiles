# ============================================================================
# ZSH OPTIONS
# ============================================================================
# setopt AUTO_CD              # Go to folder path without using cd
setopt AUTO_PUSHD           # Push the old directory onto the stack on cd
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd
setopt CORRECT              # Spelling correction for commands
setopt CDABLE_VARS          # Change directory to a path stored in a variable
setopt EXTENDED_GLOB        # Use extended globbing syntax

# ============================================================================
# PLATFORM DETECTION
# ============================================================================
if [[ "$OSTYPE" == darwin* ]]; then
  is_macos=true
else
  is_macos=false
fi

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
else
  export EDITOR="vim"
fi

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
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.local/scripts"
export PATH="$PATH:${GOPATH:-$HOME/go}/bin"

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
if command -v nvim >/dev/null 2>&1; then
  alias vim="nvim"
  alias vi="nvim"
fi

# File operations. Debian/Ubuntu install these as `batcat` and `fdfind` to
# avoid name clashes, so fall back to those when the real names are absent.
command -v eza >/dev/null 2>&1 && alias ls="eza"
if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
elif command -v batcat >/dev/null 2>&1; then
  alias cat="batcat"
  alias bat="batcat"
fi
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd="fdfind"
fi

# Safety nets. Deliberately not aliasing `rm`: `rm -i` does not protect the
# case that matters (`rm -rf` overrides it) and is absent in scripts and on
# machines without these dotfiles, so it trains a reflex that does not hold.
# Use `del` for recoverable deletes.
command -v trash >/dev/null 2>&1 && alias del='trash'
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
# Pull the repo's actual default branch, not a hardcoded "master".
gpum() {
  local remote=${1:-origin} branch
  git fetch --all || return 1
  branch=$(git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null)
  branch=${branch#"$remote/"}
  if [[ -z "$branch" ]]; then
    print -u2 "gpum: could not determine default branch for '$remote'"
    print -u2 "gpum: run: git remote set-head $remote --auto"
    return 1
  fi
  git pull "$remote" "$branch"
}

# Development
alias piru="pod install --repo-update"
alias cr="cargo run"
alias ct="cargo test"
alias cb="cargo build"

# tailscale
if [[ "$is_macos" == true && -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  alias ts="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi

# Search. `grep` is deliberately left alone: aliasing it to `rg -uuu` makes an
# ordinary `grep -r secret .` read .env, .git/ and credential caches, which is
# a leak waiting to happen. Use `rga` when you explicitly want everything.
command -v rg >/dev/null 2>&1 && alias rga="rg -uuu"

command -v nvim >/dev/null 2>&1 && export MANPAGER="nvim +Man!"

# ============================================================================
# KEY BINDINGS
# ============================================================================
bindkey -s '^f' "tmux-sessionizer\n"

# ============================================================================
# EXTERNAL INTEGRATIONS
# ============================================================================
# Homebrew
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# .env integration
if [ -f ~/.env ]; then
  set -o allexport
  source ~/.env
  set +o allexport
fi

# ===========================================================================
# PLUGINS
# ===========================================================================

if [ -f ~/.antidote/antidote.zsh ]; then
  source ~/.antidote/antidote.zsh
  antidote load
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# zsh-syntax-highlighting. Location differs across Apple Silicon, Intel macOS
# and Linux distros, so probe rather than hardcoding the Homebrew path.
for _zsh_hl in \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [ -f "$_zsh_hl" ]; then
    source "$_zsh_hl"
    break
  fi
done
unset _zsh_hl

if ! command -v starship >/dev/null 2>&1; then
  # Minimal fallback prompt so a fresh machine is still usable.
  PROMPT='%F{blue}%~%f %# '
  return 0
fi

eval "$(starship init zsh)"
zle-line-init() {
  emulate -L zsh
  [[ $CONTEXT == start ]] || return 0

  while true; do
    zle .recursive-edit
    local -i ret=$?
    [[ $ret == 0 && $KEYS == $'\4' ]] || break
    [[ -o ignore_eof ]] || exit 0
  done

  local save_prompt=$PROMPT
  local save_rprompt=$RPROMPT
  PROMPT=$(starship module character)   # the transient (collapsed) prompt
  RPROMPT=''
  zle .reset-prompt
  PROMPT=$save_prompt
  RPROMPT=$save_rprompt

  if (( ret )); then
    zle .send-break
  else
    zle .accept-line
  fi
  return ret
}
zle -N zle-line-init
