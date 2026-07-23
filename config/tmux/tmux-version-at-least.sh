#!/bin/sh
# Exit 0 if the running tmux is at least the version passed as $1.
# Used to guard options that older tmux builds reject outright (a rejected
# option aborts the rest of tmux.conf, so this must not be optimistic).
#
#   tmux-version-at-least.sh 3.5

want=$1
[ -n "$want" ] || exit 1

have=$(tmux -V 2>/dev/null | sed 's/^tmux //; s/[^0-9.].*$//')
[ -n "$have" ] || exit 1

# sort -V puts the lower version first; if that is the wanted one, we are fine.
lowest=$(printf '%s\n%s\n' "$have" "$want" | sort -V | head -1)
[ "$lowest" = "$want" ]
