#!/bin/bash
# Apply a tmux status theme matching the terminal's themes: vscode-dark in dark
# mode and rose-pine-dawn in light (see ~/.config/ghostty/themes/). Pass "dark"
# or "light"; with no argument, detect the current macOS appearance.

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
  # WSL follows the Windows app theme; native Linux asks the desktop.
  if [ -n "${WSL_INTEROP:-}" ] && command -v powershell.exe >/dev/null 2>&1; then
    windows_light=$(powershell.exe -NoProfile -Command \
      "(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme" \
      2>/dev/null | tr -d '[:space:]')
    case "$windows_light" in
      1) MODE="light" ;;
      0) MODE="dark" ;;
    esac
  elif command -v gsettings >/dev/null 2>&1; then
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    case "$scheme" in
      *prefer-light*|*default*) MODE="light" ;;
      *prefer-dark*)           MODE="dark" ;;
    esac
  fi
  : "${MODE:=dark}"
fi

if [ "$MODE" = "light" ]; then
  # rose-pine-dawn palette
  BG="#faf4ed"          # base
  FG="#575279"          # text
  MUTED="#797593"       # subtle
  ACCENT="#286983"      # pine
  ACCENT_FG="#faf4ed"
  ACTIVE_BG="#dfdad9"   # highlight med
  ACTIVE_FG="#575279"
  BORDER="#cecacd"      # highlight high
  ACTIVE_BORDER="#286983"
else
  # vscode.nvim dark palette
  BG="#1f1f1f"          # vscBack
  FG="#d4d4d4"          # vscFront
  MUTED="#808080"       # vscGray
  ACCENT="#569cd6"      # vscBlue
  ACCENT_FG="#1f1f1f"
  ACTIVE_BG="#264f78"   # vscSelection
  ACTIVE_FG="#ffffff"
  BORDER="#444444"      # vscSplitDark
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
