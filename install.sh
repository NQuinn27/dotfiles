#!/bin/bash

# Create ~/.local/scripts directory if it doesn't exist
mkdir -p ~/.local/scripts

# Loop through all files in executables directory
for script in scripts/*; do
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

echo "Installation complete!"

