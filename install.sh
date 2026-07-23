#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
backup_suffix=".backup.$(date +%Y%m%d%H%M%S)"

skip_deps=false
deps_only=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Symlinks this checkout into place and provisions optional dependencies.
Safe to re-run at any time; every step is idempotent.

Options:
  --skip-deps   Only create symlinks; do not install anything
  --deps-only   Only install dependencies; do not touch symlinks
  -h, --help    Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-deps) skip_deps=true ;;
    --deps-only) deps_only=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

is_macos() { [ "$(uname -s)" = "Darwin" ]; }

# Seconds to allow tpm to clone plugins before giving up. Override if you have
# a slow link: TMUX_PLUGIN_TIMEOUT=600 ./install.sh
tmux_plugin_timeout=${TMUX_PLUGIN_TIMEOUT:-300}

# Portable `timeout`: macOS has no coreutils timeout by default. Runs a command
# in the background, kills it if it outruns the budget, and returns 124 like
# GNU timeout does.
run_with_timeout() {
  local secs=$1; shift
  "$@" >/dev/null 2>&1 &
  local cmd_pid=$!

  ( sleep "$secs"; kill -TERM "$cmd_pid" 2>/dev/null ) >/dev/null 2>&1 &
  local watchdog_pid=$!

  local rc=0
  wait "$cmd_pid" 2>/dev/null || rc=$?
  kill -TERM "$watchdog_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null || true

  # 143 = killed by SIGTERM, i.e. the watchdog fired.
  [ "$rc" = 143 ] && return 124
  return "$rc"
}

# ============================================================================
# SYMLINKING
# ============================================================================

link_target() {
  local source_path=$1
  local target_path=$2
  local current_target

  # Never create a dangling link for something that is not in the checkout.
  if [ ! -e "$source_path" ]; then
    warn "skipping missing source: $source_path"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ]; then
    current_target=$(readlink "$target_path")
    if [ "$current_target" = "$source_path" ]; then
      return 0
    fi
    log "Replacing symlink: $target_path (was -> $current_target)"
    rm -f "$target_path"
  elif [ -e "$target_path" ]; then
    mv "$target_path" "${target_path}${backup_suffix}"
    log "Backed up existing target: $target_path -> ${target_path}${backup_suffix}"
  fi

  ln -s "$source_path" "$target_path"
}

# Remove symlinks that point into this checkout but whose source is gone,
# e.g. after a config directory is renamed or deleted upstream.
prune_stale_links() {
  local dir link resolved base
  # $HOME is scanned for dotfiles only (e.g. a leftover ~/.p10k.zsh); the other
  # directories are scanned in full. Nothing is recursed into, and links
  # pointing outside this checkout are never touched.
  for dir in "$HOME/.config" "$HOME/.local/scripts" "$HOME"; do
    [ -d "$dir" ] || continue
    for link in "$dir"/* "$dir"/.*; do
      [ -L "$link" ] || continue
      base=$(basename "$link")
      [ "$base" = "." ] || [ "$base" = ".." ] && continue
      [ "$dir" = "$HOME" ] && [[ "$base" != .* ]] && continue

      resolved=$(readlink "$link")
      case "$resolved" in
        "$repo_root"/*) ;;
        *) continue ;;
      esac
      if [ ! -e "$resolved" ]; then
        rm -f "$link"
        log "Pruned stale link: $link -> $resolved"
      fi
    done
  done
}

install_links() {
  mkdir -p "$HOME/.local/scripts" "$HOME/.config"

  local script filename config dotfile modfile

  for script in "$repo_root"/.local/scripts/*; do
    [ -f "$script" ] || continue
    filename=$(basename "$script")
    [[ "$filename" =~ ^\. ]] && continue

    chmod +x "$script"
    link_target "$script" "$HOME/.local/scripts/$filename"
    log "Linked script: $filename"
  done

  for config in "$repo_root"/config/*; do
    [ -e "$config" ] || continue
    filename=$(basename "$config")
    [ "$filename" = ".DS_Store" ] && continue

    link_target "$config" "$HOME/.config/$filename"
    log "Linked config: $filename"
  done

  for dotfile in .zshrc .zsh_plugins.txt; do
    link_target "$repo_root/$dotfile" "$HOME/$dotfile"
    log "Linked dotfile: $dotfile"
  done

  # Karabiner complex modifications, only if this checkout carries any.
  if compgen -G "$repo_root/karabiner/*.json" >/dev/null; then
    for modfile in "$repo_root"/karabiner/*.json; do
      filename=$(basename "$modfile")
      link_target "$modfile" \
        "$HOME/.config/karabiner/assets/complex_modifications/$filename"
      log "Linked karabiner modification: $filename"
    done
  fi

  prune_stale_links
}

# ============================================================================
# DEPENDENCIES
# ============================================================================

# Clone a git repo to a path if it is not already there. Idempotent: an
# existing checkout is left completely alone.
clone_once() {
  local url=$1 dest=$2 name=$3
  if [ -d "$dest/.git" ]; then
    return 0
  fi
  if [ -e "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
    warn "$name: $dest exists but is not a git checkout; leaving it alone"
    return 0
  fi
  if ! have git; then
    warn "$name: git is not installed; skipping"
    return 0
  fi
  log "Installing $name -> $dest"
  git clone --depth 1 "$url" "$dest"
}

# True when every `brew "..."` entry in the Brewfile is installed, ignoring
# whether it is outdated. Purely local: no network, no tap refresh.
brewfile_satisfied() {
  local installed name
  installed=$(brew list --formula -1 2>/dev/null) || return 1

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    # Strip any tap prefix: "org/tap/foo" -> "foo".
    name=${name##*/}
    printf '%s\n' "$installed" | grep -qxF "$name" || return 1
  done < <(sed -n 's/^[[:space:]]*brew[[:space:]]*"\([^"]*\)".*/\1/p' "$repo_root/Brewfile")

  return 0
}

install_homebrew_packages() {
  is_macos || return 0

  if ! have brew; then
    warn "Homebrew is not installed. Install it first, then re-run this script:"
    warn '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 0
  fi

  if [ ! -f "$repo_root/Brewfile" ]; then
    warn "no Brewfile found; skipping brew bundle"
    return 0
  fi

  # Deliberately not using `brew bundle check`: it reports merely-outdated
  # formulae as unmet, so it never passes on a machine with pending upgrades
  # and every run would hit the network. We install with --no-upgrade, so the
  # question that matters is "installed at all?", which is a local lookup.
  if brewfile_satisfied; then
    log "Homebrew packages already installed"
    return 0
  fi

  # --no-upgrade: install what is missing, but never silently upgrade packages
  # that are merely outdated. Re-running install.sh should not churn a working
  # toolchain; use `brew upgrade` deliberately when you want that.
  log "Installing missing Homebrew packages from Brewfile (this may take a while)"
  brew bundle install --no-upgrade --file="$repo_root/Brewfile"
}

install_apt_packages() {
  local pkgs=()
  local line

  if [ ! -f "$repo_root/Aptfile" ]; then
    warn "no Aptfile found; skipping apt install"
    return 0
  fi

  # Strip comments and blanks.
  while IFS= read -r line; do
    line=${line%%#*}
    line=$(printf '%s' "$line" | tr -d '[:space:]')
    [ -n "$line" ] && pkgs+=("$line")
  done < "$repo_root/Aptfile"

  [ "${#pkgs[@]}" -gt 0 ] || return 0

  # Only ask for sudo if something is actually missing.
  local missing=()
  local pkg
  for pkg in "${pkgs[@]}"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" ||
      missing+=("$pkg")
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    log "apt packages already satisfied"
    return 0
  fi

  log "Installing ${#missing[@]} apt package(s): ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
}

# Tools apt cannot supply at a usable version. Each installer is guarded on
# the binary already being present, so re-running is a no-op.
install_linux_extras() {
  local arch
  arch=$(uname -m)

  if ! have nvim; then
    install_neovim_linux "$arch"
  fi

  if ! have starship; then
    log "Installing starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes ||
      warn "starship install failed"
  fi

  if ! have eza; then
    install_github_tarball eza \
      "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" \
      eza
  fi

  if ! have lazygit; then
    local lg_arch=$arch
    [ "$arch" = "aarch64" ] && lg_arch="arm64"
    [ "$arch" = "x86_64" ] && lg_arch="x86_64"
    install_github_tarball lazygit \
      "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_$(latest_gh_version jesseduffield/lazygit)_Linux_${lg_arch}.tar.gz" \
      lazygit
  fi

  # Debian names these binaries differently; give them their real names so
  # scripts and aliases behave the same as on macOS.
  local bin
  mkdir -p "$HOME/.local/bin"
  for bin in batcat:bat fdfind:fd; do
    local src=${bin%%:*} dst=${bin##*:}
    if have "$src" && ! have "$dst"; then
      ln -sf "$(command -v "$src")" "$HOME/.local/bin/$dst"
      log "Linked $src -> ~/.local/bin/$dst"
    fi
  done
}

latest_gh_version() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null |
    sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1
}

# Download a .tar.gz, extract one binary from it, drop it in ~/.local/bin.
install_github_tarball() {
  local name=$1 url=$2 binary=$3 tmp

  # A missing version lookup yields a malformed URL; fail loudly rather than
  # downloading a 404 page and extracting nothing.
  case "$url" in
    https://*) ;;
    *) warn "$name: could not build a download URL; install it manually"; return 0 ;;
  esac
  case "$url" in
    *__*|*_""_*) warn "$name: version lookup failed; install it manually"; return 0 ;;
  esac

  tmp=$(mktemp -d)
  log "Installing $name"
  if curl -fsSL "$url" -o "$tmp/dl.tar.gz" 2>/dev/null &&
     tar -xzf "$tmp/dl.tar.gz" -C "$tmp" 2>/dev/null; then
    local found
    found=$(find "$tmp" -type f -name "$binary" -perm -u+x | head -1)
    if [ -n "$found" ]; then
      mkdir -p "$HOME/.local/bin"
      install -m 755 "$found" "$HOME/.local/bin/$binary"
      log "Installed $name -> ~/.local/bin/$binary"
    else
      warn "$name: binary '$binary' not found in archive; install it manually"
    fi
  else
    warn "$name: download failed; install it manually"
  fi
  rm -rf "$tmp"
}

install_neovim_linux() {
  local arch=$1 nvim_arch tmp
  case "$arch" in
    x86_64)  nvim_arch=linux-x86_64 ;;
    aarch64) nvim_arch=linux-arm64 ;;
    *) warn "neovim: unsupported arch '$arch'; install it manually"; return 0 ;;
  esac

  log "Installing neovim (apt's version is too old for this config)"
  tmp=$(mktemp -d)
  if curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-${nvim_arch}.tar.gz" \
       -o "$tmp/nvim.tar.gz" 2>/dev/null &&
     tar -xzf "$tmp/nvim.tar.gz" -C "$tmp" 2>/dev/null; then
    local src
    src=$(find "$tmp" -maxdepth 1 -type d -name 'nvim-*' | head -1)
    if [ -n "$src" ]; then
      mkdir -p "$HOME/.local"
      rm -rf "$HOME/.local/nvim"
      mv "$src" "$HOME/.local/nvim"
      mkdir -p "$HOME/.local/bin"
      ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
      log "Installed neovim -> ~/.local/bin/nvim"
    else
      warn "neovim: unexpected archive layout; install it manually"
    fi
  else
    warn "neovim: download failed; install it manually"
  fi
  rm -rf "$tmp"
}

install_linux_packages() {
  is_macos && return 0

  if have brew; then
    # Homebrew on Linux works and gives exact parity with macOS. If it is
    # present, prefer it and skip the apt path entirely.
    log "Homebrew detected on Linux; using the Brewfile"
    if brewfile_satisfied; then
      log "Homebrew packages already installed"
    else
      brew bundle install --no-upgrade --file="$repo_root/Brewfile"
    fi
  elif have apt-get; then
    install_apt_packages
    install_linux_extras
  else
    warn "no supported package manager found (expected apt-get or brew)"
    warn "see Aptfile and Brewfile for the package lists"
  fi

  local tool
  local missing=()
  for tool in zsh git tmux nvim fzf rg zoxide starship; do
    have "$tool" || missing+=("$tool")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    warn "still missing after provisioning: ${missing[*]}"
  fi
}

# TPM installs the plugins declared in tmux.conf. Safe to re-run: already
# installed plugins are skipped.
install_tmux_plugins() {
  local tpm_bin="$repo_root/config/tmux/plugins/tpm/bin/install_plugins"
  local conf="$HOME/.config/tmux/tmux.conf"

  [ -x "$tpm_bin" ] || return 0

  if ! have tmux; then
    warn "tmux is not installed; skipping plugin install"
    return 0
  fi

  if [ ! -e "$conf" ]; then
    warn "tmux config is not linked yet; skipping plugin install"
    warn "run ./install.sh without --deps-only, or 'prefix + I' inside tmux"
    return 0
  fi

  # install_plugins resolves TMUX_PLUGIN_MANAGER_PATH from a live tmux server,
  # and a server with no sessions exits immediately -- `start-server` alone is
  # not enough, it needs a session.
  #
  # That server is deliberately an isolated one (private TMUX_TMPDIR, which tpm
  # inherits) rather than whatever the user already has running: this must not
  # create sessions on, reload the config of, or otherwise disturb a live tmux.
  # The trap tears it down even if the script is interrupted mid-clone.
  log "Installing tmux plugins"

  local tmpdir
  tmpdir=$(mktemp -d) || return 0

  _cleanup_tmux_install() {
    TMUX_TMPDIR="$tmpdir" tmux kill-server 2>/dev/null || true
    rm -rf "$tmpdir"
  }
  trap '_cleanup_tmux_install' EXIT INT TERM

  # env -u TMUX: if install.sh is itself run from inside tmux, an inherited
  # $TMUX would make new-session refuse to nest.
  #
  # GIT_TERMINAL_PROMPT=0 / GIT_ASKPASS=true: tpm clones from a detached server
  # with no terminal, so a private or renamed plugin repo would otherwise block
  # forever on a credential prompt. Fail fast instead.
  if env -u TMUX TMUX_TMPDIR="$tmpdir" tmux -f "$conf" \
       new-session -d -s dotfiles-install 2>/dev/null; then
    # A subshell, not `env`: run_with_timeout is a shell function and env can
    # only exec real binaries.
    (
      unset TMUX
      export TMUX_TMPDIR="$tmpdir"
      export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true
      export GIT_SSH_COMMAND='ssh -oBatchMode=yes'
      run_with_timeout "$tmux_plugin_timeout" "$tpm_bin"
    ) ||
      warn "tmux plugin install did not complete; run 'prefix + I' inside tmux to retry"
  else
    warn "could not start tmux; run 'prefix + I' inside tmux to install plugins"
  fi

  _cleanup_tmux_install
  trap - EXIT INT TERM
}

install_deps() {
  install_homebrew_packages
  install_linux_packages

  clone_once https://github.com/mattmc3/antidote.git \
    "$HOME/.antidote" "antidote (zsh plugin manager)"

  clone_once https://github.com/tmux-plugins/tpm.git \
    "$repo_root/config/tmux/plugins/tpm" "tpm (tmux plugin manager)"

  install_tmux_plugins

  if [ ! -f "$HOME/.env" ] && [ -f "$repo_root/.env.example" ]; then
    warn "no ~/.env found; copy .env.example to ~/.env and fill in your keys"
  fi
}

# ============================================================================
# MAIN
# ============================================================================

if [ "$deps_only" = false ]; then
  install_links
fi

if [ "$skip_deps" = false ]; then
  install_deps
fi

log "Installation complete."
