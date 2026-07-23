#!/bin/bash
# Apply a tmux status theme matching Ghostty's vscode-dark / vscode-light themes
# (see ~/.config/ghostty/themes/vscode-{dark,light}). Pass "dark" or "light";
# with no argument, detect the current macOS appearance.

MODE="$1"

# On macOS the system appearance is authoritative. Always prefer it over any
# passed argument: tmux races on first client attach and can fire the wrong
# client-{dark,light}-theme hook, so we treat the hook only as a re-detect
# trigger and read the real appearance here. Off Darwin, trust the argument.
if [ "$(uname)" = "Darwin" ]; then
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi dark; then
    MODE="dark"
  else
    MODE="light"
  fi
elif [ -z "$MODE" ]; then
  # Linux: ask the desktop if there is one, otherwise default to dark.
  if command -v gsettings >/dev/null 2>&1; then
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    case "$scheme" in
      *prefer-light*) MODE="light" ;;
      *prefer-dark*)  MODE="dark" ;;
    esac
  fi
  : "${MODE:=dark}"
fi

if [ "$MODE" = "light" ]; then
  # vscode-light
  BG="#f8f8f8"          # background
  FG="#000000"          # foreground
  MUTED="#555555"       # palette 7 (dim)
  ACCENT="#0451a5"      # palette 4 (blue)
  ACCENT_FG="#f8f8f8"
  ACTIVE_BG="#add6ff"   # selection-background
  ACTIVE_FG="#000000"   # selection-foreground
  BORDER="#c0c0c0"
  ACTIVE_BORDER="#0451a5"
else
  # vscode-dark
  BG="#181818"          # background
  FG="#cccccc"          # foreground
  MUTED="#6a6a6a"       # palette 8 (dim)
  ACCENT="#569cd6"      # palette 4 (blue)
  ACCENT_FG="#1e1e1e"
  ACTIVE_BG="#264f78"   # selection-background
  ACTIVE_FG="#ffffff"   # selection-foreground
  BORDER="#333333"
  ACTIVE_BORDER="#569cd6"
fi

# Status bar
tmux set -g status-style "bg=$BG,fg=$FG"
tmux set -g status-left-length 100
tmux set -g status-right-length 100
tmux set -g status-left "#[bg=$ACCENT,fg=$ACCENT_FG,bold] #S #[bg=$BG,fg=$FG] "
tmux set -g status-right "#[fg=$MUTED]#{host_short} #[fg=$ACCENT,bold]%H:%M #[fg=$MUTED]%d-%b "

# Windows
tmux set -g window-status-separator ""
tmux set -g window-status-format "#[fg=$MUTED] #I:#W "
tmux set -g window-status-current-format "#[bg=$ACTIVE_BG,fg=$ACTIVE_FG,bold] #I:#W "

# Panes
tmux set -g pane-border-style "fg=$BORDER"
tmux set -g pane-active-border-style "fg=$ACTIVE_BORDER"

# Messages / copy mode
tmux set -g message-style "bg=$ACCENT,fg=$ACCENT_FG"
tmux set -g message-command-style "bg=$ACCENT,fg=$ACCENT_FG"
tmux set -g mode-style "bg=$ACTIVE_BG,fg=$ACTIVE_FG"
