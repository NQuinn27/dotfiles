# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

fcd() {
  local dir
  dir=$(find ${1:-.} -type d -not -path '*/\.*' 2> /dev/null | fzf +m) && cd "$dir"
}

alias zshconfig="vim ~/.zshrc"

plugins=(git macos brew zsh-syntax-highlighting zsh-autosuggestions)


source $ZSH/oh-my-zsh.sh


export ANDROID_HOME=/Users/niallquinn/Library/Android/sdk
export EDITOR="vim"

export PATH="/usr/local/bin:/Users/niall/.local/bin:$PATH"
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/build-tools/35.0.0

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias vim="nvim"
alias vi="nvim"
alias ls="eza"
alias piru="pod install --repo-update"
alias greset="git reset --hard HEAD"
alias gclean="git clean -fd"
alias gpum="git fetch --all;git pull origin master"
alias cat="bat"
alias ls="eza"

. ~/.asdf/plugins/java/set-java-home.zsh
. ~/.asdf/plugins/golang/set-env.zsh

eval $(/opt/homebrew/bin/brew shellenv)

. /opt/homebrew/opt/asdf/libexec/asdf.sh
# Created by `pipx` on 2024-10-08 10:16:16
export PATH="$PATH:/Users/niall/.local/bin"
export PATH="$PATH:/Users/niall/.local/scripts"
set -o allexport; source ~/.env; set +o allexport

bindkey -s ^f "tmux-sessionizer\n"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
