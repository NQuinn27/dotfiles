# dotfiles

Shared dotfiles for macOS and WSL/Linux with optional platform-specific integrations.

What is not in this repo:
- Sensitive keys
- projects for `tmux-sessionizer` as these are machine-specific
- inputs for `cht.sh` as these are workflow-specific, different languages for work and personal projects

## Installation

- Clone this repo somewhere, eg `~/Config`
- Ensure `~/.sessionizer-projects`, `~/.chtsh-languages`, and `~/.chtsh-utils` are present if you use the tmux sessionizer or cheat helper
- Run `./install.sh`
- Verify output/symlinks are correct
- Manually add env files for sensitive keys such as `~/.env`

## Platform Model

- One shared checkout is expected to work on both macOS and WSL/Linux.
- Platform-specific integrations should enable themselves only when the host OS and required tools are present.
- Missing optional tools should not break shell, tmux, or Neovim startup.

## Optional Dependencies

### macOS

- Homebrew for shell environment setup and any Homebrew-managed tools
- Ghostty for the terminal config in `config/ghostty`
- Tailscale app bundle if you want the `tailscale` / `ts` aliases
- Conda if you rely on Python environments from Anaconda or Miniconda
- Xcode / SourceKit / xcodebuild.nvim if you work on Swift projects

### WSL / Linux

- `zsh` and `oh-my-zsh`
- `tmux`, `fzf`, `eza`, `bat`, `rg`, and `nvim` for the main shell workflow
- Optional clipboard helpers such as `wl-copy`, `xclip`, or `xsel`
- Optional `conda` if you use Python environments there as well

## Notes

- `install.sh` links configs into `~/.config`, scripts into `~/.local/scripts`, and shell dotfiles into `$HOME`.
- If an existing target already exists and is not a symlink, the installer backs it up before linking the repo-managed version.
