# macOS provisioning for this checkout.
#
#   brew bundle --file=Brewfile        # install everything listed here
#   brew bundle check --file=Brewfile  # report what is missing
#   brew bundle dump --file=Brewfile --force   # regenerate from this machine
#
# ./install.sh runs `brew bundle` automatically on macOS. Only top-level
# (installed-on-request) packages are listed; transitive dependencies are
# resolved by Homebrew.
#
# Not covered here: Ghostty, Tailscale and Karabiner-Elements are installed
# outside Homebrew on this machine. Install them manually, or add them as
# `cask "ghostty"` etc. if you switch to Homebrew-managed casks.

# Plugin manager for zsh, inspired by antigen and antibody
brew "antidote"
# Clone of cat(1) with syntax highlighting and Git integration
brew "bat"
# Wrap Gemini CLI, Codex, Claude Code, Qwen Code as an API service
brew "cliproxyapi"
# Modern, maintained replacement for ls
brew "eza"
# Command-line fuzzy finder written in Go
brew "fzf"
# GitHub command-line tool
brew "gh"
# Simple terminal UI for git commands
brew "lazygit"
# Package manager for the Lua programming language
brew "luarocks"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Search tool like grep and The Silver Searcher
brew "ripgrep"
# Cross-shell prompt for astronauts
brew "starship"
# Terminal multiplexer
brew "tmux"
# Shell extension to navigate your filesystem faster
brew "zoxide"
# Fish shell like syntax highlighting for zsh
brew "zsh-syntax-highlighting"
# NOTE: `brew bundle dump` also emits `npm "..."` and `go "..."` lines for
# globally installed packages. They are deliberately kept out of this file:
# a `npm` entry makes `brew bundle` install Homebrew's own node, which then
# competes with the nvm-managed node this setup actually uses. Install these
# yourself after nvm is set up:
#
#   npm  install -g @earendil-works/pi-coding-agent @rynfar/meridian corepack open-computer-use
#   go   install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
#
# If you re-dump this file, delete the npm/go lines again.
