#!/bin/bash

# # Create ~/.local/scripts directory if it doesn't exist
mkdir -p ~/.local/scripts
#
# # Loop through all files in executables directory
for script in .local/scripts/*; do
  # Skip if it's a directory or a hidden file
  if [ -f "$script" ] && [[ ! $(basename "$script") =~ ^\. ]]; then
    # Get just the filename without the path
    filename=$(basename "$script")
    # Create symbolic link in ~/.local/scripts
    ln -sf "$(pwd)/$script" ~/.local/scripts/"$filename"
    # Make the original script executable
    chmod +x "$(pwd)/$script"
    # Make the symbolic link executable
    chmod +x ~/.local/scripts/"$filename"
    echo "Linked and made executable: $filename"
  fi
done

# Loop through all items in config directory
for config in config/*; do
  # Skip if the glob didn't match
  [ -e "$config" ] || continue
  # Skip .DS_Store files
  [[ "$(basename "$config")" == ".DS_Store" ]] && continue
  # Get just the filename without the path
  filename=$(basename "$config")
  # Create symbolic link in ~/.config
  ln -sf "$(pwd)/$config" ~/.config/"$filename"
  echo "Linked to ~/.config: $filename"
done

# Loop through specific dotfiles to link to home directory
for dotfile in .zshrc .p10k.zsh; do
  ln -sf "$(pwd)/$dotfile" ~/"$dotfile"
  echo "Linked to home: $dotfile"
done

echo "Installation complete!"
