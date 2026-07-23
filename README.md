# dotfiles

Shared dotfiles for macOS and WSL/Linux with optional platform-specific integrations.

What is not in this repo:
- Sensitive keys
- projects for `tmux-sessionizer` as these are machine-specific
- inputs for `cht.sh` as these are workflow-specific, different languages for work and personal projects

## Installation

On a new machine:

1. Install Homebrew (macOS only) — `install.sh` will tell you if it is missing:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. Clone this repo somewhere, eg `~/dotfiles`
3. Run `./install.sh`

That symlinks everything into place and then provisions dependencies:
Homebrew packages from the `Brewfile`, antidote, and tpm plus the tmux plugins
declared in `tmux.conf`.

Afterwards:

- Copy `.env.example` to `~/.env` and fill in your keys
- Create `~/.sessionizer-projects`, `~/.chtsh-languages`, and `~/.chtsh-utils`
  if you use the tmux sessionizer or cheat helper
- Install nvm and the global npm/go packages listed at the bottom of `Brewfile`

### install.sh options

| Flag | Effect |
| --- | --- |
| *(none)* | Symlink everything, then install dependencies |
| `--skip-deps` | Symlinks only; installs nothing |
| `--deps-only` | Dependencies only; leaves symlinks alone |

`install.sh` is idempotent — re-run it any time. It never upgrades packages
that are merely outdated (run `brew upgrade` deliberately for that), backs up
any real file it would overwrite, and prunes symlinks left pointing at paths
that no longer exist in this checkout.

### Provisioning

Two package lists, picked automatically by `install.sh`:

| Platform | List | Notes |
| --- | --- | --- |
| macOS | `Brewfile` | `brew bundle` |
| Debian/Ubuntu | `Aptfile` | `apt-get`, plus extras apt cannot supply |
| Linux with Homebrew | `Brewfile` | preferred if `brew` is on PATH — exact parity |

Regenerate the macOS list with:

```sh
brew bundle dump --file=Brewfile --force
```

then delete the `npm`/`go` lines it emits (see the note in the file for why).

#### Why Linux is not a straight apt mirror

apt does not carry usable versions of the whole stack, so `install.sh` installs
these separately into `~/.local/bin` after the apt pass:

| Tool | Why not apt |
| --- | --- |
| `neovim` | Debian 12 has 0.7.2, Ubuntu 24.04 has 0.9.5; this config needs 0.10+ |
| `starship` | not packaged — official install script |
| `lazygit` | not packaged — GitHub release |
| `eza` | absent or stale depending on release — GitHub release |
| `antidote` | not packaged — cloned, same as macOS |

apt also renames two binaries: `bat` installs as `batcat` and `fd` as `fdfind`.
`install.sh` symlinks the real names into `~/.local/bin`, and `.zshrc` aliases
them as a fallback.

**Simplest path to true parity:** install [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)
and `install.sh` will use the same `Brewfile` as macOS, skipping apt entirely.
The apt path exists for machines where you do not want linuxbrew.

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

Everything in `Aptfile` plus the extras listed under Provisioning; `install.sh`
handles both. Beyond that:

- Optional `conda` if you use Python environments there as well
- tmux 3.5+ for automatic light/dark theme switching. Older tmux still works —
  the theme hooks are version-guarded and simply stay off, and the theme is
  still applied once at config load.
- Appearance detection uses GNOME's `color-scheme` via `gsettings`. Without a
  desktop (WSL, headless, non-GNOME) it falls back to dark.
- Clipboard: `wl-clipboard` for Wayland or `xclip` for X11. Neovim and the rust
  plugin pick whichever matches the session; both are in `Aptfile`.

## Notes

- `install.sh` links configs into `~/.config`, scripts into `~/.local/scripts`, and shell dotfiles into `$HOME`.
- If an existing target already exists and is not a symlink, the installer backs it up before linking the repo-managed version.
- `config/tmux/plugins/` is not tracked; tpm installs the plugins declared in `tmux.conf`. Run `prefix + I` inside tmux if the install step was skipped.
- `~/.config/herdr` symlinks into this checkout, so herdr writes its logs, sockets and session state here. `.gitignore` allowlists `config.toml` only — keep it that way, since `pane_history` can capture secrets from pane output.
- `grep` is intentionally not aliased to `rg -uuu`; use `rga` when you want to search ignored, hidden and binary files.
