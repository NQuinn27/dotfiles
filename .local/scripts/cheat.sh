#!/usr/bin/env bash

# curl cheat.sh/{language}/query+string
# curl cheat.sh/{core-util}/query+string

selected=`cat ~/.chtsh-languages ~/.chtsh-utils | fzf`
read -p "query: " query

if grep -qs "$selected" ~/.chtsh-languages;  then
    query=`echo $query | tr ' ' '+'`
    if [ -n "$TMUX" ]; then
        tmux neww bash -c "echo \"curl cht.sh/$selected/$query\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
    else
        curl cht.sh/$selected/$query
    fi
else
    query=`echo $query | tr ' ' '+'`
    if [ -n "$TMUX" ]; then
        tmux neww bash -c "echo \"curl cht.sh/$selected~$query\" & curl cht.sh/$selected~$query & while [ : ]; do sleep 1; done"
    else
        curl cht.sh/$selected~$query
    fi
fi
