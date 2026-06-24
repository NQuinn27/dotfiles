#!/bin/bash
# Apply the correct catppuccin flavor, clearing cached color values
# without destroying user customizations (window_status_style, window_text, etc.)

FLAVOR="$1"
if [ -z "$FLAVOR" ]; then
  if [ "$(uname)" = "Darwin" ] && ! defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
    FLAVOR="latte"
  else
    FLAVOR="mocha"
  fi
fi

# Unset all @thm_* color variables
tmux show -g 2>/dev/null | grep -oE '^@thm_[^ ]+' | while IFS= read -r opt; do
  tmux set -Ugq "$opt"
done

# Unset per-module color variables (these use -ogq and cache theme colors)
for mod in $(tmux show -g 2>/dev/null | grep -oE '@catppuccin_[a-z]+_color ' | sed 's/_color //' | sed 's/@catppuccin_//'); do
  tmux set -Ugq "@catppuccin_${mod}_color"
  tmux set -Ugq "@catppuccin_status_${mod}_icon_fg"
  tmux set -Ugq "@catppuccin_status_${mod}_text_fg"
  tmux set -Ugq "@catppuccin_status_${mod}_icon_bg"
done

# Unset other color-dependent options
tmux set -Ugq @catppuccin_status_module_text_bg
tmux set -Ugq @catppuccin_window_text_color
tmux set -Ugq @catppuccin_window_number_color
tmux set -Ugq @catppuccin_window_current_text_color
tmux set -Ugq @catppuccin_window_current_number_color
tmux set -Ugq @catppuccin_menu_selected_style
tmux set -Ugq @catppuccin_pane_border_style
tmux set -Ugq @catppuccin_pane_active_border_style
tmux set -Ugq @catppuccin_pane_color
tmux set -Ugq @catppuccin_pane_background_color

tmux set -g @catppuccin_flavor "$FLAVOR"
~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
