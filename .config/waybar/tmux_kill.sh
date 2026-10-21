#!/bin/bash
# Fermer les sessions tmux détachées

DETACHED=$(tmux ls 2>/dev/null | grep -v '(attached)' | cut -d: -f1)

if [ -z "$DETACHED" ]; then
    notify-send "Tmux" "Aucune session détachée à fermer" -i terminal 2>/dev/null
    exit 0
fi

COUNT=$(echo "$DETACHED" | wc -l)
echo "$DETACHED" | xargs -r -n1 tmux kill-session -t

notify-send "Tmux" "$COUNT session(s) détachée(s) fermée(s)" -i terminal 2>/dev/null
