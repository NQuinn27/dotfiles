# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles shared across macOS and WSL/Linux from a single checkout. There is no build or test suite — the only "install" step is `./install.sh`, which symlinks everything into place:

- `config/*` → `~/.config/*` (each entry linked as a whole directory)
- `.local/scripts/*` → `~/.local/scripts/*` (made executable, on PATH via `.zshrc`)
- `.zshrc` and `.p10k.zsh` → `$HOME`

The installer is idempotent; existing non-symlink targets are backed up with a timestamp suffix before linking. Because whole directories are symlinked, edits made here take effect live in `~/.config` — no re-run of `install.sh` is needed unless a new top-level entry is added.

## Platform model

One checkout must work on both macOS and WSL/Linux. Platform-specific integrations (Homebrew, Tailscale, Ghostty, xcodebuild.nvim, clipboard helpers) must self-gate on OS/tool presence — a missing optional tool must never break zsh, tmux, or Neovim startup. Follow this pattern when adding anything: guard with `command -v` / file-existence checks rather than assuming the tool exists.

## Layout

- `.zshrc` — shell config: options, aliases, PATH, plugins via antidote (`.zsh_plugins.txt`), starship prompt with a transient-prompt `zle-line-init` hook. `Ctrl-f` launches `tmux-sessionizer`.
- `config/nvim/` — main Neovim config. `init.lua` loads `lua/lazy-set.lua`, `set.lua`, `map.lua`, `terminal.lua`, then lazy.nvim with one file per plugin under `lua/plugins/`. `lua/platform.lua` holds OS detection. Add new plugins as a new file in `lua/plugins/`.
- `config/nvim-lazy/`, `config/nvim.personal/` — alternate Neovim configs (LazyVim starter and a personal variant).
- `config/tmux/tmux.conf` — prefix `C-b`, vi mode-keys, TPM plugins, popup bindings for `tmux-sessionizer` (`prefix f`) and `cheat.sh` (`prefix i`).
- `config/ghostty`, `config/opencode`, `config/starship.toml`, `config/herdr/config.toml` — other tool configs.
- `.local/scripts/` — helper scripts (`tmux-sessionizer`, `cheat.sh`, `committer`, `tmux-appearance`).

## Machine-specific / sensitive files (never commit)

Sensitive keys live in `~/.env` (sourced by `.zshrc`, gitignored). Machine-specific inputs live outside the repo: `~/.sessionizer-projects`, `~/.chtsh-languages`, `~/.chtsh-utils`. Runtime/state files under `config/herdr/` (logs, sockets, session JSON) are gitignored — only `config.toml` and plugin config are tracked. `lazy-lock.json` is also gitignored.
