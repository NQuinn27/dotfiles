#!/usr/bin/env bash

# curl cheat.sh/{language}/query+string
# curl cheat.sh/{core-util}/query+string

set -uo pipefail

for f in ~/.chtsh-languages ~/.chtsh-utils; do
  if [ ! -f "$f" ]; then
    printf 'Error: %s not found. See README for setup.\n' "$f" >&2
    exit 1
  fi
done

selected=$(cat ~/.chtsh-languages ~/.chtsh-utils | fzf)
[ -n "$selected" ] || exit 0

read -r -p "query: " query
query=${query// /+}

# Languages take a path separator, core-utils take a tilde.
if grep -qsFx -- "$selected" ~/.chtsh-languages; then
  url="cht.sh/$selected/$query"
else
  url="cht.sh/$selected~$query"
fi

if [ -n "${TMUX:-}" ]; then
  # Pass the URL as an argument rather than interpolating it into the shell
  # string, so a query containing backticks or $() cannot execute.
  tmux neww bash -c 'echo "curl $0"; curl "$0"; while :; do sleep 1; done' "$url"
else
  curl "$url"
fi
