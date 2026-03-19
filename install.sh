#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
backup_suffix=".backup.$(date +%Y%m%d%H%M%S)"

link_target() {
  local source_path=$1
  local target_path=$2
  local current_target

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ]; then
    current_target=$(readlink "$target_path")
    if [ "$current_target" = "$source_path" ]; then
      return 0
    fi
    rm -f "$target_path"
  elif [ -e "$target_path" ]; then
    mv "$target_path" "${target_path}${backup_suffix}"
    echo "Backed up existing target: $target_path -> ${target_path}${backup_suffix}"
  fi

  ln -s "$source_path" "$target_path"
}

mkdir -p "$HOME/.local/scripts" "$HOME/.config"

for script in "$repo_root"/.local/scripts/*; do
  [ -f "$script" ] || continue
  filename=$(basename "$script")
  [[ "$filename" =~ ^\. ]] && continue

  chmod +x "$script"
  link_target "$script" "$HOME/.local/scripts/$filename"
  echo "Linked script: $filename"
done

for config in "$repo_root"/config/*; do
  [ -e "$config" ] || continue
  filename=$(basename "$config")
  [ "$filename" = ".DS_Store" ] && continue

  link_target "$config" "$HOME/.config/$filename"
  echo "Linked config: $filename"
done

for dotfile in .zshrc .p10k.zsh; do
  link_target "$repo_root/$dotfile" "$HOME/$dotfile"
  echo "Linked dotfile: $dotfile"
done

echo "Installation complete."
